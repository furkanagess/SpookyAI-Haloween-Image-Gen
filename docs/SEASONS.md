# Seasons

SpookyAI changes its whole look and content with the time of year. This
document explains how that works, how to add a season, which seasons are worth
adding, and what the review of the current code found.

Related: [PROMPT_ARCHITECTURE.md](../PROMPT_ARCHITECTURE.md) (how prompts are
built), [PROMPT_LIBRARY.md](PROMPT_LIBRARY.md) (Halloween prompts), and
[CHRISTMAS_PROMPT_LIBRARY.md](CHRISTMAS_PROMPT_LIBRARY.md) (raw Christmas
prompts shipped in the app).

## 1. The idea

A **season is a data bundle, not a code path.** The screens never ask "is it
Halloween?". They read the active season from one place and everything else
(colors, wording, particles, prompts, scenes, the map) follows. Adding a
season means adding data in a fixed set of places; no screen changes.

```
              SeasonId (enum)              <- the key everything hangs off
                   │
SeasonRegistry ── SeasonTheme ── colors, appTitle, emoji
   (calendar)          ├─ SeasonDecor ── word/emoji swaps, art, ambient effect, splash
                       └─ SeasonCopy ─── Generate screen wording
                   │
SeasonProvider ── auto (calendar) or pinned by the user (persisted)
                   │
SeasonPalette.current  <- static access for widgets without a BuildContext
                   │
   ┌───────────────┼──────────────────────────────┐
 UI theme      Prompt side                      Map screen
 (ThemeData)   PromptService library            medallion shape + world scenery
 effects       SceneKits (engine)
 transition    HalloweenPromptData (legacy lists)
```

Halloween is the **base season**: every user-facing string and bundled image
is authored for Halloween and other seasons translate it (section 3).

## 2. Where things live

| Concern | File |
|---|---|
| Season ids | `lib/core/theme/seasons/season_theme.dart` (`SeasonId`) |
| Colors, `ThemeData`, `SeasonCopy` | `lib/core/theme/seasons/season_theme.dart` |
| All season definitions + calendar | `lib/core/theme/seasons/season_registry.dart` |
| Words, emoji, art, particles, splash | `lib/core/theme/seasons/season_decor.dart` |
| Active season, user override | `lib/core/theme/seasons/season_provider.dart` |
| Static access (`SeasonPalette.accent`, `.t()`) | `lib/core/theme/seasons/season_palette.dart` |
| Ambient particles layer | `lib/core/theme/seasons/season_effects_layer.dart` |
| Splash hero | `lib/core/theme/seasons/season_splash_stage.dart` |
| Full-screen transition on change | `lib/core/theme/seasons/season_transition_overlay.dart` |
| Image replacement helper | `lib/core/theme/seasons/season_art_image.dart` |
| Ready-made prompts | `lib/features/home/data/services/prompt_service.dart` (Halloween) and `christmas_prompts.dart` |
| Scene kits (setting, light, effect) | `lib/core/prompt_engine/scene_kits.dart` |
| Legacy option lists | `lib/core/models/halloween_prompt_data.dart` |
| World map screen | `lib/features/home/presentation/pages/season_map_page.dart` |
| Entry points to the map | Generate app bar (map icon), Profile → Appearance |
| Wiring | `lib/main.dart` |

## 3. How a season reaches the screen

**Colors.** `SeasonTheme.toThemeData()` builds the Material theme. Widgets read
colors through `SeasonPalette.accent` / `.scaffold` / `.card` / etc. Never
hard-code a Halloween color in a screen.

**Words and emoji (`SeasonPalette.t`).** Strings are authored for Halloween and
pass through `SeasonPalette.t('...')`. `SeasonDecor.swaps` is a list of
substring replacements (`'🎃' → '🎄'`, `'Halloween' → 'Christmas'`,
`'spooky' → 'festive'`). Good for emoji and single words; **do not** use it for
whole sentences that only make sense for one season (use `SeasonCopy`).

**Generate screen wording (`SeasonCopy`).** Titles, hints and the "choose a
style" labels. Its defaults are the Halloween strings, so a new season that
forgets to set `copy` silently shows Halloween text. A test guards this
(section 6).

**Images (`SeasonArtImage` + `SeasonDecor.art`).** A screen asks for the base
(Halloween) asset path; a season can map it to another asset or an emoji.

**Ambient effect (`SeasonEffect`).** Falling or rising glyph particles over the
whole app. Pure data: glyphs, count, speed, sway, opacity.

**Prompts.** Three layers, all keyed by the active season:

1. *Library* (`PromptService`): 10 text + 20 image ready-made styles per season.
2. *Scene kits* (`SceneKits.forSeason`): matching setting + lighting + effect
   the engine adds when a prompt does not own its scene. Image-to-image only
   uses `faceFriendly` kits.
3. *Legacy lists* (`HalloweenPromptData.settings/lighting/effects`): older
   random pickers still used in a few paths. Despite the name they are
   per-season.

The centralized prompt templates also align a person's face with their body,
pose and surroundings. Every current and future season inherits this guidance
without duplicating it in each raw library entry.

**Switching.** `main.dart` keys the whole `MaterialApp` by `SeasonId`, so a
season change **rebuilds the entire app, including the navigator, and restarts
at the splash page.** The map screen therefore closes when the world changes;
that is expected. `SeasonTransitionOverlay` lives outside the keyed subtree so
its animation survives the rebuild.

## 4. Choosing the active season

`SeasonProvider.current` = the user's pinned season if any, otherwise
`SeasonRegistry.forDate(now)`.

- **Auto** follows the calendar. **Pinned** is saved in
  `SharedPreferences` (`season_override`) and survives restarts.
- Today's calendar: Christmas from Nov 25 to Jan 15, **Halloween the rest of
  the year** (including a long out-of-season stretch, see section 7).
- The map screen has a switch for Auto/Pinned and walks the marker to the
  chosen world.

## 5. Adding a season: checklist

Use this order; the compiler will point at the places marked *(forced)*.

1. **Id.** Add the value to `SeasonId`. *(Forces the next four steps: they are
   exhaustive `switch`es.)*
2. **Theme.** Add a `SeasonTheme` to `SeasonRegistry` and to `all`. Needed:
   `displayName`, `appTitle`, `emoji`, the 10 colors, `decor`, `copy`.
   - Keep text on `accent` readable (white on accent is used for buttons).
   - `secondaryAccent` and `highlight` are also used for the map medallion and
     halo; pick three colors that look good together.
   - Optional: the 7 `light*` fields (`lightScaffoldBackground`,
     `lightSurface`, `lightCard`, `lightCardGradientStart/End`,
     `lightInputFill`, `lightMutedText`) are this season's **light-mode**
     structural colors, used when the user picks Light (or System resolves
     to light) in Profile → Appearance → Theme. They default to a generic
     cream/white if omitted; author your own so the season still has an
     identity in daylight (see Halloween/Christmas for the pattern: a warm
     or cool near-white tinted toward the season's own card gradient).
     Brand colors (`accent`, `secondaryAccent`, `highlight`, `highlightDeep`,
     `seedColor`) are shared between dark and light — do not duplicate them.
3. **Calendar.** Add the date window in `SeasonRegistry.forDate` (section 7)
   and a test case in `test/season_theme_test.dart`.
4. **Prompt library** *(forced)*. New file `<season>_prompts.dart` like
   `christmas_prompts.dart`; wire it in `PromptService._libraryFor`. Rules:
   10 text + at least 10 image prompts, unique ids and titles across **all**
   seasons, tags that match the season's scene kits, image prompts start with
   "the person". Full rules: PROMPT_ARCHITECTURE.md and
   `test/prompt_library_test.dart`.
5. **Scene kits** *(forced)*. At least 5 kits in `SceneKits`, at least one
   `faceFriendly`. Reuse tag words from the library.
6. **Generating-screen voice** *(forced)*. `_tipsFor` in
   `generation_progress_dialog.dart`: four short lines in the season's voice.
7. **Legacy lists** *(forced)*. Settings, lighting and effects in
   `HalloweenPromptData`.
8. **Map scenery** *(forced, two places)*. `_styleOf` and the medallion painter
   in `season_map_page.dart`: choose a world style and draw the medallion
   shape (Halloween is a pumpkin, Christmas a bauble; a heart for Valentine's,
   an egg for spring, and so on).
9. **Words and art.** `decor.swaps` for emoji/words; `decor.art` for the five
   purchase-screen images; `decor.effect`; optionally `decor.splashLottie`.
10. **Previews.** Drop card images in `assets/prompt_previews/<prompt id>.jpg`.
   Cards without one show an emoji placeholder (add tag → emoji pairs in
   `prompt_preview.dart`).
11. **Docs.** Regenerate `docs/PROMPT_LIBRARY.md`
    (`rm docs/PROMPT_LIBRARY.md`, then run `test/prompt_docs_test.dart`).
12. **Tests.** `test/season_completeness_test.dart` must pass; it fails when a
    registered season is missing scene kits, a library, its own copy or its
    own ids.

Not season-aware today (decide per season, see section 7): the launcher icon,
store screenshots and listing text, push/notification copy, onboarding images.

## 6. What the tests enforce

| Test | Guards |
|---|---|
| `season_completeness_test.dart` | every `SeasonId` registered once; each season has identity, effect, ≥5 scene kits with a face-friendly one, 10 text + ≥10 image prompts, legacy lists; non-Halloween seasons do not reuse Halloween copy, accent or prompt ids; prompt ids unique across seasons (favorites are keyed by id) |
| `season_theme_test.dart` | calendar windows, override persistence |
| `prompt_library_test.dart` | Halloween library shape and prompt rules |
| `christmas_library_test.dart` | same rules for Christmas |
| `scene_kits_test.dart`, `prompt_engine_test.dart` | engine behavior per season |

A new season should also get a library test like `christmas_library_test.dart`
(or generalize it to loop over `SeasonRegistry.all`).

## 7. Candidate seasons

> A fuller year plan, with concept ideas per season, is in
> [SEASON_CALENDAR.md](SEASON_CALENDAR.md).

Chosen for what an image app does best: portraits and scenes people want to
post at a specific moment. Dates are Northern Hemisphere; the owner decides
which markets matter.

| Priority | Season | Window (proposal) | Why it fits | Look and content |
|---|---|---|---|---|
| 1 | **Valentine's Day** | Jan 25 – Feb 15 | Fills the Jan/Feb gap; strong portrait use (couples, "me as…") | Rose and cream, soft glow; heart medallion; cafe, florist, vintage cards, candlelit dinner |
| 2 | **Spring / Easter** | Mar 15 – Apr 25 (Easter moves) | Fills March–April | Pastels; egg medallion; blossoms, meadows, picnic; keep it secular/neutral |
| 3 | **Summer** | Jun 1 – Aug 31 | Longest empty stretch of the year | Sunset coral and sea teal; sun medallion; beach, road trip, festival, poolside |
| 4 | **New Year's Eve** | Dec 26 – Jan 2 (inside Christmas) | Highest sharing moment | Gold and midnight; could be a sub-theme of Christmas or a short override window |
| 5 | **Eid / Ramadan** | Moves by the lunar calendar | Large part of the Turkish audience | Needs respectful, reviewed content; dates need a lookup table or remote config |
| 6 | **Thanksgiving / Autumn** | Nov 6 – Nov 24 | Fills the Halloween→Christmas gap | Amber and brown; harvest table, forest cabin |
| 7 | **National days** (e.g. 29 October, 23 April for Turkey) | One-day or week windows | Local relevance | Flag colors are sensitive; start with a one-day override |

Also worth considering: **evergreen "worlds"** that are not tied to a date
(Fantasy, Retro 90s, Cyberpunk). They fit the map metaphor and give the app a
sensible default outside the festive months (see below).

### Calendar structure

The current `forDate` is a single `if` that falls back to Halloween. That does
not scale. Recommended shape:

```dart
// season_registry.dart
static const _windows = <(SeasonId id, int start, int end)>[ ... ]; // MMDD, may wrap the year
static SeasonId forDate(DateTime d) {
  final md = d.month * 100 + d.day;
  for (final w in _windows) { if (inWindow(md, w)) return w.id; }
  return fallback; // evergreen default
}
```

- **Order wins on overlap.** List short, high-value windows first (New Year's
  Eve before Christmas).
- **Wrapping windows** (Nov 25 – Jan 15) must be handled explicitly.
- **Moving holidays** (Easter, Eid) need computed or remote dates. The
  registry comment already notes that this table can later be overridden by
  remote config; that is the right place.
- **The fallback is a product decision.** Halloween out of season (a long
  stretch, e.g. March) feels odd and the app name is "SpookyAI". Options: keep
  Halloween (brand), or add an evergreen season used between holidays.

## 8. Review findings

What the review of the season system found, and what was done.

**Fixed**
- **Silent Halloween fallback.** The prompt library, the legacy lists and the
  map scenery chose the Christmas variant with `== christmas ? … : halloween`.
  A new season would have compiled and quietly shown Halloween content. They
  are now exhaustive `switch`es on `SeasonId`, so a new season does not build
  until each place is handled.
- **No completeness guard.** Added `test/season_completeness_test.dart`.

**Open, worth knowing**
- **`SeasonCopy` defaults are Halloween strings.** Forgetting `copy` on a new
  season shows Halloween text; only the test catches it. Safer: make the
  fields required.
- **`SeasonTheme.promptAssetPath` is unused.** It points to
  `assets/prompts/*.json`, which do not exist; prompts live in Dart. Remove
  the field or implement it, but do not rely on it.
- **`decor.swaps` is Halloween-shaped.** It is a string search/replace on
  Halloween text, which works for Christmas but gets awkward for seasons far
  from Halloween (Summer, Valentine's). For those, prefer `SeasonCopy` and
  per-season strings over more swaps.
- **Season change restarts the app flow** (keyed `MaterialApp`, navigator
  reset, back to splash). Acceptable for a rare action; it is why the map
  closes after a switch.
- **Static `SeasonPalette.current`.** Convenient, but it is set as a side
  effect of reading `SeasonProvider.current`. In tests set it explicitly.
- **Not season-aware:** launcher icon, store listing, screenshots, onboarding
  images.
- **Free vs premium** is season-independent: 3 prompts per mode are free, per
  season, ordered popular first (`PromptsProvider.freePromptsPerMode`). The
  Prompts banner counts locked styles across all seasons
  (`lockedCountAllSeasons`), including ones not currently visible.
- **Map and prompt counts** scale linearly: each season adds a region of
  360 px to the map and 30 prompts to the library.

## 9. Design guidelines for new seasons

- **One strong accent, one supporting color.** Halloween: orange + purple;
  Christmas: red + gold + green. The map medallion uses `accent`,
  `secondaryAccent` and `highlight`.
- **Dark base.** The app is dark-mode only; scaffold and card colors should be
  deep tones of the season's hue, not black.
- **No text on the map.** The medallion shape and colors carry the identity;
  only the season name is shown.
- **Prompts must stay inside the moderation rules**
  (CONTENT_MODERATION_GUIDELINES.md). Religious or cultural seasons get an
  extra human review before shipping.
- **Ship the whole bundle.** A half-done season is worse than none: it shows
  Halloween leftovers. Do not add it to `SeasonRegistry.all` until the
  checklist is complete.
