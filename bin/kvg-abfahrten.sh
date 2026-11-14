#!/usr/bin/env bash
export LC_ALL=C.UTF-8
URL="https://kvg-internetservice-proxy.p.networkteam.com/internetservice/services/passageInfo/stopPassages/stop?stop=2387&mode=departure"
curl -sf --max-time 10 "$URL" \
  | jq -r '.actual[:20][] | [.patternText, .direction, (.mixedTime | sub("%UNIT_MIN%"; " Min"))] | @tsv' \
  | awk -F'\t' 'BEGIN{printf "%-5s  %-24s%s\n","Linie","Ziel","Min"}
               {printf "%-5s  %-24s%s\n", $1, $2, $3}'
