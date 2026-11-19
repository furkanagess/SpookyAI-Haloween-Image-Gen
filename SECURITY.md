# Secrets and fal.ai access

## The rule

**No secret lives in the source code or in the app bundle.** Anything compiled
into a mobile app can be extracted, so the real fal key is only ever on a
server (the proxy in `tool/fal_proxy`) or, for local development, passed at
run time.

`test/environment_config_test.dart` fails the build if a fal key pattern
appears in `lib/`, `test/` or `tool/`, or if `.env` is bundled as an asset
again.

## How the app finds fal (`lib/core/config/environment_config.dart`)

| Mode | Use for | Configure with |
|---|---|---|
| **Proxy** | release builds, TestFlight, Play tracks | `--dart-define=FAL_PROXY_URL=https://…` and `--dart-define=FAL_PROXY_TOKEN=…` |
| **Direct key** | your own machine only | `--dart-define=FAL_AI_API_KEY=…` |

```bash
# development
flutter run --dart-define=FAL_AI_API_KEY=<your dev key>

# release
# .env.production (git-ignored): FAL_PROXY_URL, FAL_PROXY_TOKEN,
# REVENUECAT_IOS_KEY, REVENUECAT_ANDROID_KEY — never FAL_AI_API_KEY
tool/build_release.sh android   # or: ios | all
```

Never build a release with `FAL_AI_API_KEY` set. A `.env` file is still read
if present (development convenience) but is **not** bundled into builds.
Development values live in a git-ignored `.env` (VS Code launch passes it via
`--dart-define-from-file=.env`). Release builds go only through
`tool/build_release.sh`, which reads `.env.production` and refuses to build if
`FAL_AI_API_KEY` is set or a required key is missing.

## One-time clean-up for the key that used to be in the code

The old key was committed to git (history) and shipped inside every build, so
treat it as public:

1. In the fal dashboard, **revoke it** and create a new key. Deleting it from
   the code is not enough; the history and old app builds still contain it.
2. Set a **spend limit** on the new key/account in the fal dashboard.
3. Deploy the proxy (below) with the new key as a secret.
4. Ship an app version that points at the proxy. Old installed versions stop
   working once the old key is revoked; that is intended.
5. Optional: rewrite git history with `git filter-repo` to drop the old key.
   Only worth it if the repository is or becomes public; revocation already
   makes the old key useless.

## The proxy (`tool/fal_proxy`)

A ~100-line Cloudflare Worker (also runs on Node 20+). It adds the key
server-side and enforces cost guards even if a client is modified: one image
per request, web search off, resolution capped at 2K (4K doubles the price),
oversized bodies rejected, only the two models the app uses are reachable.

```bash
cd tool/fal_proxy
node --test worker.test.mjs                 # 9 tests, no network
npx wrangler deploy
npx wrangler secret put FAL_KEY             # the NEW fal key
npx wrangler secret put APP_TOKEN           # long random string
```

Kill switch: set the `DISABLED` variable to `1` (dashboard or
`wrangler deploy --var DISABLED:1`); all calls return 503 immediately.

### Honest limits

- `FAL_PROXY_TOKEN` is compiled into the app, so it can be extracted too. It
  stops casual scraping, not a determined attacker. The proxy's value is that
  the **fal key and the cost guards are out of the client's hands**, you can
  rotate the token or flip the kill switch in seconds, and Cloudflare rate
  limits can be added per IP.
- The proxy does not know who the user is. The token balance still lives on
  the device (`SharedPreferences`), so a user can edit it, and reinstalling on
  Android restores the 3 free tokens. Real protection needs accounts or
  App Attest / Play Integrity plus a server-side token ledger. That is the
  next step before running an expensive model at scale.
- Set fal's spend limit regardless of everything above.
