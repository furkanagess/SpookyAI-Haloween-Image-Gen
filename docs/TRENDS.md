# Trends tab (Firestore)

The Trends tab reads the `trend_sections` collection in Firestore
(project `spookyai-app-ratings`). Add, edit or hide trends in the Firebase
console; the app picks them up on next open or pull-to-refresh, with no app
update. The app can only read this collection (see `firestore.rules`).

## One document = one section

Document id: any short slug (`gta6`, `thanksgiving`).

| Field | Type | Notes |
|---|---|---|
| `title` | string | Required. Section name. |
| `subtitle` | string | Optional one-liner under the title. |
| `emoji` | string | Optional; not shown on the screen at the moment. |
| `accent` | string | Optional `#RRGGBB` glow color for this section. |
| `order` | number | Lower shows first. |
| `active` | boolean | `false` hides the section. |
| `startsAt` / `endsAt` | timestamp | Optional; shown only inside this window. |
| `items` | array of maps | The styles (below). |

### Item map

| Field | Type | Notes |
|---|---|---|
| `id` | string | Stable id, unique in the section. |
| `title` | string | Required. Shown on the card. |
| `prompt` | string | Required. Sent to fal, **never shown**. Keep it short and descriptive. |
| `tagline` | string | Short line on the card. |
| `description` | string | One or two sentences on the detail sheet. |
| `imageUrl` | string | Preview image: a Storage path (`trends/gta6/poster.jpg`), a `gs://` URL or any https URL. |
| `type` | string | `text` (from text) or `image` (uses the user's photo). |
| `isHot` | boolean | HOT item; in the top carousel when `heroItems` is empty. |
| `isPremium` | boolean | Locked for non-premium users. |
| `ownsScene` | boolean | `true` if the prompt sets its own scene and light. |
| `kind` | string | `realistic` or `fantasy`. |
| `tags` | array | Optional tags shown on the detail sheet. |
| `active` | boolean | `false` hides this item. |
| `badge` | string | Optional custom badge, e.g. `NEW`, `LIMITED`. |
| `badgeColor` | string | `#RRGGBB` for that badge (default: section color). |

Section extra: `showCount` (boolean, default true) shows the "N styles" chip.

## Screen texts and colors: `trend_config/screen`

Everything else on the screen comes from one document, `trend_config/screen`.
Every field is optional; a missing field keeps the built-in default. A full
example with the defaults is in `docs/trend_config.sample.json`.

| Field | Default | What it controls |
|---|---|---|
| `tabLabel` | Trends | Bottom bar label |
| `tabColors` | pink → orange | 2+ `#hex` gradient of the highlighted tab |
| `appBarTitle` | Trends | Top bar title |
| `showHeader` | true | Big headline block |
| `headline` / `subheadline` | … | Headline texts (`\n` = new line) |
| `headlineColors` | season colors | 2+ `#hex` colors of the moving gradient |
| `showLive` / `liveText` / `liveColor` | true / LIVE / #FF2D55 | Pulsing badge |
| `showHero` / `heroTitle` | true / "" | Top carousel and its title |
| `heroItems` | [] | Top carousel cards, in order, as `"sectionId/itemId"` (e.g. `"gta6/loading_screen"`). Empty = all `isHot` items. Hidden or unknown ones are skipped |
| `showBadges` / `showTagline` / `showSectionLabel` | false | Card extras: all badges (NEW, PRO, HOT…), tagline line, section name on carousel cards. Off = image + title + button only |
| `tryText` / `unlockText` | Try it now / Unlock | Card button |
| `hotText` / `hotColor` | "" (hidden) | HOT badge; set e.g. "🔥 HOT" to show it |
| `showPhotoBadge` / `photoText` / `photoColor` | false / 📸 Your photo | Photo-style badge (hidden by default) |
| `proText` / `proColor` | 👑 PRO | Locked badge |
| `countText` | {n} styles | Section chip (`{n}` = count) |
| `emptyTitle` / `emptyBody` | … | No trends |
| `errorTitle` / `errorBody` / `refreshText` | … | Load failed |
| `glow` / `glowSeconds` | true / 4 | Running light around cards, seconds per lap |
| `accent` / `secondaryAccent` | season colors | Default glow colors |

## Preview images (Firebase Storage)

1. Firebase console → Storage → open (or create) the `trends/` folder and
   upload the image, e.g. `trends/gta6/poster.jpg`. JPG/PNG/WebP, about
   800×1000 px and under 300 KB keeps cards fast.
2. In the item's map, set `imageUrl` to that path: `trends/gta6/poster.jpg`.

Only files under `trends/` are public (see `storage.rules`). Without an
image the card shows a gradient in the section color.

Or put `"imageFile": "images/poster.jpg"` (relative to the JSON) on an item
and run the seed script: it uploads the file and fills `imageUrl` for you.

## Upload

```bash
node tool/seed_trends.cjs
```

writes both sample files (sections + screen config) with your Firebase CLI
login. Edit the JSON and run it again to update.

## Example

```json
{
  "title": "GTA 6 Vibes",
  "subtitle": "Neon Miami, loading-screen art",
  "emoji": "🌴",
  "accent": "#FF2D95",
  "order": 1,
  "active": true,
  "items": [
    {
      "id": "loading_screen",
      "title": "Loading Screen Poster",
      "tagline": "You, as cover art",
      "type": "image",
      "isHot": true,
      "ownsScene": true,
      "kind": "fantasy",
      "imageUrl": "https://…",
      "prompt": "Bold illustrated video game loading screen portrait of the person, thick outlines, cel shading, Miami beach at sunset with palm trees and neon signs behind them. Keep the same face."
    }
  ]
}
```

```json
{
  "title": "Thanksgiving",
  "emoji": "🦃",
  "accent": "#FF8A00",
  "order": 2,
  "endsAt": "<timestamp: 2026-12-01>",
  "items": [
    {
      "id": "cozy_table",
      "title": "Cozy Family Feast",
      "tagline": "Warm candlelit dinner",
      "type": "image",
      "isHot": true,
      "ownsScene": true,
      "prompt": "Warm candid photo of the person at a Thanksgiving dinner table with roast turkey, pumpkin pie and autumn leaves, soft candlelight. Keep the same face."
    }
  ]
}
```

A style picked from Trends is used once on the Generate screen; it is not
restored after the app restarts.
