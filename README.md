# conky-kvg – KVG-Echtzeitabfahrten

Nächste Busabfahrten einer KVG-Haltestelle in Kiel im DFI-Look – als **Conky-Widget** (Linux-Desktop) und als **PWA** (Android/Handy). Datenquelle: inoffizielle KVG-„internetservice“-JSON-API, siehe [docs/api-endpunkte.md](docs/api-endpunkte.md).

![Vorschau](docs/preview.png)

**Features:** Echtzeit-Abfahrten (Echtzeit-Prognose, `sofort` bei 0 min, Soll-Uhrzeit bei reinen Fahrplandaten), Verspätungsanzeige, Lauftext-Fußzeile (`generalAlerts`), Doto-Black-Schrift, halbtransparentes Fenster ohne Flackern, konfigurierbare Haltestelle ohne Neustart, 30-s-API-Cache.

## Inhalt

```
conky/conky.conf            Conky-Konfiguration (Farben, Transparenz, Fonts, Layout)
conky/kvg.lua               Lua: API-Abruf (Cache 30 s), Formatierung, Lauftext
conky/kvg-stop.conf.example Haltestelle konfigurieren (STOP/NAME)
bin/kvg-abfahrten.sh        Fallback ohne Lua (curl+jq+awk)
app/widget.html             PWA fürs Handy (gleiches Design, lokale Fonts, Suche)
app/manifest.webmanifest    PWA-Manifest
app/fonts/                  Doto (woff2) + DejaVu Sans Mono (ttf), lokal gebundelt
app/icon-512.png            PWA-Icon
docs/api-endpunkte.md       API-Referenz (Endpunkte, JSON-Felder, Koordinaten)
docs/haltestellen-kiel.csv  488 Haltestellen im Kieler Stadtgebiet
docs/preview.png            Vorschaubild
```

## Voraussetzungen

- Ubuntu/Debian: `sudo apt install conky-all jq curl` (`conky-all` enthält Lua; prüfen: `conky -v | grep -i lua`)
- X11-Sitzung (bei Wayland am Login „Ubuntu on Xorg“ wählen)
- Doto installiert (`fc-list | grep -i doto`; als „Doto Black“ alternativ `${font 'Doto Black':size=…}`)

## Installation (Conky)

```bash
mkdir -p ~/.config/conky ~/.local/bin
cp conky/conky.conf   ~/.config/conky/conky.conf
cp conky/kvg.lua      ~/.config/conky/kvg.lua
cp conky/kvg-stop.conf.example ~/.config/conky/kvg-stop.conf
cp bin/kvg-abfahrten.sh ~/.local/bin/kvg-abfahrten.sh   # nur Fallback ohne Lua
chmod +x ~/.local/bin/kvg-abfahrten.sh
conky        # starten; neu laden: killall conky && conky
```

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

Alternativ systemd-Userdienst: `~/.config/systemd/user/conky.service` mit `ExecStart=/usr/bin/conky`, dann `systemctl --user enable --now conky.service`.

## Conky-Widget konfigurieren

### Haltestelle wechseln

Über `~/.config/conky/kvg-stop.conf` (aus `conky/kvg-stop.conf.example` kopiert):

```
STOP=3001
NAME=Hbf/Kaistraße
```

`STOP` = vierstellige KVG-Haltestellennummer, `NAME` = Titel (weiß, size 13). Ohne Conky-Neustart wirksam (Titel sofort, Daten spätestens nach 30 s Cache). Standard: Hauptbahnhof `2387`. Alle Nummern: [docs/haltestellen-kiel.csv](docs/haltestellen-kiel.csv) (Spalten `haltestellennummer,name,interne_id,kategorie,latitude,longitude`; Beispiele: `2387` Hauptbahnhof, `3001` Hbf/Kaistraße).

### Design

- **Farben:** `color1` = Amber (`FFA500`), `default_color` = Weiß, `color2` = Grau – in `conky.conf`.
- **Transparenz:** `own_window_argb_value` (255 = deckend, aktuell 80).
- **Flackern:** `double_buffer = true` ist gesetzt (zeichnet off-screen, tauscht atomar). Sonst: Compositor an, `update_interval` erhöhen (z. B. `5.0`).
- **Fonts:** Uhr + Tabelle in Doto Black via `${font Doto:size=…:weight=900}` in `conky.text`; Titel in DejaVu Sans Mono. Doto ist monospaced → die Zeichen-basierten Spaltenbreiten (`pad`/`lpad` in `kvg.lua`) bleiben gültig. Falls abgeschnitten: `minimum_width` anpassen (aktuell 260, damit die Uhr exakt über „Abfahrt“ steht).
- **DFI-Layout:** Uhr eigene Zeile oben rechts über der Spalte „Abfahrt“ (`${alignr}`); Abfahrt rechtsbündig (`lpad(…, 8)`), Format `6min`, bei `0min` → `sofort`, bei `status=PLANNED` die Soll-Uhrzeit (`8:35`); bei Verspätung (`actualTime ≠ plannedTime`) steht die Ist-Uhrzeit in der Abfahrt-Spalte. Lauftext-Fußzeile aus `generalAlerts` (Conky `${scroll 39 …}`, mehrere Meldungen mit ` +++ ` getrennt).
- **Mehr/weniger Zeilen / Linien filtern:** `.actual[:20]` bzw. `select(.patternText == "6" …)` im jq-Filter in `kvg.lua`.
- **Fallback ohne Lua** (`conky-std`): in `conky.text` die `${lua_parse …}`-Zeile ersetzen durch `${execi 30 ~/.local/bin/kvg-abfahrten.sh}` (liest ebenfalls `kvg-stop.conf`; Titel dann manuell in `conky.text`).

## Android / Smartphone (PWA)

Conky läuft nur unter X11 – auf dem Handy nimmst Du die Web-App in `app/widget.html` (gleiche API und gleiches Design; CORS erlaubt: `Access-Control-Allow-Origin: *`; Fonts lokal in `app/fonts/`, kein Google-Request; Lizenzen: Doto = SIL OFL 1.1, DejaVu = Bitstream-Vera).

1. **GitHub Pages:** Repo → *Settings → Pages → Branch `main`, Folder `/ (root)`* → Save.
2. **Handy:** Chrome öffnen, z. B. `https://kaffeeringe.github.io/conky-kvg/app/widget.html`, Menü (⋮) → „Zum Startbildschirm hinzufügen“ → Vollbild-App, aktualisiert alle 30 s.
3. **Haltestelle wechseln (ohne ID):** Suchfeld oben (Autovervollständigung aus `docs/haltestellen-kiel.csv`, nur Namen, keine Nummern; Schrift DejaVu Sans Mono; per ☰/✕-Button rechts oben ausblendbar → Original-Look, gemerkt in `localStorage`). Auswahl landet in `localStorage` und in der URL (`?stop=…&name=…`) – Priorität: URL > localStorage > Default (Hbf `2387`). Zum Teilen einfach URL mit Parametern.

Alternativen: KWGT/Kustom-Widget (`$wg(url, jsonpath)$`), Termux + Termux:Widget (führt `bin/kvg-abfahrten.sh` aus), fertige Apps (NAH.SH-App, mobil.kielregion.de als PWA, kiel-live).

## API-Referenz & Haltestellenliste

- Endpunkte, JSON-Felder, Koordinaten-Skalierung (Grad × 3.600.000): [docs/api-endpunkte.md](docs/api-endpunkte.md)
- Haltestellenliste neu erzeugen (Bounding-Box Kiel ca. lat 54.26–54.42, lon 9.96–10.26):

```bash
curl -s "https://kvg-internetservice-proxy.p.networkteam.com/internetservice/geoserviceDispatcher/services/stopinfo/stops?top=195912000&bottom=195336000&left=35856000&right=36936000" \
  | jq -r '.stops[] | [.shortName, .name, .id, .category, (.latitude/3600000), (.longitude/3600000)] | @csv'
```

## Hinweise

- Die API ist **inoffiziell** (kein Key, keine Doku, kann sich ändern). Abruf max. alle 30 s – in `kvg.lua` eingebaut (`CACHE_SECONDS = 30`, Cache über `os.time()`); Fallback nutzt `execi 30`.
- `mixedTime` enthält `" %UNIT_MIN%"` (mit Leerzeichen) → wird zu `min`/`sofort` verarbeitet; bei `status=PLANNED` steht dort die Soll-Uhrzeit.
- Bei Lua-Fehlern Conky im Terminal starten – die Fehlermeldung erscheint auf stderr (z. B. `kvg.lua:…: syntax error near …`).

## Lizenz

[GPL-3.0](LICENSE)
