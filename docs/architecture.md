# Architecture

TAPTOM is a Flutter client for a NestJS REST API. It runs on Android, iOS
and the web from one codebase.

## Layout

```
lib/
  main.dart              bootstrap: env, Thai date data, locator, shader warm-up
  app/
    app.dart             MaterialApp.router, providers, themes, text-scale clamp
    router.dart          every route and the role guard
    routes.dart          route names, role-to-home map, role requirements
    locator.dart         GetIt registrations for long-lived singletons
  core/
    config/              Env: .env plus --dart-define overrides, demo flag
    design/              palette, type scale, spacing, motion, icons, theme
    effects/             GLSL backdrops, the Lung Tom mascot, logo
    network/             ApiClient (Dio), endpoints, ApiException
      demo/              in-memory backend used by demo builds
    security/            secure token storage
    services/            one service per API area, plus PDF and cache helpers
    utils/               Thai dates, status labels, map styles, geometry
    widgets/             the shared component library (see design-system.md)
  data/models/           plain models with tolerant fromJson
  features/
    auth/                login, sign-up, PIN entry and setup, consent
    home/                farmer and staff dashboards, splash
    map/                 plot map, plot detail, boundary drawing
    gap/                 the seven GAP forms, overview, summary, gallery
    traceability/        public lot report and QR scanner
    admin/               members, plot review, messaging, audit trail
    super_admin/         console, officers, officer detail
    notifications/       notification centre and polling provider
    certificate/         GAP certificate list and preview
    chat/                Ask Lung Tom assistant
    support/             help tickets
    profile/, settings/, contact/
```

Features depend on `core` and `data`; `core` never imports a feature, with one
exception: `GapService` returns `GapProgress` from `features/gap`, which keeps
the GAP domain in one place.

## State

- `Provider` for app-wide state: `AuthProvider`, `SettingsProvider`,
  `NotificationProvider`, `AdminStateProvider`, `MessageProvider`.
- Screens own their transient state with `StatefulWidget`; most lists fetch on
  open and refresh with pull-to-refresh.
- `GapService.getProgress` caches a plot's seven categories for 45 seconds and
  fetches them in two small waves so several plots can load without tripping
  the API rate limiter. Every save calls `GapService.invalidate(plotId)`.

## Networking

`ApiClient` is a single Dio instance.

- Adds the bearer token, refreshes it once on 401 (concurrent requests share the
  same refresh), retries 429 with backoff, and maps every failure to
  `ApiException` with a Thai message.
- Ask Lung Tom posts the recent conversation to the backend's
  `/assistant/chat`, which holds the Gemini key and system prompt, so the app
  ships no AI credentials.
- In demo builds a `DemoInterceptor` sits after the auth interceptor and answers
  requests from memory, so the real request pipeline, including token handling,
  still runs.

## Roles and routing

Three roles: farmer (`USER`), officer (`ADMIN`) and system administrator
(`SUPER_ADMIN`).

- `Routes.rolesFor(path)` declares which roles may open a path: `/admin/*`
  for officers and super admins, `/super-admin/*` for super admins, the farmer
  home for farmers. Everything else needs only a session.
- The router guard sends signed-out users to login, users in the PIN step to
  PIN entry, and anyone on a path their role may not open to their own home.
- `/traceability/*` is public so buyers can open a lot report without an
  account.
- Within screens, `canManagePlot(user, plot)` limits approve, reject and
  boundary edits to officers whose territory (sub-district, district, province
  or region, most specific first) contains the plot. Super admins can act
  anywhere. The server enforces the same rules; the client check only hides
  actions that would fail.

## Sign-in

Members sign in with phone number and birthday. Staff then enter a PIN (six
digits for officers, eight for super admins) or set one on first sign-in.
Tokens live in secure storage; the last user is cached so the app opens
offline and refreshes the session in the background.

## Offline and drafts

GAP forms keep drafts per plot in SQLite on mobile and in shared preferences on
the web. The general-information form autosaves a draft every 30 seconds while
it has unsaved edits.

## PDFs

`PdfGeneratorService` builds the GAP inspection report and
`CertificatePdfService` the certificate. Both embed the bundled Sarabun font
and partner logos, so they work offline and on the web.
