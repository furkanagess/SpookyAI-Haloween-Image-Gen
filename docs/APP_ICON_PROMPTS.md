# App icon prompts (one per season)

Prompts for generating the launcher icon of each season. The user picks the
icon in **Profile → Appearance → App icon** (see `AppIconService`).

All icons must read as **one family**: same composition, same lighting, same
level of detail. Only the hero object and the palette change.

---

## Shared rules (apply to every prompt)

| Rule | Why |
|---|---|
| **One hero object**, centered, filling ~70% of the canvas | Readable at 29–48 px |
| Hero sits inside the **central 66%** (Android adaptive safe zone) | Launchers crop corners into circles/squircles |
| **Square 1:1**, full-bleed background, **no transparency** | iOS rejects alpha in app icons |
| **No text, letters, numbers, logos, watermarks, frames, borders** | Text is unreadable at icon size; OS adds its own mask |
| Dark, smooth **radial gradient background** in the season's base color | Matches the app's dark scaffold; hero pops |
| Hero has a **soft inner glow + rim light** in the season accent color | Family signature (same as the current pumpkin icon) |
| Few, subtle particles **behind** the hero, never over its silhouette | Atmosphere without noise |
| Clean, bold silhouette, high contrast, minimal fine detail | Survives downscaling |
| Style: **polished 3D render, soft studio light, slight glossy finish** | Modern store look, consistent across seasons |

### Shared negative prompt

```
text, letters, words, numbers, logo, watermark, signature, border, frame,
rounded corners, app icon mockup, phone, hands, multiple objects, cluttered
background, busy scene, landscape, people, faces of real persons, photo,
blurry, low contrast, noise, grain, jpeg artifacts, cropped subject,
subject touching edges, transparent background, flat clip art
```

### Shared prompt suffix

Append this to every season prompt:

```
centered composition, single subject filling 70% of the frame, subject fully
inside the central safe area, smooth dark radial gradient background, soft
rim light, subtle glow, few soft bokeh particles behind the subject, bold
clean silhouette, high contrast, polished 3D render, soft studio lighting,
glossy finish, app icon, 1:1 square, ultra sharp, no text
```

---

## Live seasons

### Halloween 🎃 — `assets/icons/app_icon.png`

Palette: background `#0F0B1A` (deep violet-black), accent `#FF6A00` (pumpkin
orange), highlight `#B25AFF` (purple).

```
A friendly-spooky carved jack-o'-lantern glowing from inside with warm orange
light, sharp triangular eyes and a jagged grin, curled dark stem, faint
magical purple sparks drifting around it, deep violet-black background
(#0F0B1A) fading to a soft purple glow behind the pumpkin, orange (#FF6A00)
inner light and purple (#B25AFF) rim light
```

### Christmas 🎄 — `assets/icons/app_icon_christmas.png`

Palette: background `#07140F` (deep pine-black), accent `#E53935` (red),
highlight `#43A047` (green).

```
A cute rounded snowman head wearing a small red knitted beanie and red
scarf, coal eyes and a carrot nose, gentle smile, soft snow sparkle on
the hat, a few warm golden fairy-light bokeh dots behind, deep pine-green
to black background (#07140F) with a soft warm glow behind the subject,
red (#E53935) accents and green (#43A047) rim light
```

Alternative hero (if the snowman reads too busy at small size):

```
A glowing stylized Christmas tree made of soft emerald glass, golden star
on top, a few red ornaments, warm light radiating from inside, deep
pine-black background (#07140F), red (#E53935) and green (#43A047) accents
```

---

## Planned seasons (from `SEASON_CALENDAR.md`)

Palettes are proposals; take the final values from the season's entry in
`season_registry.dart` once it exists.

### Valentine's Day 💘

```
A glossy plump heart made of soft rose-red glass with a tiny golden arrow
through it, warm pink inner glow, small floating hearts as bokeh behind,
deep wine-black background (#1A0710), rose (#FF2E63) accent and blush pink
(#FF8FB1) rim light
```

### Spring / Easter 🌸

```
A pastel decorated egg resting in a tiny nest with a single cherry blossom,
soft morning light, a few floating petals behind, deep twilight-teal
background (#0B1A1A), blossom pink (#FF9EC7) accent and fresh mint
(#7BE0AD) rim light
```

### Summer ☀️

```
A cheerful glowing sun-orange ice cream cone with a single scoop and a tiny
cherry on top, warm golden-hour light, a few sparkling light flecks behind,
deep ocean-navy background (#061626), sunny orange (#FFA726) accent and
aqua (#26C6DA) rim light
```

### Autumn 🍂

```
A single glossy maple leaf in amber and crimson, gently curled, warm light
glowing through its veins, a few small drifting leaves as bokeh behind,
deep cocoa-black background (#160D07), amber (#FF8F00) accent and rust
(#C0392B) rim light
```

### Thanksgiving / Harvest 🌾

```
A cozy woven harvest basket overflowing with a small pumpkin, golden wheat
and a red apple, warm candle-like light, soft golden dust behind, deep
chestnut-brown background (#140C06), harvest gold (#FFB300) accent and
burnt orange (#E65100) rim light
```

### New Year's Eve 🎆

```
A sparkling champagne-gold firework burst shaped like a star, bright core
with radiating golden trails, a few tiny confetti flecks behind, deep
midnight-navy background (#050A1F), gold (#FFD54F) accent and electric
violet (#7C4DFF) rim light
```

### Ramadan / Eid 🌙

```
A slender golden crescent moon cradling a small ornate glowing lantern,
warm soft light, a few tiny stars twinkling behind, deep night-indigo
background (#0A0B24), gold (#FFC94D) accent and emerald (#1DB980) rim light
```

### Lunar New Year 🧧

```
A round glowing red paper lantern with a gold tassel and subtle gold
pattern (no characters or text), warm inner light, a few golden sparks
behind, deep lacquer-black background (#140606), red (#E53935) accent and
gold (#FFC107) rim light
```

---

## Export checklist

1. Generate at **1024×1024** (or larger, then downscale), PNG, **no alpha**.
2. Check at 48 px and 29 px: the hero must still be recognizable.
3. Check with a circle mask: nothing important outside the central 66%.
4. Put the files in place:
   - Flutter preview: `assets/icons/app_icon_<season>.png` (512×512)
   - iOS: `ios/Runner/Assets.xcassets/AppIcon-<Season>.appiconset/` (1024×1024)
     and add the name to `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher_<season>.png`
     (48/72/96/144/192) and a new `activity-alias` in `AndroidManifest.xml`
5. Register the season in `AppIconService.previewAssets`, `MainActivity.kt`
   and `AppDelegate.swift`; run `flutter test test/app_icon_service_test.dart`.
