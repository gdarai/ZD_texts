#!/bin/bash
# validate_tags.sh
# Checks that all tags used in faq.csv exist in faq_tags.csv

DIR="$(cd "$(dirname "$0")" && pwd)"
TAGS_FILE="$DIR/faq_tags.csv"
FAQ_FILE="$DIR/faq.csv"

# Load valid tags from faq_tags.csv (first column, skip header)
declare -A VALID_TAGS
while IFS='|' read -r tag rest; do
    VALID_TAGS["$tag"]=1
done < <(tail -n +2 "$TAGS_FILE")

# Check each FAQ line
errors=0
while IFS='|' read -r order tags question answer; do
    IFS=',' read -ra tag_list <<< "$tags"
    for tag in "${tag_list[@]}"; do
        if [[ -z "${VALID_TAGS[$tag]}" ]]; then
            echo "ERROR line $order: unknown tag '$tag'"
            ((errors++))
        fi
    done
done < <(tail -n +2 "$FAQ_FILE")

if [[ $errors -eq 0 ]]; then
    echo "OK: All tags in faq.csv are valid."
else
    echo ""
    echo "FAILED: $errors invalid tag usage(s) found."
fi

