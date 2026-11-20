# Backend, araçlar, testler, dokümanlar

## Firebase (proje `spookyai-app-ratings`)
- Init: `lib/main.dart`, `lib/firebase_options.dart`; ayar `firebase.json`
- Analytics + Crashlytics: `lib/core/services/analytics_service.dart` (Firebase yoksa no-op)
- Firestore koleksiyonları: `promo_codes` (+ `redemptions`), `ratings`,
  `trend_config/screen`, `trend_sections`
- Kurallar: `firestore.rules`, `storage.rules`
- Trend içeriği seed: `tool/seed_trends.cjs`, örnekler `docs/trend_*.sample.json`, rehber `docs/TRENDS.md`, `tool/trend_scout/`

## fal proxy (Cloudflare Worker)
- `tool/fal_proxy/worker.mjs`, `wrangler.toml`; deneme hakkı `/trial/claim` de burada
- Test: `cd tool/fal_proxy && node --test worker.test.mjs`
- Uygulama tarafı: `environment_config.dart` (`FAL_PROXY_URL`, `FAL_PROXY_TOKEN`, `FAL_AI_API_KEY`) — `SECURITY.md`

## Secret'lar
`.env` (debug, `--dart-define-from-file=.env`), şablon `env.example`.
Kaynakta/asset'te secret yasak (`environment_config_test` zorlar).

## Release
`tool/build_release.sh android|ios|all` (çıplak `flutter build` kullanma).
Sürüm: `pubspec.yaml` `version:`; `version_service.dart`.

## Web sitesi
`website/` → `public/` (index, privacy, terms, tr/, get/), `build.mjs`,
`tools/` (QR, asset optimize), `redirect/`. Firebase Hosting site `spookyai-app`.

## Testler (`test/`)
Komut: `flutter test test/<dosya>_test.dart`. Analiz: `dart analyze lib test`.
Gruplar: prompt (`prompt_*`, `scene_kits`, `hidden_styles`, `style_copy`,
`christmas_library`), fal (`fal_*`, `video_mode`), para (`token_*`,
`promo_code_service`, `paywall_page`, `rating_reward_policy`), sezon
(`season_*`, `color_contrast`, `app_icon_service`, `ambient_sound_service`),
UI (`onboarding_page`, `product_tour`, `favorites`), diğer
(`environment_config`, `trend_service`). Boş: `prompt_builder_test`, `widget_test`.
`integration_test/v33_biscuit_test.dart`: pazarlama videosu senaryosu.

## Dokümanlar (kök + docs/)
| Dosya | Konu |
|---|---|
| `PROMPT_ARCHITECTURE.md` | Prompt hattı kuralları |
| `CONTENT_MODERATION_GUIDELINES.md` | Moderasyon politikası |
| `SECURITY.md` | Anahtar/proxy düzeni |
| `UI_UX_REVIEW.md` | UI/UX inceleme notları |
| `USER_RETENTION_FEATURES.md` | Elde tutma özellikleri |
| `PRIVACY_POLICY.md`, `TERMS_OF_USE.md` | Yasal |
| `YAPILACAKLAR.md` | Açık işler (güncel durum burada) |
| `docs/SEASONS.md`, `SEASON_CALENDAR.md` | Sezonlar |
| `docs/TRENDS.md` | Trend sekmesi |
| `docs/PROMPT_LIBRARY.md`, `CHRISTMAS_PROMPT_LIBRARY.md` | Üretilmiş stil listeleri |
| `docs/APP_ICON_PROMPTS.md` | İkon üretim prompt'ları |
| `docs/BUYUME_YOL_HARITASI.md` | Büyüme planı |
| `docs/marketing/` | Sosyal medya, içerik takvimi, video planları |
| `store_screenshots/` | Mağaza görselleri |
