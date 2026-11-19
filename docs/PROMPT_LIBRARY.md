# Halloween prompt library — ready to use

> Generated from the live code by `test/prompt_docs_test.dart`; do not edit by hand.
> Regenerate: `UPDATE_PROMPT_DOCS=1 flutter test test/prompt_docs_test.dart`.

Each entry has:

- **Raw prompt** — what is stored in the library and shown in the app.
- **Applied generation guidance** — the few words the app adds to each prompt (image prompts: one face sentence; text prompts: "realistic photo").
- **Ready-to-use prompt** — exactly what the app sends to the model: the raw prompt wrapped by the prompt architecture (`PromptEngine`) with the scene that fits it best. Paste this into a playground to test.
- **Other scenes** — alternatives the app may pick for the same prompt (it always uses the best-fitting scene; library prompts carry their own place).

Prompts marked *own scene* describe their own place and light, so no scene is added.

## Settings to use with the ready-to-use prompts

| | Text to Image | Image to Image |
|---|---|---|
| Model (current) | `openai/gpt-image-2` | `openai/gpt-image-2/edit` |
| Settings | `aspect_ratio` 1:1, `resolution` 1K, `output_format` jpeg, `safety_tolerance` 3, web search off | `image_size` portrait_4_3, `quality` high, jpeg, safety checker on |
| Negative prompt | not supported (the prompt words its limits positively) | not supported |
| Input | – | a clear, front-facing photo |

Neither model takes a negative prompt or a strength value. Prompts are kept short on purpose, so paste the ready-to-use text as is.

---

## Text to Image (10)

### Pumpkin King  `pumpkin_king`
*Premium · Popular · own scene* · tags: pumpkin, fantasy, horror

**In-app copy:** *A crown of thorns, a lantern for a scepter.* — A towering king with a glowing carved face rules from a throne of twisted roots. Autumn folklore in a crimson velvet cape.

**Raw prompt**

```
A pumpkin-headed king on a throne of twisted roots, tattered crimson cape, crown of black iron thorns, carved face glowing from within, in a moonlit pumpkin patch full of glowing jack-o'-lanterns.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (212 chars)

```
A pumpkin-headed king on a throne of twisted roots, tattered crimson cape, crown of black iron thorns, carved face glowing from within, in a moonlit pumpkin patch full of glowing jack-o'-lanterns, realistic photo
```

### Moonlit Witch  `moonlit_witch`
*Premium · Popular · own scene* · tags: witch, moon, fantasy

**In-app copy:** *She brews by moonlight, the cat supervises.* — A silver-haired witch lifts a glowing green potion, midnight robes stitched with stars and a black cat at her feet.

**Raw prompt**

```
A witch with long silver hair and a pointed hat holding a glowing green potion, midnight-blue robes, a black cat at her feet, on a misty hilltop under a huge full moon.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (184 chars)

```
A witch with long silver hair and a pointed hat holding a glowing green potion, midnight-blue robes, a black cat at her feet, on a misty hilltop under a huge full moon, realistic photo
```

### Crimson Vampire  `vampire_noble`
*Premium · own scene* · tags: vampire, gothic, nobility

**In-app copy:** *Velvet, rings and centuries of charm.* — An aristocrat in a high-collared coat raises a crystal goblet. Pale, elegant and just a little dangerous.

**Raw prompt**

```
A pale aristocratic vampire in a high-collared black velvet coat raising a crystal goblet, faint fangs, in a candle-lit gothic castle hall with arched windows and red drapes.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (190 chars)

```
A pale aristocratic vampire in a high-collared black velvet coat raising a crystal goblet, faint fangs, in a candle-lit gothic castle hall with arched windows and red drapes, realistic photo
```

### Friendly Ghost  `friendly_ghost`
*Free · Popular · own scene* · tags: ghosts, fantasy, supernatural

**In-app copy:** *The least scary ghost in the house.* — A round-eyed ghost drifts along with a tiny lantern, trailing soft light. Storybook sweet, never frightening.

**Raw prompt**

```
A cute ghost in a flowing white sheet with big round glowing eyes, floating and holding a tiny lantern, in a cozy old attic with wooden beams and a round window at night, warm lantern glow.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (205 chars)

```
A cute ghost in a flowing white sheet with big round glowing eyes, floating and holding a tiny lantern, in a cozy old attic with wooden beams and a round window at night, warm lantern glow, realistic photo
```

### Skeleton Musician  `skeleton_musician`
*Premium · own scene* · tags: skeletons, horror, vintage

**In-app copy:** *A dapper skeleton, a violin, no regrets.* — Bones polished like ivory, a tattered tailcoat and a single candle flame floating over the strings, mid-dance.

**Raw prompt**

```
A skeleton in a tattered tailcoat and top hat playing the violin with passion, on the wooden stage of a dusty vintage theater, red velvet curtains, a single warm spotlight.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (188 chars)

```
A skeleton in a tattered tailcoat and top hat playing the violin with passion, on the wooden stage of a dusty vintage theater, red velvet curtains, a single warm spotlight, realistic photo
```

### Werewolf Howl  `werewolf_howl`
*Premium · own scene* · tags: horror, supernatural, moon

**In-app copy:** *One howl at the full moon.* — A powerful werewolf with its head thrown back, torn shirt and amber eyes, every strand of fur catching the moonlight.

**Raw prompt**

```
A werewolf howling with its head thrown back, torn shirt over thick fur, glowing amber eyes, on a rocky ridge above a dark pine forest under a bright full moon, thin mist.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (187 chars)

```
A werewolf howling with its head thrown back, torn shirt over thick fur, glowing amber eyes, on a rocky ridge above a dark pine forest under a bright full moon, thin mist, realistic photo
```

### Black Cat Familiar  `black_cat_familiar`
*Free · Popular · own scene* · tags: witch, fantasy, supernatural

**In-app copy:** *Small cat, big spellbook.* — A sleek black cat in a crooked witch hat sits on an antique spellbook, with a candle and dried herbs close by.

**Raw prompt**

```
A black cat with yellow eyes and a tiny crooked witch hat sitting on an old spellbook, a lit candle and dried herbs beside it, on a wooden desk in a witch's cottage, warm candlelight.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (199 chars)

```
A black cat with yellow eyes and a tiny crooked witch hat sitting on an old spellbook, a lit candle and dried herbs beside it, on a wooden desk in a witch's cottage, warm candlelight, realistic photo
```

### Jack-o'-Lantern Still Life  `jack_o_lantern_still_life`
*Free · own scene* · tags: pumpkin, vintage

**In-app copy:** *Five pumpkins, five moods.* — A candlelit table of hand-carved jack-o'-lanterns, scattered leaves and a lace cloth, glowing like an October evening.

**Raw prompt**

```
Five hand-carved jack-o'-lanterns of different sizes and faces on a rustic wooden table, candles glowing inside, scattered autumn leaves and small gourds, warm light across the table.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (199 chars)

```
Five hand-carved jack-o'-lanterns of different sizes and faces on a rustic wooden table, candles glowing inside, scattered autumn leaves and small gourds, warm light across the table, realistic photo
```

### Ghost Bride  `ghost_bride`
*Premium · own scene* · tags: ghosts, gothic, supernatural

**In-app copy:** *A wedding that never quite ended.* — A veiled bride drifts like smoke, holding black roses. Calm, sorrowful and slowly dissolving into mist.

**Raw prompt**

```
A ghostly bride in a tattered lace gown and smoky veil holding wilted black roses, sorrowful expression, edges fading into mist, in an overgrown Victorian graveyard at night, stone angels in fog.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (211 chars)

```
A ghostly bride in a tattered lace gown and smoky veil holding wilted black roses, sorrowful expression, edges fading into mist, in an overgrown Victorian graveyard at night, stone angels in fog, realistic photo
```

### Raven Queen  `raven_queen`
*Premium · own scene* · tags: gothic, nobility, fantasy

**In-app copy:** *Ravens answer to her.* — A gothic queen in a feathered gown, crowned with raven feathers, with ravens perched on her outstretched arms.

**Raw prompt**

```
A gothic queen in a feathered black gown and a crown of raven feathers, ravens on her outstretched arms, dark lipstick, in a ruined cathedral with broken stained-glass windows, cold dawn light.
```

**Applied generation guidance:** Short tail only: ", realistic photo".

**Ready-to-use prompt** (209 chars)

```
A gothic queen in a feathered black gown and a crown of raven feathers, ravens on her outstretched arms, dark lipstick, in a ruined cathedral with broken stained-glass windows, cold dawn light, realistic photo
```

---

## Image to Image (20)

Use with a photo of a person. The identity-lock and natural-blending instructions are already inside the ready-to-use prompt.

### Vampire Noble  `halloween_vampire`
*Free · Popular · own scene* · tags: vampire, gothic, nobility

**In-app copy:** *Become the one the night waits for.* — A high-collared velvet coat, subtle fangs and a calm gaze. You, as an elegant vampire who never loses composure.

**Raw prompt**

```
the person as an elegant vampire in a high-collared black velvet coat with red silk lining, pale makeup, subtle fangs, hair swept back, in the candle-lit hall of an old gothic mansion, warm candlelight
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (316 chars)

```
Edit this photo: the person as an elegant vampire in a high-collared black velvet coat with red silk lining, pale makeup, subtle fangs, hair swept back, in the candle-lit hall of an old gothic mansion, warm candlelight. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Enchanted Witch  `halloween_witch`
*Free · Popular · own scene* · tags: witch, fantasy, moon

**In-app copy:** *Your own spell, your own hat.* — A wide-brimmed hat, silver-embroidered robes and a lantern's glow. You, as a witch who knows exactly what they're doing.

**Raw prompt**

```
the person as a witch in a wide-brimmed pointed hat and dark embroidered robes, holding a small glowing lantern, in a cozy witch's cottage with a bubbling cauldron and hanging herbs, warm firelight
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (312 chars)

```
Edit this photo: the person as a witch in a wide-brimmed pointed hat and dark embroidered robes, holding a small glowing lantern, in a cozy witch's cottage with a bubbling cauldron and hanging herbs, warm firelight. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Spectral Ghost  `halloween_ghost`
*Premium · own scene* · tags: ghosts, supernatural, gothic

**In-app copy:** *Soft glow, solid you.* — Flowing pale clothing, a faint mist at the hem and a quiet ethereal glow. Your face stays clear while the world turns spectral.

**Raw prompt**

```
the person as a gentle ghost in flowing pale clothing with a soft glow and faint mist around them, serene expression, in the hallway of an old Victorian house, soft moonlight through lace curtains
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (311 chars)

```
Edit this photo: the person as a gentle ghost in flowing pale clothing with a soft glow and faint mist around them, serene expression, in the hallway of an old Victorian house, soft moonlight through lace curtains. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Skeleton Makeup  `halloween_skeleton`
*Premium · Popular · own scene* · tags: skeletons, horror, vintage

**In-app copy:** *Bone structure, but make it art.* — Skeleton makeup that follows your own features, dark tailoring and a marigold behind the ear. Day of the Dead elegance.

**Raw prompt**

```
the person with elegant skeleton face paint in soft white and charcoal, dark clothing, a marigold behind the ear, in a candle-lit courtyard decorated for Día de Muertos, warm evening light
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (290 chars)

```
Edit this photo: the person with elegant skeleton face paint in soft white and charcoal, dark clothing, a marigold behind the ear, in a candle-lit courtyard decorated for Día de Muertos, warm evening light. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Werewolf  `halloween_werewolf`
*Premium · own scene* · tags: horror, supernatural, moon

**In-app copy:** *Just a hint of wolf.* — Light fur along the jaw, amber eyes and a torn flannel shirt. Subtle enough that you're still unmistakably you.

**Raw prompt**

```
the person as a subtle werewolf with light fur along the jaw, amber eyes, small fangs and a torn flannel shirt, at the edge of a misty pine forest at night under a full moon, cool moonlight
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (304 chars)

```
Edit this photo: the person as a subtle werewolf with light fur along the jaw, amber eyes, small fangs and a torn flannel shirt, at the edge of a misty pine forest at night under a full moon, cool moonlight. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Gothic Royalty  `halloween_royalty`
*Premium · own scene* · tags: nobility, gothic, fantasy

**In-app copy:** *Black velvet and a slim crown.* — Gothic royalty with a ruffled collar, jewels and a proud, calm pose, as if the castle was always yours.

**Raw prompt**

```
the person as gothic royalty in black velvet and lace with a high ruffled collar and a slim jeweled crown, seated in a gothic castle throne room with tall candelabras, warm candlelight
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (299 chars)

```
Edit this photo: the person as gothic royalty in black velvet and lace with a high ruffled collar and a slim jeweled crown, seated in a gothic castle throne room with tall candelabras, warm candlelight. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Retro Slasher Night  `halloween_retro_bedroom`
*Premium · Popular · own scene* · tags: retro, horror, vintage

**In-app copy:** *Pink sheets, corded phone, something at the door.* — You on a 90s sleepover bed with popcorn and movie posters, and a shadowy figure out of focus in the doorway.

**Raw prompt**

```
the person lounging on pink satin sheets in a retro 90s teen bedroom, holding a corded phone, movie posters on the wall, a tall shadowy figure out of focus in the doorway, warm lamp light
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (289 chars)

```
Edit this photo: the person lounging on pink satin sheets in a retro 90s teen bedroom, holding a corded phone, movie posters on the wall, a tall shadowy figure out of focus in the doorway, warm lamp light. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Haunted Mansion Portrait  `halloween_haunted_mansion`
*Premium · own scene* · tags: house, gothic, ghosts

**In-app copy:** *Candlelight on a very old staircase.* — You in Victorian mourning at the foot of a grand staircase, dusty chandeliers above and ghosts barely visible in the dark.

**Raw prompt**

```
the person in a Victorian mourning outfit standing at the foot of a grand staircase in a candle-lit mansion, dusty chandelier and cobwebs, faint ghostly figures in the shadows, soft warm candle light on the face
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (326 chars)

```
Edit this photo: the person in a Victorian mourning outfit standing at the foot of a grand staircase in a candle-lit mansion, dusty chandelier and cobwebs, faint ghostly figures in the shadows, soft warm candle light on the face. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Golden Pumpkin Patch  `halloween_pumpkin_patch`
*Free · Popular · own scene* · tags: pumpkin, party

**In-app copy:** *Golden hour, big sweater, endless pumpkins.* — A cozy autumn portrait among hay bales and drifting fog, with warm backlight glowing in your hair.

**Raw prompt**

```
the person in an oversized cozy knit sweater sitting among pumpkins in a golden-hour pumpkin patch, hay bales, light drifting fog, soft warm backlight in their hair
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (266 chars)

```
Edit this photo: the person in an oversized cozy knit sweater sitting among pumpkins in a golden-hour pumpkin patch, hay bales, light drifting fog, soft warm backlight in their hair. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Gothic Masquerade Ball  `halloween_gothic_ballroom`
*Premium · own scene* · tags: nobility, gothic, party

**In-app copy:** *The masquerade starts at midnight.* — Black velvet in a candlelit ballroom, crystal chandeliers overhead and dancers softly blurred behind you.

**Raw prompt**

```
the person in a black velvet masquerade outfit in a vast candle-lit gothic ballroom, crystal chandeliers, dancing couples softly blurred behind, holding an ornate mask at their side, soft golden candle glow
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (308 chars)

```
Edit this photo: the person in a black velvet masquerade outfit in a vast candle-lit gothic ballroom, crystal chandeliers, dancing couples softly blurred behind, holding an ornate mask at their side, soft golden candle glow. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Polaroid Costume Party  `halloween_polaroid_party`
*Free · own scene* · tags: retro, party, vintage

**In-app copy:** *Hard flash, soft nostalgia.* — An 80s costume party caught on instant film: sequins, tinsel, paper skeletons and a flash that blows out the background.

**Raw prompt**

```
the person at an 80s Halloween costume party in a sequined jacket and a witch hat, tinsel streamers and paper skeletons on the wall behind, a harsh on-camera flash, grainy instant-photo colors
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (294 chars)

```
Edit this photo: the person at an 80s Halloween costume party in a sequined jacket and a witch hat, tinsel streamers and paper skeletons on the wall behind, a harsh on-camera flash, grainy instant-photo colors. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Mirror Ghost Portrait  `halloween_mirror_ghost`
*Free · own scene* · tags: ghosts, gothic, vintage

**In-app copy:** *Your reflection knows something.* — Candlelight, lace and an antique mirror where your reflection looks back a little too calmly.

**Raw prompt**

```
the person in Victorian lace and a high collar standing before an antique mirror in candlelight, their reflection a faint pale ghost with a slight smile, sepia tones, dust motes in the air
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (303 chars)

```
Edit this photo: the person in Victorian lace and a high collar standing before an antique mirror in candlelight, their reflection a faint pale ghost with a slight smile, sepia tones, dust motes in the air. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Haunted Carnival  `halloween_haunted_carnival`
*Free · own scene* · tags: party, horror, retro

**In-app copy:** *The rides still run after closing.* — A neon ferris wheel through the fog, empty striped tents and flickering bulbs. A carnival that never quite closed.

**Raw prompt**

```
the person at a deserted carnival at night, a neon ferris wheel glowing through low fog behind them, striped tents and flickering bulbs, a vintage jacket, soft light on their face
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (281 chars)

```
Edit this photo: the person at a deserted carnival at night, a neon ferris wheel glowing through low fog behind them, striped tents and flickering bulbs, a vintage jacket, soft light on their face. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Apothecary Witch  `halloween_apothecary_witch`
*Premium · own scene* · tags: witch, cozy, fantasy

**In-app copy:** *Soup, but make it a spell.* — Dried herbs, a steaming cauldron and amber lamps. You as the witch who runs the coziest kitchen in the woods.

**Raw prompt**

```
the person as a cottage witch in an herb-filled apothecary kitchen, bundles of dried herbs hanging overhead, a cauldron steaming beside them, amber lamplight, a linen apron over dark robes
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (303 chars)

```
Edit this photo: the person as a cottage witch in an herb-filled apothecary kitchen, bundles of dried herbs hanging overhead, a cauldron steaming beside them, amber lamplight, a linen apron over dark robes. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Liminal Hallway  `halloween_liminal_hallway`
*Premium · own scene* · tags: liminal, horror, retro

**In-app copy:** *Somewhere between floors.* — An endless hallway of flickering lights and worn carpet. Unsettling in the quietest way, with you in a bat-wing cape.

**Raw prompt**

```
the person in a vintage bat-wing cape standing in an endless empty office hallway, flickering fluorescent lights, worn carpet, an uncanny quiet, slightly desaturated colors
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (274 chars)

```
Edit this photo: the person in a vintage bat-wing cape standing in an endless empty office hallway, flickering fluorescent lights, worn carpet, an uncanny quiet, slightly desaturated colors. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Harvest Scarecrow  `halloween_harvest_scarecrow`
*Premium · own scene* · tags: pumpkin, fantasy, kids

**In-app copy:** *Stuffed with straw, full of charm.* — A patched shirt, stitched cheeks and straw at the cuffs in a golden cornfield. A scarecrow you would wave back at.

**Raw prompt**

```
the person as a friendly scarecrow in a patched plaid shirt and straw hat, small stitched marks on the cheeks, straw tufts at the cuffs, a cornfield glowing at golden hour behind them
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (285 chars)

```
Edit this photo: the person as a friendly scarecrow in a patched plaid shirt and straw hat, small stitched marks on the cheeks, straw tufts at the cuffs, a cornfield glowing at golden hour behind them. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Fortune Teller  `halloween_fortune_teller`
*Premium · own scene* · tags: supernatural, fantasy, vintage

**In-app copy:** *Your future, by candlelight.* — Layered scarves, gold coins and a glowing crystal ball between your hands. The tent where every card means something.

**Raw prompt**

```
the person as a fortune teller in a velvet tent, layered scarves and gold coin jewelry, a glowing crystal ball between their hands, candles and tarot cards on a draped table, warm flickering light
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (298 chars)

```
Edit this photo: the person as a fortune teller in a velvet tent, layered scarves and gold coin jewelry, a glowing crystal ball between their hands, candles and tarot cards on a draped table, warm flickering light. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Moonlit Graveyard  `halloween_graveyard_moon`
*Premium · own scene* · tags: graveyard, moon, gothic

**In-app copy:** *A quiet walk, nothing to see here.* — Mossy gravestones, low mist and a lantern held low under a full moon. Calm, cold and just a little too quiet.

**Raw prompt**

```
the person in a long black coat standing among old mossy gravestones under a full moon, low mist around their ankles, a small lantern in hand, cool moonlight with a hint of warm glow
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (284 chars)

```
Edit this photo: the person in a long black coat standing among old mossy gravestones under a full moon, low mist around their ankles, a small lantern in hand, cool moonlight with a hint of warm glow. Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

### Cursed Library  `halloween_cursed_library`
*Premium · own scene* · tags: fantasy, gothic, supernatural

**In-app copy:** *Every book is whispering.* — A tall dusty library where the books hover, the pages drift and a black cat guards the desk.

**Raw prompt**

```
the person reading by candlelight in a tall dusty library, floating books and drifting pages around them, a dark academia sweater and scarf, a black cat on the desk, warm amber light
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (297 chars)

```
Edit this photo: the person reading by candlelight in a tall dusty library, floating books and drifting pages around them, a dark academia sweater and scarf, a black cat on the desk, warm amber light. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

### Cat Familiar  `halloween_cat_sorcerer`
*Premium · own scene* · tags: witch, moon, fantasy

**In-app copy:** *The cat chose you, not the other way.* — A velvet jacket, a silver moon brooch and a black cat on your shoulder. Quietly powerful, and the cat knows it.

**Raw prompt**

```
the person as a young sorcerer in a dark velvet jacket with a silver moon brooch, a black cat on their shoulder, in an old wizard's library with tall bookshelves and floating candles, warm light
```

**Applied generation guidance:** One face sentence: "Keep the same face, natural and unchanged, lit to match the scene."

**Ready-to-use prompt** (309 chars)

```
Edit this photo: the person as a young sorcerer in a dark velvet jacket with a silver moon brooch, a black cat on their shoulder, in an old wizard's library with tall bookshelves and floating candles, warm light. Keep the same face, natural and unchanged, lit to match the scene. Photorealistic fantasy scene.
```

