# conky-kvg – KVG-Echtzeitabfahrten als Conky-Widget

Zeigt die nächsten Busabfahrten einer KVG-Haltestelle in Kiel als Desktop-Widget (Conky) an –
optisch angelehnt an die elektronischen Anzeigetafeln (DFI) an den Haltestellen:
schwarzer (halbtransparenter) Hintergrund, Spalten `Linie | Ziel | Min`,
Liniennummern und Minuten in Amber/Orange, Uhrzeit oben rechts.

Datenquelle: inoffizielle JSON-API der KVG („internetservice“), siehe [docs/api-endpunkte.md](docs/api-endpunkte.md).

## Voraussetzungen

- Ubuntu/Debian: `sudo apt install conky-all jq curl` (`conky-all` enthält die nötige Lua-Unterstützung; prüfen mit `conky -v | grep -i lua`)
- X11-Sitzung (bei Wayland am Login „Ubuntu on Xorg“ wählen)

## Installation

```bash
mkdir -p ~/.config/conky ~/.local/bin
cp conky/conky.conf   ~/.config/conky/conky.conf
cp conky/kvg.lua      ~/.config/conky/kvg.lua
cp bin/kvg-abfahrten.sh ~/.local/bin/kvg-abfahrten.sh   # nur Fallback ohne Lua
chmod +x ~/.local/bin/kvg-abfahrten.sh
```

Conky starten: `conky` – Konfiguration testen/neu laden mit `killall conky && conky`.

## Autostart

```bash
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/conky.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Conky
Exec=sh -c "sleep 5 && conky"
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
```

Alternativ als systemd-Userdienst: `~/.config/systemd/user/conky.service` mit
`ExecStart=/usr/bin/conky`, dann `systemctl --user enable --now conky.service`.

## Haltestelle ändern

Standard ist der **Hauptbahnhof (Haltestellennummer `2387`)**. Ändern:

1. In `~/.config/conky/kvg.lua` in der `URL` die `stop=2387` durch die gewünschte Nummer ersetzen.
2. In `~/.config/conky/conky.conf` den Titel `Hauptbahnhof` im `conky.text` anpassen.

Alle Haltestellennummern für das Kieler Stadtgebiet (488 Haltestellen, Stand der Abfrage siehe CSV):
[docs/haltestellen-kiel.csv](docs/haltestellen-kiel.csv) – Spalten:
`haltestellennummer,name,interne_id,kategorie,latitude,longitude`.
Beispiele: `2387` Hauptbahnhof, `2731` Petruskirche, `3001` Hbf/Kaistraße.

Die Liste kann jederzeit neu erzeugt werden (Koordinaten = Grad × 3.600.000, Bounding-Box Kiel
ca. lat 54.26–54.42, lon 9.96–10.26):

```bash
curl -s "https://kvg-internetservice-proxy.p.networkteam.com/internetservice/geoserviceDispatcher/services/stopinfo/stops?top=195912000&bottom=195336000&left=35856000&right=36936000" \
  | jq -r '.stops[] | [.shortName, .name, .id, .category, (.latitude/3600000), (.longitude/3600000)] | @csv'
```

## Anzeige anpassen

- **Transparenz:** in `conky.conf` `own_window_argb_value` ändern (255 = deckend, 180 = leicht transparent).
- **Farben:** `color1` (Amber, Standard `FFA500`), `default_color` (Weiß), `color2` (grau für Hinweise/Fehler).
- **Mehr/weniger Zeilen:** in `kvg.lua` bzw. `kvg-abfahrten.sh` das `.actual[:20]` anpassen.
- **Linien filtern:** im jq-Filter z. B. `select(.patternText == "6" or .patternText == "91")` ergänzen.
- **Spaltenbreite:** `pad(…, 5)` / `pad(…, 24)` in `kvg.lua` bzw. `%-5s` / `%-24s` in awk – Überschrift und Datenzeilen müssen identische Breiten haben. `pad()` zählt sichtbare Zeichen (UTF-8), damit Umlaute (z. B. „Reventloubrücke“) die Spalte nicht verschieben.
- **Fallback ohne Lua** (`conky-std`): in `conky.text` statt `${lua_parse kvg_abfahrten}` nutzen:
  ```
  ${color1}Hauptbahnhof${color}${alignr}${color1}${time %H:%M}${color}
  ${color1}${execi 30 /home/DEINUSER/.local/bin/kvg-abfahrten.sh}${color}
  ```

## Hinweise

- Die API ist **inoffiziell** (kein API-Key, keine Doku, kann sich ändern). Nicht öfter als alle 30–60 s pollen (`execi 30` / `update_interval`).
- `mixedTime` enthält den Platzhalter `%UNIT_MIN%` (→ „Min“ ersetzen); bei `status=PLANNED` steht dort stattdessen die Uhrzeit.
- Verspätung: `actualTime` weicht von `plannedTime` ab – das Widget zeigt die Ist-Uhrzeit dann grau in Klammern an.
- Am Hauptbahnhof fahren viele Linien takt-synchron zur selben Minute (Taktknoten) – gleiche Minutenangaben in mehreren Zeilen sind korrekt, siehe dazu mehr Zeilen via `.actual[:20]`.

## Lizenz

[GPL-3.0](LICENSE) (vom Repo-Initialcommit übernommen)
