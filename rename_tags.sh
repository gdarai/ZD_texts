#!/bin/bash
# rename_tags.sh
# Renames old CZ-based tag slugs to new EN-based tag slugs in the 'tags' column of faq.csv
# Only modifies column 2 (pipe-delimited), leaving question/answer text untouched.

DIR="$(cd "$(dirname "$0")" && pwd)"
FAQ_FILE="$DIR/faq.csv"

# Mapping: old_cz_tag -> new_en_tag
declare -A TAG_MAP=(
    ["princip-hry"]="game-principle"
    ["herní-prvky"]="game-components"
    ["dobírací-balíčky"]="draw-decks"
    ["karty-na-ruce"]="hand-cards"
    ["karty-příběhu"]="story-cards"
    ["jsem-epic"]="i-am-epic"
    ["na-stole"]="on-table"
    ["vítězné-body"]="victory-points"
    ["symboly-karet"]="card-symbols"
    ["míchání-balíčků"]="deck-mixing"
    ["příprava-hry"]="game-setup"
    ["začínající-hráč"]="starting-player"
    ["stavba-mapy"]="map-building"
    ["speciální-pole"]="special-tiles"
    ["dostupnost-polí"]="tile-accessibility"
    ["umístění-příšer"]="monster-placement"
    ["volba-startu"]="starting-position"
    ["počáteční-zbraně"]="initial-weapons"
    ["počáteční-karty"]="initial-cards"
    ["veřejná-nabídka"]="public-offer"
    ["tah-hráče"]="player-turn"
    ["fáze-tahu"]="turn-phases"
    ["dobrání-zbraní"]="drawing-weapons"
    ["plnění-úkolů"]="quest-completion"
    ["doplňování-příšer"]="monster-replenishment"
    ["výměna-úkolu"]="quest-exchange"
    ["úkol-trofej"]="trophy-quest"
    ["úkol-formace"]="formation-quest"
    ["úkol-bariéra"]="barrier-quest"
    ["stůj-mezi"]="stand-between"
    ["stůj-v-řadě"]="stand-in-line"
    ["chraň-vesnici"]="protect-village"
    ["zažeň-ke-skále"]="chase-to-rock"
    ["kouzlo-tvrdosti"]="hardness-spell"
    ["kouzlo-záměny"]="swap-spell"
    ["kouzlo-vábení"]="lure-spell"
    ["kouzlo-vzteku"]="rage-spell"
    ["kouzlo-krádeže"]="theft-spell"
    ["kouzlo-létání"]="flying-spell"
    ["opakované-hry"]="repeated-games"
    ["trestné-body"]="penalty-points"
    ["pole-start"]="start-tile"
    ["pole-vesnice"]="village-tile"
    ["pole-věž"]="tower-tile"
    ["pole-teleport"]="teleport-tile"
    ["pole-skála"]="rock-tile"
    ["pole-hrad"]="castle-tile"
    ["povolání"]="profession"
    ["vítězství"]="victory"
    ["příšery"]="monsters"
    ["trofeje"]="trophies"
    ["předměty"]="items"
    ["odpočinek"]="rest"
    ["vybavení"]="equipment"
    ["figurky"]="figurines"
    ["nápovědy"]="help-cards"
    ["zbraně"]="weapons"
    ["zvíře"]="beast"
    ["nemrtvý"]="undead"
    ["člověk"]="human"
    ["démon"]="demon"
    ["pohyb"]="movement"
    ["úkoly"]="quests"
    ["kouzla"]="spells"
    ["turnaj"]="tournament"
    ["dohrávání"]="finishing-round"
    ["palice"]="mace"
    ["bomba"]="bomb"
    ["skóre"]="score"
    ["kopí"]="spear"
    ["mapa"]="map"
    ["hory"]="mountains"
    ["meč"]="sword"
    ["luk"]="bow"
    ["boj"]="combat"
)

# Function to translate a comma-separated list of tags
translate_tags() {
    local input="$1"
    local result=""
    IFS=',' read -ra tags <<< "$input"
    for tag in "${tags[@]}"; do
        if [[ -n "${TAG_MAP[$tag]}" ]]; then
            tag="${TAG_MAP[$tag]}"
        fi
        if [[ -z "$result" ]]; then
            result="$tag"
        else
            result="$result,$tag"
        fi
    done
    echo "$result"
}

echo "Processing $FAQ_FILE ..."
tmpfile=$(mktemp)

# Keep header
head -1 "$FAQ_FILE" > "$tmpfile"

# Process each data line: only translate column 2 (tags)
tail -n +2 "$FAQ_FILE" | while IFS='|' read -r col1 col2 col3 col4; do
    new_tags=$(translate_tags "$col2")
    echo "${col1}|${new_tags}|${col3}|${col4}"
done >> "$tmpfile"

mv "$tmpfile" "$FAQ_FILE"

echo "Done! All CZ tags in faq.csv have been renamed to EN."
echo ""
echo "Verifying - first 5 data lines of faq.csv:"
head -6 "$FAQ_FILE"
