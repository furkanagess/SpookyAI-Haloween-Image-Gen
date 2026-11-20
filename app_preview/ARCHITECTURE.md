# Mimari

## Klasörler

```
lib/
  main.dart                 Firebase init, IAP init, quick actions, MultiProvider, home: SplashPage
  firebase_options.dart     FlutterFire üretimi
  core/
    config/                 environment_config (secret/endpoint), prompt_preview_assets
    models/                 generated_image, halloween_prompt_data, onboarding_data
    prompt_engine/          moderasyon + prompt kurma + sorun ekranları (bkz GENERATION.md)
    services/               tüm servis ve provider'lar (iş mantığı burada)
    theme/                  app_theme, app_metrics, seasons/ (bkz SEASONS.md)
    utils/                  platform_utils (prompt_builder ölü)
    widgets/                app_bar_title, token_display_widget
  features/
    home/
      data/models/          prompt_category (PromptItem), user_prompt
      data/services/        prompt_service (Halloween kütüphanesi), christmas_prompts, user_prompt_service
      domain/               GenerationMode {text, image, video}, generated_image_result
      presentation/pages/   tüm ekranlar (bkz SCREENS.md)
      presentation/widgets/ sheet, dialog, kartlar
    onboarding/             onboarding_page + onboarding_visuals
    tour/                   product_tour (ilk kullanım turu)
test/                       birim/widget testleri (bkz BACKEND_AND_TOOLING.md)
integration_test/           v33_biscuit_test (pazarlama videosu çekimi)
tool/                       build_release.sh, fal_proxy/, seed_trends.cjs, trend_scout/
website/                    statik tanıtım sitesi (Firebase Hosting)
docs/                       prompt kütüphanesi, sezonlar, trendler, büyüme, pazarlama
assets/                     icons, images, lottie, prompt_previews, sounds, ss, example.mp4
```

## Açılış akışı

`main()` → Firebase.initializeApp (başarısız olursa devam) → AnalyticsService →
`InAppPurchaseService.initialize()` → `QuickActionsService.initialize()` →
`runApp(GhostfaceApp)` → `SplashPage` → (ilk kez) `OnboardingPage` →
`MainNavigationPageRefactored` (onboarding'den gelince paywall gösterir).

## Provider'lar (lib/main.dart ~72-92)

| Provider | Sorumluluk |
|---|---|
| `SeasonProvider` | Aktif sezon (otomatik takvim veya kullanıcı sabitlemesi) |
| `SavedImagesProvider` | Kaydedilmiş görseller (galeri) |
| `SavedVideosProvider` | Kaydedilmiş videolar (yalnızca dosya adı tutar) |
| `TokenProvider` | Bakiye UI state'i (`TokenService` üzerinde) |
| `MainNavigationProvider` | Sekme index'i, mod, prompt, yüklenen görsel, seçili stil, premium banner |
| `ProfileProvider` | Profil verisi |
| `PromptsProvider` | Hazır prompt kullanım limitleri (free kullanıcı) |
| `PurchaseProvider` | Ürün listesi, satın alma state'i |
| `AddPromptProvider`, `HalloweenPromptProvider`, `PromptInputProvider` | Prompt ekleme / giriş alanı state'i |

## Yerel depolama

- Token bakiyesi: `SharedPreferences` + `FlutterSecureStorage` (`token_service.dart`, anahtarlar `_v2`).
- Puanlama geçmişi: keychain/secure storage (`rating_service.dart`).
- Görseller: `image_storage_service.dart` (iOS'ta klasör yolu her çağrıda çözülür; mutlak yol saklama).
- Seçili stiller: `MainNavigationProvider._persistStyles` (sezona bağlı).

## Platform farkları

`ios_purchase_service.dart` / `android_purchase_service.dart`,
`lib/core/utils/platform_utils.dart`. Native kod: `ios/`, `android/`.
