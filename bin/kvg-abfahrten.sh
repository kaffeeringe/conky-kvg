#!/usr/bin/env bash
export LC_ALL=C.UTF-8
STOP_FILE="$HOME/.config/conky/kvg-stop.conf"
STOP=2387
if [ -r "$STOP_FILE" ]; then
    v=$(sed -n 's/^STOP=//p' "$STOP_FILE" | head -1)
    [ -n "$v" ] && STOP="$v"
fi
URL="https://kvg-internetservice-proxy.p.networkteam.com/internetservice/services/passageInfo/stopPassages/stop?stop=${STOP}&mode=departure"
curl -sf --max-time 10 "$URL" \
  | jq -r '.actual[:20][] | [.patternText, .direction, (.mixedTime | sub("%UNIT_MIN%"; " Min"))] | @tsv' \
  | awk -F'\t' 'BEGIN{printf "%-5s  %-24s%s\n","Linie","Ziel","Min"}
               {printf "%-5s  %-24s%s\n", $1, $2, $3}'
