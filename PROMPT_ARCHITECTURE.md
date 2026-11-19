# SpookyAI Prompt Architecture

This document describes how user input becomes an API-ready image prompt, how
face identity is preserved in image-to-image, and how disallowed content is
blocked. The implementation lives in `lib/core/prompt_engine/`.

## Pipeline overview

```
user text (≤500 chars, from Generate screen or the prompt library)
   │
   ▼
1. MODERATION  PromptEngine.moderate()            prompt_moderation.dart
   │  blocked → BlockedPromptDialog, no tokens spent, no API call
   ▼
2. SANITIZE    (inside the builders)              prompt_engine.dart
   │  trim/normalize whitespace, strip control chars,
   │  remove prompt-injection phrases, cap at 500 chars on a word boundary
   ▼
3. BUILD       PromptEngine.textToImage()  /  PromptEngine.imageToImage()
   │  mode-specific template + season context + negative prompt
   ▼
4. SEND        FalAiService.generateImage(rawPrompt: true)
               FalAiService.generateImageFromImage(rawPrompt: true,
                                                   negativePrompt: ...)
```

Key rule: **the engine's output is final.** `rawPrompt: true` tells
`FalAiService` to skip its legacy keyword enhancement, so the prompt is never
enhanced twice or truncated mid-word downstream. Server-side
`enable_safety_checker: true` stays on as the second safety layer.

## Modules

| File | Responsibility |
|---|---|
| `prompt_engine.dart` | Sanitization, mode templates, negative prompts, length budget, tuning constants |
| `prompt_moderation.dart` | Category blocklists, normalization, `ModerationResult` with user-facing messages |
| `blocked_prompt_dialog.dart` | Dialog shown when a prompt is rejected |
| `core/utils/prompt_builder.dart` | **Deprecated** facade delegating to `PromptEngine` (kept for old call sites) |

Call sites: `_generateImage()` and `_generateFalAiNewFlow()` in
`main_navigation_page_refactored.dart` run the moderation gate first, then
build and send.

## 1. Content moderation

Client-side gate, evaluated **before any token is charged**. Matching runs on
a normalized copy of the prompt — lowercased, Turkish letters ASCII-folded
(`ç→c`, `ş→s`, …), basic leetspeak undone (`3→e`, `@→a`, …), and once more
with in-word separators removed so `s.e.x` or `n-u-d-e` still match. All
matches are word-boundary based, so *assassin* or *class* never trips a list.

Categories (English + Turkish terms):

| Category | Examples blocked | Deliberately allowed |
|---|---|---|
| `sexual` | nude, porn, erotic, çıplak, seks… | — |
| `minors` | CSAM terms outright; any sexual term co-occurring with child/teen/çocuk… | — |
| `violence` | murder, beheading, torture, massacre, school shooting, cinayet, katliam… | blood, gore-free spooky staples: zombie, vampire, skull, "killer clown" |
| `selfHarm` | suicide, self-harm, kill myself, intihar… | "hanging decorations" (only "hang myself" is blocked) |
| `hate` | nazi, swastika, ethnic cleansing… | — |

Each rejection carries a short, friendly, category-specific message
(`ModerationResult.message`); the self-harm one includes a help-seeking note.
The genre vocabulary of a Halloween app (ghost, scary, haunted, blood…) is
intentionally **not** blocked — the lists target realistic harm, not spooky
fiction. To extend a category, add the word to the list in
`prompt_moderation.dart` and a case to `test/prompt_engine_test.dart`.

## 2. Sanitization

- Control characters removed; whitespace collapsed; surrounding quotes and
  leading punctuation stripped.
- Prompt-injection phrases removed (`ignore previous instructions`,
  `system prompt`, `jailbreak`, `you are now`, …) — these try to steer the
  model instead of describing an image.
- Input capped at 500 chars **on a word boundary** (matches the UI limit).

## 3. Prompt building

**Rule: short and descriptive.** A prompt holds only what the picture needs
(subject, place, light, "realistic photo"), like
*"Casual smartphone selfie of a 25-year-old woman with long brown hair,
natural indoor light, plain apartment background, realistic phone camera
photo"*. Earlier versions appended long rule blocks (named facial features,
"Avoid: …" lists, blending and proportion instructions, "top priority"
reminders). They crowded out the subject, so they were removed.

### Text-to-image — GPT Image 2 (`openai/gpt-image-2`)

```
<subject>, set in <setting>, lit by <lighting>, with <effect>, realistic photo
<subject>, realistic photo                      (subject names its own place)
```

- `<subject>` is the sanitized text, always first and verbatim (with a style:
  `<style prompt>, <user's extra details>`).
- `<setting>/<lighting>/<effect>` come from `SceneKits` (section 3a). If the
  library entry `ownsScene` or the user names a place, no scene is added.
- Empty input falls back to a seasonal default subject via `SeasonPalette.t`.

### Image-to-image — GPT Image 2 edit (`openai/gpt-image-2/edit`)

```
Edit this photo: <subject>[, set in <setting>, lit by <lighting>].
Keep the same face, natural and unchanged, lit to match the scene. Realistic photo.
```

The single face sentence (`PromptEngine.faceLock`) carries the whole
identity rule: the face stays the person's own and looks natural in the new
light. Library prompts must not repeat identity wording (enforced by test),
and inline legacy phrases ("keep exact same face", …) are stripped. Library
prompts keep the face open (no masks, pumpkin heads, full-face fur).

### Photo edit (`PromptEngine.editImage`)

```
<instruction>. Keep everything else the same, including the person's face.
```

No scene or style is added to an edit.

### Image-to-video (`FalAiService.buildVideoPrompt`)

```
<motion>. Keep the face natural and unchanged.
Subtle, natural motion. Keep the face natural and unchanged.   (no motion typed)
```

`prompt_expansion_mode` is `disabled`, so the model does not rewrite it.

Neither image model takes a negative prompt. `BuiltPrompt.negativePrompt` is
still built for models that accept one; it is not sent with the current
models.

### Length budget

Built prompts are usually 150–320 characters. `PromptEngine.maxPromptLength`
(2000) is a safety cap: only the subject is ever trimmed (at a word
boundary); the face sentence is never cut.

## 3-0. Styles: library prompts are never shown to users

The app treats a library entry as a **style**. The user sees only its title,
preview image and a few tag words (Prompts tab, style card on Generate); the
prompt text stays inside the app.

Flow:

1. **Prompts tab** → pick a style → *Use this style* (premium lock still
   applies) → `MainNavigationProvider.setStyle(item)` and back to **Generate**.
   Picking a style also switches the mode (photo style → Image to Image, text
   idea → Text to Image) and starts with empty extra details.
2. **Generate** shows a *style card* (thumbnail, title, Change / remove). The
   text box becomes **"Add details (optional)"**: whatever the user types is
   appended to the hidden prompt (`PromptEngine._compose`:
   `<style prompt>, <extra details>`). Without a style the text box is the full
   custom prompt, exactly as before. *Surprise me* picks a random unlocked
   style (the card appears; no text is revealed).
3. The engine receives the style object (`style:` parameter), so tags and
   `ownsScene` come from the entry itself and survive added details.
4. **Validation**: with a style, an empty text box is valid (a style is a
   complete prompt); extra details are still length/letters/moderation
   checked (`PromptValidator.validate(…, hasStyle: true)`).
5. **What gets stored and shown** (confirmation dialog, result dialog, gallery,
   share text): `MainNavigationProvider.promptLabel` — the style title for
   styles, the user's own text otherwise. Share text no longer includes a
   prompt at all ("Created with SpookyAI").
6. Prompts search matches **titles and tags only**; the detail sheet has no
   prompt text and no copy button.

`test/hidden_styles_test.dart` guards this, including a source scan that fails
if a screen reads `style.prompt` / `item.prompt` or offers copy/select-text.

Note: hiding the text in the UI is not secrecy. The prompts ship inside the
app binary and anyone willing to decompile it can read them. If the prompts are
a competitive asset, serve them from a server (the same proxy) instead.

## 3a. Scene kits (`scene_kits.dart`)

The environment part of a prompt is no longer three independent random
strings. A **`SceneKit`** is a coherent triple authored together — *setting*
(starts with "a/an", ≤85 chars), *lighting* (≤65), *effect* (≤60) — plus the
concepts it suits (`tags`) and a `faceFriendly` flag.

- **Per season**: Halloween 9 kits, Christmas 7. A new season is a new list in
  `SceneKits.forSeason` (plus a `SeasonId`); the engine needs no change.
- **Prompt-aware picking**: tags come from the library entry (exact text
  match) plus keywords found in the text itself (`SceneKits.tagsFromText`, so
  user-typed prompts work too). Kits are drawn at random **weighted by overlap²**:
  a ghost bride lands in a graveyard/mansion/crypt, a pumpkin scarecrow in a
  pumpkin field or autumn path — never in an unrelated crypt — yet the same
  prompt still varies between generations. With no overlap the pick is uniform.
- **Image-to-image uses `faceFriendly` kits only**: saturated colored light
  (e.g. the neon carnival) tints skin and breaks the likeness. Text-to-image
  may use them.
- **No artifact words**: kits never ask for "AI", glitch, pixel or digital
  effects (the old effect list did, which hurt photorealism). Enforced by test.
- Wording: `…, set in <setting>, lit by <lighting>, with <effect>` (t2i) and
  `…, set in <setting>, lit by <lighting>` (i2i). Prompts flagged `ownsScene` skip the kit's setting/lighting.
- Deterministic tests: `SceneKits.random` can be seeded.

> **Ready-to-use prompts for the whole library** (raw prompt + the architecture-
> wrapped prompt the app sends, per prompt) live in
> [`docs/PROMPT_LIBRARY.md`](docs/PROMPT_LIBRARY.md). It is generated from the
> code by `test/prompt_docs_test.dart`, and that test fails when the file is
> stale, so the docs cannot drift from the app.

## 3b. Prompt library (`PromptService`) authoring rules

The shipped Halloween library is **10 text-to-image + 10 image-to-image**
prompts (`PromptItem`). Rules, enforced by `test/prompt_library_test.dart`:

| Rule | Text-to-image | Image-to-image |
|---|---|---|
| Shape | A subject: who/what, wardrobe, props, pose, mood | Starts with `the person as/in …`; costume, makeup, hair, props, expression |
| Never | Quality tags (4k, masterpiece…), negative prompts, the word *transform* | Identity wording (*same person, preserve face…* — the engine owns it) |
| Length | 120–340 chars; keep to essentials (~150–210) | same |
| Scene | Characters/objects with **no** place named, so the engine's random setting fits any of them | Costume-only prompts get the engine's random setting; **scene-bound looks** (retro bedroom, polaroid party, carnival…) describe their own place and light |
| Safety | Must pass `PromptEngine.moderate` | same |

- **`ownsScene: true`** marks a prompt that already describes its environment
  and lighting. `PromptEngine` finds it via `PromptService.findByPrompt` and
  **skips the random setting/lighting** so the two never contradict
  (e.g. "retro 90s bedroom" + "pumpkin field"). If the user edits the text,
  the match fails and the random scene is used again. Mix: 6 of 10 image
  prompts are costume-only (variety from random scenes), 4 are scene-bound
  (tuned looks). Text prompts: 1 scene-bound, the rest characters.
- **`isPremium`** is an explicit flag (it used to be derived from a hash of
  the title, which made the free/premium split accidental). Current split:
  text 6 free / 4 premium, image 6 free / 4 premium, so a free user always
  has a full first screen.
- **`isPopular`**: ~25 % per mode, sorted first in the UI.
- **Ids** are stable, lowercase snake_case and double as preview filenames
  (`assets/prompt_previews/<id>.jpg`). Ids carried over from the old library
  (`halloween_vampire`, `halloween_witch`, …) keep users' favorites.
- Titles are unique across the library.

## 4. Generation parameters

| Parameter | Value | Why |
|---|---|---|
| t2i request | `aspect_ratio` 1:1, `resolution` 1K, `output_format` jpeg, `safety_tolerance` 3, `enable_web_search` false, `num_images` 1 | Cost guards: 4K doubles the ~$0.15 price and web search adds $0.015, so the app never sends either |
| i2i request | `image_urls` [photo as data URI], `image_size` portrait_4_3, `quality` high, `output_format` jpeg (compression 90), `background` opaque, `num_images` 1, safety checker on | fal list price per image at 1024×1024: low $0.015, medium $0.061, **high $0.219**; the fixed 768×1024 size keeps the price predictable. `quality` is the big cost lever: medium is ~3.6× cheaper. The old `strength` knob does not exist on this model, so likeness now rests entirely on the prompt wording. |
| i2i strength | not available | The previous editor exposed a denoise strength (we used 0.55 for likeness); GPT Image 2 edit has none, so likeness rests on the identity wording in the prompt and on `quality: high`. |
| Server-side safety | i2i `enable_safety_checker: true`; t2i `enable_safety_checker: true`; both: medium quality, `square` (512x512) preset, enforced again by the proxy | Second safety layer. An empty `images` list from GPT Image 2 means the model declined; the app shows the "didn't pass our safety check" sheet |
| i2i `negative_prompt` | sent from the engine | Endpoint accepts it; t2i (GPT Image 2) has no negative-prompt input either, so quality/constraint terms ride in the positive prompt (the t2i negative list in the engine is documentation only) |

## Testing

`test/prompt_engine_test.dart` (25 tests) and `test/prompt_library_test.dart` (24 checks over the whole library) cover: every moderation category
incl. Turkish terms and separator evasion, allowed genre vocabulary,
subject-first t2i structure, seasonal templating, injection stripping,
identity + integration clauses, legacy boilerplate dedupe, and the length
budget. Run with the Dart MCP test tool or `flutter test`. `test/fal_text_to_image_test.dart` covers the Nano Banana Pro request body and the queue flow (submit, poll, fetch result, safety decline, HTTP errors, cancellation) against a mock HTTP client.

## Extending

- **New season**: see the checklist in [docs/SEASONS.md](docs/SEASONS.md)
  (registry, prompt library, scene kits, legacy lists, map). No engine change
  needed, and the compiler flags the places that must be filled in.
- **New blocked term**: `prompt_moderation.dart` list + a test case.
- **Model swap**: keep the pipeline, revisit the template comments at the top
  of `prompt_engine.dart` (prompt style is model-specific) and the i2i
  strength constant.
- **Known limits**: moderation is wordlist-based — it blocks the listed
  categories robustly but is not a semantic classifier; the server-side
  checker remains the backstop. The old `FluxSchnellStyle`/`Quality` keyword
  enhancer still exists for legacy callers but is bypassed on every current
  call site.
