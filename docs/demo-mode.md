# Demo mode

Demo builds run the whole app against an in-memory backend, so the app can be
shown, tested or screenshotted without the NestJS API or a database.

```bash
flutter run --dart-define=TAPTOM_DEMO=true
flutter build web --release --dart-define=TAPTOM_DEMO=true
```

## How it works

`DemoInterceptor` (`lib/core/network/demo/`) is added to the Dio pipeline
after the authentication interceptor. It answers every request with data
shaped like the real API, including status codes and error bodies, and waits
180 to 420 ms so loading states show. Writes (approvals, new plots, GAP
records, messages, tickets) are kept until the app restarts. Tokens are signed
JWT-shaped strings, so the normal refresh and role checks run unchanged.

The data describes a kratom-growing community in Wang Thong, Phitsanulok:
members with plots in each review state, a full set of GAP records for one
plot, harvest lots with traceability reports, notifications, officer messages
and an audit trail.

## Sample accounts

The login screen in demo builds shows one-tap buttons for each account.

| Role | Phone | Birthday (B.E.) | PIN |
| --- | --- | --- | --- |
| Farmer | 0812345678 | 15/01/2518 | none |
| Officer | 0898765432 | 20/05/2528 | 123456 |
| System administrator | 0800000001 | 01/01/2525 | 12345678 |

## What still needs the network

- Satellite imagery: MapTiler when `MAPTILER_API_KEY` is set, otherwise Esri
  World Imagery with no key. Without internet access the map shows a plain
  ground colour and the plot outlines still draw.
- Ask Lung Tom answers from built-in samples in demo builds and whenever no
  `GEMINI_API_KEY` is configured.

## Screenshots

On your own computer, one command rebuilds the demo app and refreshes
`docs/screenshots` with real satellite imagery (Flutter and Node 18 or newer;
Playwright's Chromium is installed on the first run):

```bash
node tool/screenshots/run-local.js                # every scene
node tool/screenshots/run-local.js farmer,trace   # only the map scenes
```

This uses demo mode, so the images show the demo data rather than a backend.


The images in `docs/screenshots` come from a release web build in demo mode,
driven by Playwright at a 390 x 844 phone viewport (2x) and a 1280 x 800
desktop viewport. The script taps through the app using Flutter's semantics
tree, the same labels screen readers use.

```bash
flutter build web --release --dart-define=TAPTOM_DEMO=true
(cd build/web && python3 -m http.server 8787) &
npm install --no-save playwright && npx playwright install chromium
node tool/screenshots/capture.js                 # every scene
SCENES=farmer,admin node tool/screenshots/capture.js
```

Scenes: `login`, `motion` (the login GIF, needs ffmpeg), `farmer`, `trace`,
`admin`, `super`, `dark` and `desktop`.

The committed images were taken against a local TAPTOM backend instead of
demo mode: PostgreSQL with PostGIS, the backend's migrations, Thai locations,
and the same fictional people, plots and GAP records created through the API.
Build with `--dart-define=API_BASE_URL=http://localhost:3000/api/v1` and run
the script with `REAL_API=1` (sign in by typing rather than the demo buttons)
and `TRACE_LOT` set to a lot number from the database. Environment variables are listed at
the top of `tool/screenshots/driver.js`; `OFFLINE_TILES=1` and
`MAPLIBRE_DIST` let it run where map hosts are blocked, which is how the
committed images were made, so their maps show the ground colour instead of
imagery. Run it on a normal connection to get satellite imagery.
