# Design system

The 2.0 redesign replaced ad-hoc colours, gradients and font downloads with a
small set of tokens and components in `lib/core/design` and
`lib/core/widgets`. Screens read tokens through `BuildContext` extensions
(`context.palette`, `context.text`) and never hard-code colours.

## Principles

- One brand colour. Field green carries actions, selection and the hero
  header. Status colours (amber, clay, slate) appear only to mean pending,
  rejected or informational.
- White page, white cards, hairline borders. Depth comes from borders and
  spacing, not shadows or gradients.
- Thai first. Type sizes, line heights and the minimum tap target are set for
  Thai script and for older farmers who enlarge text.
- Motion explains change and stays short. Every animation respects the
  system's reduce-motion setting.

## Colour

`AppPalette` is a `ThemeExtension` with a light and a dark instance. Roles,
not hues:

| Role | Light | Use |
| --- | --- | --- |
| `background`, `surface` | `#FFFFFF` | page and cards |
| `surfaceSunken` | `#F2F4F1` | input fields, inset panels |
| `line`, `lineStrong` | `#E6E9E4`, `#D3D8D1` | borders and dividers |
| `ink`, `inkMuted`, `inkSubtle` | `#161D18`, `#4C554D`, `#6C746C` | text |
| `brand`, `brandStrong`, `brandSoft` | `#245A33`, `#1B4427`, `#E2EFDC` | actions, selection |
| `hero`, `heroInk` | `#1B4427`, `#F8F9F7` | the contour header |
| `warning` / `warningSoft` | `#8A5D0E` / `#FDF1CC` | pending |
| `danger` / `dangerSoft` | `#9A3A27` / `#F6E1DA` | rejected, destructive |
| `info` / `infoSoft` | `#34576A` / `#E1ECF0` | neutral notices |

Text on its paired soft background meets WCAG AA (5.0:1 or better; the lowest
pair is warning on warningSoft). Dark mode swaps every role;
nothing in a screen checks the brightness itself.

### Charts

Chart colours were checked for both themes and for colour-vision deficiency:

- status series, light: `#2F7041`, `#D9A21B`, `#B8432E`
- status series, dark: `#3A7D4A`, `#B58C22`, `#C24650`
- single trend line: `#2F7041` light, `#5E9F68` dark, 2 px, 10 percent area
  wash
- neutral or "other": `#CFCDC2` light, `#3F4A42` dark

The trend chart has a crosshair tooltip and switches to a table for screen
readers; the breakdown bar labels every segment with its count in the legend.
Colour is never the only cue.

## Type

| Family | Used for |
| --- | --- |
| Anuphan 400 to 700 | all interface text |
| Noto Serif Thai 600 and 700 | page titles and display numbers |
| IBM Plex Mono 400 and 500 | phone numbers, lot codes, coordinates |
| Sarabun 400 and 700 | generated PDFs only |

All fonts are bundled under `assets/fonts` with their OFL licences. Numbers in
tables and stat tiles use tabular figures (`.tabular`). The text-scale setting
offers four steps and the app clamps system scaling to 0.9 to 1.6 so layouts
stay intact.

## Spacing, radius, motion

- Spacing: 2, 4, 8, 12, 16, 20, 24, 32, 40, 56. Page gutter 20 on phones,
  wider on tablets through `context.pageGutter`.
- Radius: 6, 10, 14 (controls), 18 (cards), 24 (sheets), pill.
- Motion: 90, 160, 240, 380, 560 ms. `Motion.standard` for most changes,
  `Motion.emphasized` for things entering. List items enter with a 45 ms
  stagger. Page transitions rise 3.5 percent and fade.

## Components

| Widget | Purpose |
| --- | --- |
| `PageScaffold` | collapsing serif title, back button, pull to refresh, bottom bar slot |
| `HeroHeader` + `SheetContainer` | contour shader header with the rounded sheet below |
| `AppShell` | bottom navigation on phones, navigation rail from 600 px |
| `AppButton`, `AppIconButton` | primary, secondary, tonal, ghost, danger; loading state blocks repeat taps |
| `AppCard`, `ListGroup`, `ListRow`, `KeyValueRow` | content containers |
| `StatusBadge`, `InlineBanner`, `EmptyState`, `ErrorState` | feedback |
| `AppToast`, `AppDialogs`, `showAppSheet` | transient feedback, confirm and prompt dialogs, sheets |
| `StatTile`, `ProgressRing`, `SegmentedTabs`, `FilterChips` | data display and filtering |
| `TrendLineChart`, `StatusBreakdownBar` | charts |
| `SkeletonList`, `Shimmer` | loading placeholders shaped like the content |
| `PlotShape` | a plot's outline drawn from its coordinates |
| GAP form kit | `GapFormWrapper`, `FormSectionCard`, `ChoiceTile`, `DatePickerField`, `FormDropdownWithOther`, `GapRecordTile` |

## Lung Tom and the backdrops

- `FarmerMascot` is drawn with `CustomPainter`: a Thai farmer in a ngob hat,
  mo hom shirt and pha khao ma scarf, holding a kratom leaf. Moods: wave,
  happy, joy, think. He greets on login, fills empty states, celebrates saves
  and thinks while the assistant answers.
- `FieldBackdrop` (`shaders/field.frag`) renders layered ridgelines, swaying
  grass, a soft sun and drifting pollen behind the login form.
- `ContourBackdrop` (`shaders/contour.frag`) draws slowly shifting topographic
  lines in the hero headers.
- Both shaders have painter fallbacks, pause when off screen, and freeze when
  reduce motion is on.

## Writing

- Plain Thai, second person, short sentences. Buttons say what happens
  ("ส่งผลการตรวจ", not "ตกลง").
- Dates in the Buddhist era (`ThaiDate`). Areas in rai, ngan and square wah.
- No emoji in the interface, in generated text or in documentation.
