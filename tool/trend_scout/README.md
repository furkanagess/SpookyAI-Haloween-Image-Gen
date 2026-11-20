# Trend Scout

A developer robot for SpookyAI. Run it and it tells you which seasonal
visual ideas are rising right now and hands you ready-to-review prompt
candidates for the app's library — text-to-image and image-to-image — that
already passed the app's own content-safety gate.

It is **not** shipped in the app. It lives in `tool/trend_scout/` as a
standalone Dart CLI and only re-uses the app's `PromptModeration`.

```
collect ──► score ──► cluster ──► write prompts ──► safety ──► report
reddit      log-norm   n-grams     Claude (or        app          output/
youtube     recency    (+Claude)   templates)        moderation   <season>_<date>.json
g-trends    keywords                                 brand flags  <season>_<date>.md
seeds       dedupe
```

## Quick start

```bash
cd tool/trend_scout
flutter pub get                 # resolves the path dependency on the app
cp .env.example .env            # add keys (all optional)
dart run bin/trend_scout.dart --season christmas
open output/christmas_*.md
```

Useful flags:

| Flag | Meaning |
|---|---|
| `--season halloween` | pick a season; default is the season for today's date |
| `--days 7` | look-back window (default 14) |
| `--concepts 12` | max concepts (default 20) |
| `--text-per-concept 2 --image-per-concept 2` | candidates per concept (LLM mode) |
| `--source reddit --source seed` | restrict sources (default: all) |
| `--no-llm` | force offline mode (template prompts) |
| `--strict` | drop brand/real-person flagged candidates instead of warning |
| `--model`, `--effort` | Claude model (default `claude-opus-5-5`) and effort (`medium`) |

Exit code 2 = no signals at all (network down, bad keys, no seeds).

## Sources

| Source | Needs | Notes |
|---|---|---|
| Reddit | `REDDIT_CLIENT_ID` + `REDDIT_CLIENT_SECRET` | Official OAuth API with a free "script" app (anonymous `.json` listings return 403 nowadays). Season communities (`r/halloween`, `r/christmas`, …) are trusted; AI-art communities are searched with the season's queries and must pass the keyword filter. NSFW-tagged posts are never ingested. |
| YouTube | `YOUTUBE_API_KEY` | Official Data API v3; recent videos per query, ranked by views. Free quota is plenty for a weekly run. |
| Google Trends | nothing | Public "trending now" RSS (US + TR). Mostly news; the keyword filter drops almost all of it — kept because seasonal spikes show up there first. |
| Seeds | `seeds/<season>.txt` | Your own notes from TikTok / Pinterest / Instagram, which have no public developer API. Trusted and high-scoring. See `seeds/README.md`. |

TikTok and Pinterest are **deliberately not scraped**: their terms forbid it,
unofficial scrapers break weekly, and accounts/IPs get banned. Note concepts
you see there into the seed file instead — that is the honest bridge.

## Scoring

Every signal gets a 0–1 score: engagement log-normalized **per source**
(so 2M views and 900 upvotes can be compared) × recency (linear decay over
the window, floor 0.35) × relevance boost (+15 % per season keyword hit, max
3). Untrusted signals without a season keyword are dropped; near-duplicate
titles are merged.

## Concepts and prompts

- **Offline** (`--no-llm` or no key): concepts are frequent 2–3-word phrases
  across titles; prompts come from templates and are marked
  `origin: template` with a "rewrite before shipping" warning.
- **With Claude**: one structured-output call. Claude re-clusters the top 150
  signals into distinct visual concepts, explains *why* each is rising, and
  writes the candidates. The system prompt encodes the app's prompt
  architecture (see `PROMPT_ARCHITECTURE.md`): text prompts are **subject
  only** (the app adds scene/lighting/style), image prompts are
  transformation instructions **without** any face/identity wording (the app
  adds its identity-lock block). Refusals fall back server-side
  (`fallbacks: "default"`). Typical cost per run: a few cents.

## Safety

Every candidate runs through the app's `PromptModeration` — exactly the
gate users hit — so nothing the robot proposes can be blocked in the app.
A second pass flags likely trademarked characters / franchises / real
people (`CandidateFilter.brandWords`) for a generic rewrite; `--strict`
drops them. Short or over-long prompts get warnings. **A human still reviews
the Markdown before anything ships**; the robot proposes, it does not publish.

## Output

- `output/<season>_<date>.json` — full machine-readable report: stats,
  concepts with evidence, candidates (`id`, `title`, `mode`, `prompt`,
  `tags`, `concept`, `trend_score`, `origin`, `warnings`, `blocked_reason`),
  top signals.
- `output/<season>_<date>.md` — the review document: concept table, prompt
  candidates grouped by mode, blocked list, top signals with links.

Candidate `id`s are stable slugs (`christmas_image_snow_globe_portrait_3`),
so they can go straight into `PromptService` and the matching preview image
can be dropped into `assets/prompt_previews/<id>.jpg`. The output folder is
git-ignored.

## Adding a season / source

- **Season**: add a `SeasonSpec` in `lib/src/seasons.dart` (keywords,
  communities, queries, months) and a `seeds/<id>.txt`.
- **Source**: implement `TrendSource` in `lib/src/sources/` and register it
  in `bin/trend_scout.dart`. Throw `SourceException` on total failure;
  partial failures should return what you have.

## Tests

Run the package tests from `tool/trend_scout` with the Dart test runner.
They cover season selection, scoring/relevance/dedupe, concept extraction,
moderation + brand filtering, every parser (Reddit JSON, Google Trends RSS,
seed file) and an offline end-to-end pipeline run with a failing source.
No test touches the network.

## Scheduling

Run it weekly (cron / GitHub Actions) with the keys in secrets, and open the
Markdown as the agenda for the seasonal prompt review. Previews for approved
candidates are generated with the app's FLUX pipeline — a separate step so
no image credits are spent on prompts nobody approved.
