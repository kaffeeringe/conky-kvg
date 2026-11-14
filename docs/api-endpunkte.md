# KVG-„internetservice“-API (inoffiziell, Reverse Engineering)

Basis-URL: `https://kvg-internetservice-proxy.p.networkteam.com/internetservice`
(Proxy der Agentur networkteam, hinter mobil.kielregion.de; dieselbe API nutzt z. B. auch das Projekt
[nairol203/kiel-bus-tracker](https://github.com/nairol203/kiel-bus-tracker). Es gibt keine offizielle Doku.)

## Endpunkte

| Zweck | Aufruf |
|---|---|
| Abfahrten an einer Haltestelle (Echtzeit) | `GET /services/passageInfo/stopPassages/stop?stop=<Haltestellennummer>&mode=departure` |
| Ankünfte | `...?stop=<Nummer>&mode=arrival` |
| Haltestellen in einem Gebiet | `GET /geoserviceDispatcher/services/stopinfo/stops?top=&bottom=&left=&right=` |
| Live-Fahrzeugpositionen | `GET /geoserviceDispatcher/services/vehicleinfo/vehicles?top=&bottom=&left=&right=` |
| Fahrtverlauf eines Kurses | `GET /services/tripInfo/tripPassages?tripId=<tripId>` |
| Haltestellen einer Linie | `GET /services/routeInfo/routeStops?routeId=<routeId>` |

## Koordinaten

`top/bottom/left/right` sind geografische Koordinaten in **Milliarksekunden**: `Grad × 3.600.000`
(z. B. Kiel Hbf 54.314982, 10.131976 → `top=195551935&bottom=195515935&left=36457114&right=36493114` für ±0.005°).

## Antwort `stopPassages` (relevante Felder)

- `stopName`, `stopShortName` – Haltestellenname und -nummer
- `actual[]` – kommende Abfahrten, je Eintrag:
  - `patternText` – Linie (z. B. `"22"`)
  - `direction` – Ziel
  - `mixedTime` – Restzeit als `"7 %UNIT_MIN%"` (Platzhalter ersetzen!) oder Uhrzeit `"21:50"`
  - `plannedTime` – Soll-Uhrzeit `"21:50"`; `actualTime` – Ist-Uhrzeit (abweichend = Verspätung)
  - `actualRelativeTime` – Sekunden bis Abfahrt
  - `status` – `PREDICTED` (Prognose), `PLANNED` (nur Fahrplan), `STOPPING` (Bus steht an der Haltestelle), `DEPARTED`
  - `tripId`, `routeId`, `passageid`, `vehicleId`
- `old[]` – bereits abgefahrene Kurse
- `routes[]` – Linien an der Haltestelle (inkl. `alerts`)
- `generalAlerts[]` – allgemeine Meldungen
- `firstPassageTime`, `lastPassageTime` – Zeitfenster der Antwort (Epoch ms)

Hinweis: `?stop=` erwartet die **vierstellige Haltestellennummer** (z. B. `2731`), nicht die lange interne `id`.
