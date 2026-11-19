# Season calendar and concept bank

A planning document: which seasons could run through the year, when, and what
each could contain. Nothing here is built unless marked **Live**.

How seasons work and how to add one: [SEASONS.md](SEASONS.md). Prompt rules:
[../PROMPT_ARCHITECTURE.md](../PROMPT_ARCHITECTURE.md).

> Dates are for the **Northern Hemisphere** and the **next 12 months from
> November 2026**. Lunar and religious dates (Eid, Diwali, Lunar New Year) are
> approximate and must be checked against an official calendar before
> shipping. The owner decides which markets matter; the plan assumes a global
> audience with a large Turkish segment.

## 1. Year at a glance

Status: **Live** = shipped, **Next** = recommended soon, **Idea** = optional.

| Month | Season | Window (proposal) | Status | Priority |
|---|---|---|---|---|
| Jan | Christmas tail → **Valentine's Day** | Christmas to Jan 15, Valentine's from Jan 25 | Live / Next | 1 |
| Feb | **Valentine's Day**, Lunar New Year (Feb 6, 2027) | Jan 25 – Feb 15; LNY Feb 1 – Feb 14 | Next / Idea | 1 / 5 |
| Mar | **Ramadan / Eid al-Fitr** (≈ Feb 8 – Mar 10, 2027), **Spring** begins | Moves yearly | Idea / Next | 4 / 2 |
| Apr | **Spring / Easter** (Mar 28, 2027), 23 April (TR) | Mar 15 – Apr 25 | Next | 2 |
| May | Mother's Day (May 9, 2027), Eid al-Adha (≈ May 17, 2027), 19 May (TR) | Short overrides | Idea | 5 |
| Jun | **Summer** (+ optional Pride overlays are NOT recommended, see section 5) | Jun 1 – Aug 31 | Next | 3 |
| Jul | Summer | | | |
| Aug | Summer, 30 August (TR) | | | |
| Sep | **Autumn** (back-to-school mood) | Sep 1 – Sep 30 | Idea | 6 |
| Oct | **Halloween**, 29 October (TR), Diwali (≈ Oct 29, 2027) | Oct 1 – Nov 5 | **Live** | – |
| Nov | **Thanksgiving / Harvest**, Christmas begins | Thanksgiving Nov 6 – Nov 24; Christmas Nov 25 | Idea / **Live** | 6 |
| Dec | **Christmas**, **New Year's Eve** | Christmas to Dec 25; NYE Dec 26 – Jan 2 | **Live** / Next | 4 |

### Visual timeline

```
        J   F   M   A   M   J   J   A   S   O   N   D
Xmas    ███                                     ░░███████
Valent  ░███
LunarNY  ░░█
Ramadan   ░░███                                  (moves)
Spring        ░███████
Summer                    ██████████████
Autumn                                  ███
Halloween                                   ████░
Thanksg.                                       ███
NYE     █                                          ░███
Evergreen  fills every gap
```

`█` main window, `░` ramp-up or tail.

### The gaps (today they all show Halloween)

| Gap | Length | Fix |
|---|---|---|
| Jan 16 – Jan 24 | 9 days | Valentine's early, or evergreen |
| Feb 16 – Mar 14 | 4 weeks | Spring early start, Ramadan/Eid, or evergreen |
| Apr 26 – May 31 | 5 weeks | Spring tail / Mother's Day / Eid al-Adha, or evergreen |
| Sep 1 – Sep 30 | 4 weeks | Autumn, or Halloween early |

An **evergreen default season** removes every gap in one move and is the
recommended fallback (section 4).

## 2. Concept sheets

Each sheet gives the look (palette, medallion, world scenery, particles) and
the **concept bank**: ideas for ready-made prompts. They are ideas, not final
prompt text. Final prompts must follow the rules in PROMPT_ARCHITECTURE.md
(text prompts describe the subject only; image prompts start with "the person"
and never hide the face or add identity wording).

Palette hexes are starting points: `accent`, `secondaryAccent`, `highlight`,
dark `scaffold`. Keep the base dark: the app is dark-mode only.

### Halloween (Live) and Christmas (Live)

Expansion ideas rather than new seasons:
- Halloween: *Day of the Dead* sub-pack, *cozy witchy autumn*, *80s slasher
  video-store*, *haunted school*, *pumpkin carving night*.
- Christmas: *Nordic Yule*, *Victorian Dickens street*, *gingerbread bakery*,
  *Krampus-free folklore*, *winter wedding*.
- Add 3 to 5 "new" styles per week during the season (a "New" badge brings
  users back).

### Valentine's Day: Jan 25 – Feb 15 (Next, priority 1)

Fills the January/February gap and suits portraits (couples, friends,
self-love).

- **Look:** rose `E8436E`, blush `FFB3C1`, peach `FF8FA3`, wine scaffold
  `1A0B14`. Medallion: a glossy heart. World: dusk sky with soft bokeh
  hearts, rose-petal particles drifting down.
- **Text to image:** candlelit dinner for two, a florist at golden hour,
  vintage love letters and wax seals, a rainy-window cafe, balloon-filled
  rooftop, a paper-cut heart garden, a love-note vending machine, two cats
  sharing a scarf, a velvet jewelry box open on a piano.
- **Image to image:** 1950s Valentine's card portrait, rose-garden stroll,
  masquerade-ball evening (half-mask only, face visible), a poet in a library,
  rooftop picnic, cozy cafe window, retro photo-booth strip, Cupid-themed
  outfit (wings, golden bow), a handwritten-letter reader.
- **Scene kits:** candlelit dining room, flower market, cafe window in the
  rain, vintage cinema lobby, rooftop at dusk, rose garden.
- **Notes:** romance is not sexual: keep moderation strict on lingerie,
  nudity and minors. Couples need two people; the current image flow handles
  one photo, so prompts stay single-person.

### Lunar New Year: ≈ Feb 1 – Feb 14, 2027 (Idea, priority 5)

- **Look:** red `D32F2F`, gold `FFC107`, ember `FF7043`, deep red-black
  scaffold `1A0808`. Keep it gold-heavy so it does not read as Christmas.
  Medallion: a lantern. World: lantern-lit street, floating lanterns.
- **Text to image:** red-lantern street at night, a lion dance mid-leap,
  paper-cut zodiac animal, a family reunion table, fireworks over a harbor,
  a calligraphy master, a dragon of silk and light, a night market.
- **Image to image:** festive silk jacket portrait, lantern-festival walk,
  a lion-dance parade spectator, tea-house portrait, zodiac-animal themed
  outfit, fireworks rooftop.
- **Notes:** the zodiac animal changes yearly (2027: Goat); use a data field,
  not hard-coded text. Have the content reviewed for cultural accuracy.

### Ramadan and Eid: moves yearly (Idea, priority 4)

Ramadan ≈ Feb 8 – Mar 9, 2027; Eid al-Fitr ≈ Mar 10; Eid al-Adha ≈ May 17.
Determined by moon sighting: use a lookup table or remote config.

- **Look:** gold `D4AF37`, teal `26A69A`, violet `7E57C2`, midnight scaffold
  `081A1F`. Medallion: a crescent with a star. World: night sky, lantern
  strings (fanous), soft minaret silhouettes.
- **Text to image:** a lantern-lit iftar table, crescent moon over a city,
  a courtyard with a fountain at dusk, a night bazaar with lanterns, dates and
  tea on a brass tray, geometric tilework close-up, a rooftop at sunset.
- **Image to image:** festive-clothing portrait, lantern-lit courtyard, a
  holiday table, a bazaar stroll, a calm night-sky portrait.
- **Notes:** needs respectful, **human-reviewed** content, no religious
  figures, no depiction of worship. Never gamify prayer. Check store policies
  for religious content. Greeting strings need native review.

### Spring / Easter: Mar 15 – Apr 25 (Next, priority 2)

- **Look:** blossom pink `F48FB1`, fresh green `A5D6A7`, butter `FFF176`,
  deep green scaffold `0E1A14`. Medallion: a decorated egg (or a flower
  bud for the secular version). World: morning mist, cherry-blossom petals
  falling.
- **Text to image:** cherry blossom avenue, a meadow of wildflowers with a
  picnic blanket, a rabbit in a hat among tulips, painted eggs in a nest,
  a greenhouse at sunrise, a rain-washed balcony garden, a watercolor
  butterfly garden, a bakery window with spring pastries.
- **Image to image:** blossom-tree portrait, flower-crown meadow, picnic in
  a park, garden-party outfit, rainy spring street with an umbrella, a
  greenhouse botanist.
- **Notes:** Easter moves (Mar 28, 2027); compute it or use a table. A
  secular "Spring" framing reaches more markets; add eggs as an option, not
  religious imagery.

### St. Patrick's Day: Mar 10 – Mar 17 (Idea, priority 7)

- **Look:** clover green `2E9E5B`, mint `B9F6CA`, deep green scaffold
  `08160D`. Medallion: a four-leaf clover.
- **Concepts:** a misty green hillside, a cozy pub window with lanterns, a
  stone bridge over a stream, a fiddle on a hay bale; portraits in a green
  scarf and flat cap, a countryside walk.
- **Notes:** alcohol imagery stays out of the library.

### Mother's Day: second Sunday of May (Idea, priority 5)

A one- or two-week override on top of Spring.
- **Concepts:** a flower-market bouquet, a kitchen breakfast tray, a
  hand-drawn card, a garden tea party, "my mom, as…" portraits.
- **Notes:** sensitive for users without a mother; keep the wording warm and
  optional.

### Summer: Jun 1 – Aug 31 (Next, priority 3)

The longest empty stretch of the year.

- **Look:** coral `FF7043`, sun `FFCA28`, sea `29B6F6`, deep ocean scaffold
  `0A1A26`. Medallion: a sun with a ring. World: sunset gradient, warm haze,
  drifting light dots.
- **Text to image:** a beach hut at golden hour, a vintage road-trip van, a
  night festival with string lights, a rooftop pool at dusk, a fruit-stand
  still life, a lighthouse coast, a campfire under stars, a surf board rack,
  a lemonade stand.
- **Image to image:** sunset beach portrait, road-trip window, festival
  crowd, poolside sunglasses look, camping night, retro 80s beach party,
  mountain-lake hiker, tropical-island explorer, street-food market evening.
- **Scene kits:** beach at sunset, rooftop pool, festival field, camp by a
  lake, coastal road, seaside town at night.
- **Notes:** swimwear: keep moderation strict; prefer clothed beach looks
  (shirts, sundresses). Southern Hemisphere users have winter in June: consider
  a user toggle.

### Autumn / Back to school: Sep 1 – Sep 30 (Idea, priority 6)

Fills September and bridges to Halloween.
- **Look:** amber `E07B39`, wheat `F2C14E`, oak `8D6E63`, warm-brown scaffold
  `1A100A`. Medallion: a leaf. World: falling leaves, low golden light.
- **Text to image:** a forest path of red leaves, a cozy reading nook with
  tea, a village market with squash, a covered bridge in mist, a library
  window in the rain.
- **Image to image:** dark-academia library portrait, leaf-pile walk, cozy
  cafe sweater look, farm-market stroll, rainy-day trench coat.
- **Notes:** overlaps with Halloween and Thanksgiving; merge them into one
  "Autumn" season (Sep 1 – Nov 24) with Halloween as a short Oct sub-window if
  you want fewer seasons to maintain.

### Thanksgiving / Harvest: ≈ Nov 6 – Nov 24 (Idea, priority 6)

- **Look:** pumpkin `E07B39`, cranberry `B3392F`, gold `F2C14E`, scaffold
  `1A100A`. Medallion: a cornucopia or a pie.
- **Text to image:** a candlelit harvest table, a farmhouse kitchen, a field
  of hay bales at dusk, autumn wreath on a door, a pie cooling on a window sill.
- **Image to image:** harvest-dinner portrait, apple-orchard walk, farm
  sweater and scarf, bonfire evening, family-photo-card style.
- **Notes:** mostly a US market; ship only if that audience matters. The
  4th Thursday of November (Nov 25, 2027).

### New Year's Eve: Dec 26 – Jan 2 (Next, priority 4)

The strongest sharing moment of the year. Overlaps Christmas (which runs to
Jan 15), so either a short override window or a Christmas sub-pack.

- **Look:** champagne gold `FFD54F`, silver `B0BEC5`, violet `7C4DFF`,
  midnight scaffold `070A1A`. Medallion: a disco-ball or a clock face. World:
  midnight sky, fireworks glow, confetti.
- **Text to image:** a rooftop party at midnight, fireworks over a city,
  a champagne tower, a countdown clock in a town square, a retro ballroom, a
  confetti-filled elevator.
- **Image to image:** sequin party look, glamorous ballroom, rooftop
  fireworks, 1920s Gatsby party, countdown clock-tower, sparkler portrait.
- **Notes:** alcohol imagery: keep it non-explicit; no minors holding drinks
  (moderation already blocks minor-related terms in risky contexts).

### Diwali: ≈ Oct 29, 2027 (Idea, priority 7)

- **Look:** magenta `FF4081`, gold `FFC107`, indigo `3F51B5`, deep indigo
  scaffold `0D1030`. It must differ from Halloween orange. Medallion: a diya
  (oil lamp). World: rows of tiny glowing lamps.
- **Concepts:** rangoli courtyard, lamp-lit rooftops, sweets on a brass
  platter, a festive silk portrait, fireworks over a town.
- **Notes:** needs native-reviewed cultural accuracy; dates move with the
  lunar calendar.

### Turkish national days (Idea, priority 7)

29 October (Republic Day), 23 April, 19 May, 30 August.

- **Concepts:** subtle flag-colored accents, city-skyline fireworks, historic
  architecture backdrops, a festive balcony. Keep them as one-day or one-week
  overrides.
- **Notes:** **do not gamify 10 November or 15 July** (solemn days); no
  playful generation, no map switch to a festive season. Use of flags and
  national figures needs care; avoid generating real historical persons.

### Evergreen worlds (not tied to a date)

Not seasons in the calendar sense, but they fit the world map and give a
dignified default outside holidays.

| World | Look | Image-to-image ideas |
|---|---|---|
| **Fantasy** | emerald + gold, mossy ruins, floating lights | elven ranger, castle guard, wizard-academy student, dragon rider |
| **Retro 90s** | teal + magenta, VHS glow | arcade evening, school-yearbook portrait, mall food-court, boombox street |
| **Cyberpunk** | neon cyan + pink, rain-wet streets | neon alley, hacker den, rooftop courier, ramen counter at night |
| **Fairytale** | dusty rose + sage, storybook woods | cottage dweller, forest queen, bookshop keeper, lantern fairy |

## 3. Per-season production checklist and effort

Each season needs (see SEASONS.md section 5 for the exact steps):

| Item | Amount | Notes |
|---|---|---|
| Text-to-image prompts | 10 | subject only; 3–5 popular |
| Image-to-image prompts | 10–20 | 20 is the current standard |
| Scene kits | 5–9 | at least one face-friendly |
| Generate-screen copy | 7 strings | `SeasonCopy` |
| Colors | 10 | accent, secondary, highlight, surfaces |
| Medallion shape + world style | 1 + 1 | map screen |
| Particles / swaps / art | 1 effect, ~10 swaps, 5 art entries | `SeasonDecor` |
| Preview images | one per prompt | optional; emoji fallback |
| Tests | completeness + library | copy `christmas_library_test.dart` |

Rough size: one season is ≈ 30 prompts of copywriting plus ≈ 1 day of theme,
medallion and world work. The prompt writing and previews are the long part.

## 4. Recommended order and fallback

1. **Valentine's Day** (Jan 25 – Feb 15): fills the first gap, high engagement.
2. **Spring** (Mar 15 – Apr 25): fills the second gap; secular by default.
3. **Summer** (Jun 1 – Aug 31): the longest gap.
4. **New Year's Eve** (Dec 26 – Jan 2): a short override with high sharing.
5. **Eid / Ramadan**, **Lunar New Year**: only with native review and a date
   source.
6. **Autumn / Thanksgiving**, **Diwali**, **national days**: market dependent.

**Fallback (the decision to make).** Today every uncovered date is Halloween,
which feels off in March and clashes with a Christmas tail in January. Options:

| Option | Pro | Con |
|---|---|---|
| Keep Halloween | Fits the "SpookyAI" brand | Out of season for most of the year |
| Evergreen "Classic" season | Never feels wrong | One more theme to design and write |
| Nearest-season rule | No new content | Looks stale, e.g. Christmas in February |

Recommendation: an **evergreen default** (for example *Fantasy*) plus the
seasonal windows above. Halloween then runs Sep 15 – Nov 5 as a real season.

## 5. Calendar rules

- Windows may overlap; **earlier entries in the table win** (put short
  high-value windows first, e.g. New Year's Eve before Christmas).
- Start a season **1–2 weeks before** the date (people search and plan early);
  end it a few days after.
- Do not switch the theme under a user **mid-generation** or mid-purchase.
  The season change restarts the app flow.
- Users can always pin a world on the map, so a window is only the
  **automatic** choice.
- Avoid theming identity or political observances (Pride, elections,
  commemorations) as playful seasons; a neutral evergreen is safer.
- Southern Hemisphere: June–August is winter. Offer a per-user hemisphere or
  simply let users pin Summer/Winter themes themselves.

## 6. Open decisions for the owner

1. Which markets to prioritize (global, US, Turkey, MENA)?
2. Evergreen fallback: Halloween, a new evergreen world, or nearest season?
3. Merge Halloween + Autumn + Thanksgiving into one long season?
4. How much native review is available for religious and cultural seasons?
5. Is a remote-config calendar needed for moving dates, or is a yearly
   code update acceptable?
6. Do paid users get early access to new seasons (a premium incentive)?
