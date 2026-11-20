# app_preview — SpookyAI kod haritası

Yeni bir oturum, uygulamayı baştan gezmeden önce BURAYI okusun. Görevi
aşağıdaki tablodan bul, yalnızca ilgili dosyayı aç, gerekirse ayrıntı için
ilgili alt belgeye bak. (Son tarama: 2026-11-19, sürüm 2.0.0+20.)

Flutter uygulaması (Provider state), fal.ai ile görsel/video üretimi,
RevenueCat ile token satışı, Firebase (Analytics, Crashlytics, Firestore),
mevsimsel tema sistemi (Halloween, Christmas).

## Alt belgeler

| Belge | İçerik |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Klasör yapısı, açılış akışı, provider listesi, yerel depolama |
| [SCREENS.md](SCREENS.md) | Sekmeler, sayfalar, widget'lar: hangi ekran hangi dosyada |
| [GENERATION.md](GENERATION.md) | Prompt engine, moderasyon, fal çağrıları, üretim akışı |
| [MONETIZATION.md](MONETIZATION.md) | Token, satın alma, paywall, promo kod, deneme, puanlama ödülü |
| [SEASONS.md](SEASONS.md) | Mevsim/tema sistemi, ikonlar, sesler, efektler |
| [BACKEND_AND_TOOLING.md](BACKEND_AND_TOOLING.md) | Firebase, fal proxy, web sitesi, release, testler, dokümanlar |

## Görev → nereye bakılır

| Görev | Önce aç |
|---|---|
| Yeni stil/prompt ekle (Halloween) | `lib/features/home/data/services/prompt_service.dart` + `PROMPT_ARCHITECTURE.md` §3b |
| Yeni stil ekle (Christmas) | `lib/features/home/data/services/christmas_prompts.dart` |
| Stil önizleme görseli | `lib/core/config/prompt_preview_assets.dart`, `assets/prompt_previews/` |
| Prompt'un fal'a giden son hali | `lib/core/prompt_engine/prompt_engine.dart` |
| Yasaklı kelime / moderasyon | `lib/core/prompt_engine/prompt_moderation.dart` |
| Hata/uyarı metinleri (prompt sorunu) | `lib/core/prompt_engine/prompt_issue.dart`, `prompt_issue_sheet.dart` |
| Sahne/ortam kitleri | `lib/core/prompt_engine/scene_kits.dart` |
| fal modeli, kalite, video süresi | `lib/core/services/fal_ai_service.dart` (üstteki sabitler) |
| API anahtarı / proxy / endpoint | `lib/core/config/environment_config.dart`, `SECURITY.md` |
| Generate sekmesi UI / üretim butonu | `lib/features/home/presentation/pages/main_navigation_page_refactored.dart` (`_buildGenerateTab` ~1096, `_generateFalAiNewFlow` ~516) |
| Mod seçici (text/image/video) | `widgets/generation_mode_switcher.dart`, `domain/generation_mode.dart` |
| Üretim bekleme ekranı | `widgets/generation_progress_dialog.dart` |
| Sonuç ekranı (görsel / video) | `pages/generated_result_page.dart`, `pages/video_result_page.dart` |
| Görseli düzenle (image→image) | `widgets/image_edit_flow.dart` |
| Görselden video | `widgets/image_to_video_flow.dart` |
| Prompts sekmesi / kütüphane | `pages/prompts_page.dart`, `widgets/prompt_detail_sheet.dart` |
| Kullanıcının kendi prompt'ları | `data/services/user_prompt_service.dart`, `widgets/add_prompt_dialog.dart` |
| Trend sekmesi (uzaktan içerik) | `pages/trend_page.dart`, `lib/core/services/trend_service.dart`, `docs/TRENDS.md` |
| Galeri (Photos / Videos) | `pages/photos_page.dart`, `pages/videos_page.dart`, `saved_images_provider.dart`, `saved_videos_provider.dart` |
| Profil sayfası | `pages/profile_page.dart`, `profile_provider.dart`, `avatar_service.dart` |
| Alt navigasyon barı | `widgets/app_bottom_nav.dart` |
| Token fiyatları (DEĞİŞTİRME, sahibin kararı) | `lib/core/services/token_costs.dart` |
| Token bakiyesi | `lib/core/services/token_service.dart`, `token_provider.dart` |
| Paket satın alma sayfası | `pages/purchase_page.dart`, `purchase_provider.dart`, `in_app_purchase_service.dart` |
| Paywall (onboarding sonrası) | `widgets/paywall_dialog.dart` |
| Promo / redeem kodu | `lib/core/services/promo_code_service.dart`, `firestore.rules` |
| Günlük giriş ödülü / streak | `lib/core/services/daily_login_service.dart` |
| Puanlama (yıldız) ve ödül | `rating_service.dart`, `widgets/result_rating_card.dart` |
| İçerik şikayet | `content_reporting_service.dart`, `pages/content_report_detail_page.dart` |
| Onboarding | `lib/features/onboarding/presentation/pages/onboarding_page.dart`, `widgets/onboarding_visuals.dart` |
| Ürün turu (coach marks) | `lib/features/tour/product_tour.dart` |
| Splash | `pages/splash_page.dart`, `theme/seasons/season_splash_stage.dart` |
| Mevsim ekle / renk / efekt | `lib/core/theme/seasons/` + `docs/SEASONS.md` §5 |
| Dünya haritası (sezon haritası) | `pages/season_map_page.dart` (2300 satır, sadece gerekli bölümü oku), `widgets/world_map_button.dart` |
| Uygulama ikonu değiştirme | `app_icon_service.dart`, `pages/app_icon_page.dart` |
| Ortam sesi | `ambient_sound_service.dart`, `assets/sounds/` |
| Toast / bildirim | `lib/core/services/notification_service.dart` |
| Analitik event'leri | `lib/core/services/analytics_service.dart` |
| Uygulama başlatma, provider kaydı | `lib/main.dart` |
| Ana tema / ölçüler | `lib/core/theme/app_theme.dart`, `app_metrics.dart` |
| Release build | `tool/build_release.sh` |
| fal proxy (Cloudflare Worker) | `tool/fal_proxy/worker.mjs` |
| Tanıtım web sitesi | `website/` (Firebase Hosting) |
| Açık işler listesi | `YAPILACAKLAR.md` |
| Büyüme / pazarlama planı | `docs/BUYUME_YOL_HARITASI.md`, `docs/marketing/` |

`pages/` ve `widgets/` = `lib/features/home/presentation/...`;
servisler = `lib/core/services/...`.

## Ölü / kullanılmayan dosyalar (dokunma, okuma)

Hiçbir yerden import edilmiyor:
`prompt_service_backup.dart`, `prompt_service_organized.dart`,
`prompt_service_updated.dart`, `widgets/halloween_prompt_selector.dart`,
`lib/core/utils/prompt_builder.dart` (eski facade).
`test/prompt_builder_test.dart` ve `test/widget_test.dart` boş dosyalar.
`build/`, `build 2/` derleme çıktısı.

## Bu belgeleri güncel tut

Bir görevde yeni dosya/özellik eklediysen veya bir dosyanın rolü değiştiyse,
ilgili tabloya tek satır ekle. Uzun açıklama yazma.
