#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s <markdown-file>\n' "${0##*/}" >&2
    exit 2
fi

if [[ ! -f $1 || ! -r $1 ]]; then
    printf 'Cannot read file: %s\n' "$1" >&2
    exit 1
fi

for tool in python3 pdflatex; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$tool" >&2
        exit 1
    fi
done

input_dir=$(cd -- "$(dirname -- "$1")" && pwd -P)
input="$input_dir/$(basename -- "$1")"
name=${input##*/}
if [[ $name == *.* && $name != .* ]]; then
    output="$input_dir/${name%.*}.pdf"
else
    output="$input.pdf"
fi
if [[ $input == "$output" ]]; then
    printf 'Input and output paths must differ: %s\n' "$input" >&2
    exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -f -- "$tmpdir/document.tex" "$tmpdir/document.pdf" "$tmpdir/document.aux" "$tmpdir/document.log"; rmdir -- "$tmpdir"' EXIT

python3 - "$input" "$tmpdir/document.tex" <<'PY'
import re
import sys
from pathlib import Path

escapes = {
    "\\": r"\textbackslash{}",
    "{": r"\{", "}": r"\}", "#": r"\#", "$": r"\$",
    "%": r"\%", "&": r"\&", "_": r"\_",
    "~": r"\textasciitilde{}", "^": r"\textasciicircum{}",
    "–": "--", "—": "---", "„": ",,", "“": "''", "”": "''",
}


def latex(text):
    parts = re.split(r"(\*\*.*?\*\*)", text)
    def escape(part):
        return "".join(escapes.get(char, char) for char in part)
    return "".join(
        r"\textbf{" + escape(part[2:-2]) + "}"
        if part.startswith("**") and part.endswith("**") else escape(part)
        for part in parts
    )


lines = [
    r"\documentclass[a4paper,11pt]{article}",
    r"\usepackage[T1]{fontenc}",
    r"\usepackage[utf8]{inputenc}",
    r"\setlength{\parindent}{0pt}",
    r"\setlength{\parskip}{0.5em}",
    r"\makeatletter",
    r"\renewcommand\section{\@startsection{section}{1}{\z@}"
    r"{-3.5ex \@plus -1ex \@minus -.2ex}{1.15ex \@plus .1ex}"
    r"{\normalfont\Large\bfseries}}",
    r"\renewcommand\subsection{\@startsection{subsection}{2}{\z@}"
    r"{-3.25ex \@plus -1ex \@minus -.2ex}{.75ex \@plus .1ex}"
    r"{\normalfont\large\bfseries}}",
    r"\makeatother",
    r"\begin{document}",
]
in_list = False

for raw in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    text = raw.strip()
    heading = re.fullmatch(r"(#{1,6})\s+(.+)", text)
    item = re.fullmatch(r"\d+\.\s+(.+)", text)
    if not item and in_list:
        lines.append(r"\end{enumerate}")
        in_list = False
    if heading:
        command = "section" if len(heading[1]) == 1 else "subsection"
        lines.extend((f"\\{command}*{{{latex(heading[2])}}}", ""))
    elif item:
        if not in_list:
            lines.append(r"\begin{enumerate}")
            in_list = True
        lines.append(r"\item " + latex(item[1]))
    elif text:
        lines.extend((latex(text), ""))

if in_list:
    lines.append(r"\end{enumerate}")
lines.append(r"\end{document}")
Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

(cd -- "$tmpdir" && pdflatex -halt-on-error -interaction=nonstopmode document.tex)
mv -- "$tmpdir/document.pdf" "$output"
printf 'Created %s\n' "$output"
