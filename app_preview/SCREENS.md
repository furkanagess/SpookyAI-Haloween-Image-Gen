# Ekranlar

Kök: `lib/features/home/presentation/`. Büyük dosyalarda yalnızca ilgili
satır aralığını oku (`grep -n` ile metodu bul).

## Ana sekmeler (`pages/main_navigation_page_refactored.dart`, IndexedStack)

| # | Etiket | Widget | Dosya |
|---|---|---|---|
| 0 | Generate | `_buildGenerateTab` (~1096) | aynı dosya |
| 1 | Prompts | `PromptsPage` | `pages/prompts_page.dart` |
| 2 | Trend (etiket uzaktan) | `TrendPage` | `pages/trend_page.dart` |
| 3 | Photos | `PhotosPage` (+ videolar) | `pages/photos_page.dart`, `pages/videos_page.dart` |
| 4 | Profile | `ProfilePage` | `pages/profile_page.dart` |

Alt bar: `widgets/app_bottom_nav.dart` (öne çıkan "fire" sekmesi `_FeaturedTile`).
Sekme başlığı: `lib/core/widgets/app_bar_title.dart`.

### main_navigation_page_refactored.dart önemli metodlar
- `initState` ~100, `_startTour` ~157 (ürün turu)
- `_surpriseStyle` ~300, `_preflight` ~312 (bakiye/girdi kontrolü)
- `_showFailure` ~332, onay sheet'leri ~341-382
- `_generateImage` ~383, `_generateFalAiNewFlow` ~516 (asıl üretim)
- `_persistGeneratedImage` ~816, `_shareGeneratedImage` ~863
- `build` ~894, `_buildPremiumBanner` ~994, `_tryVideoExample` ~1076
- `_buildCompactModeSelector` ~1341

## Generate sekmesi widget'ları
`generation_mode_switcher.dart` (segment), `generation_mode_card.dart`,
`prompt_input_widget.dart` ("Surprise me"), `idea_chips.dart`,
`style_picker_card.dart` (seçili stil), `image_upload_widget.dart`,
`image_selection_dialog.dart`, `generate_action_bar.dart` (sticky alt bar),
`generate_confirm_sheet.dart`, `generate_help_sheet.dart` ("How it works"),
`generation_progress_dialog.dart`, `video_showcase_card.dart` (video örnekleri),
`inspiration_card.dart`, `ghostface_trend_toggle.dart`, `low_balance_dialog.dart`.

## Diğer sayfalar
| Sayfa | Dosya |
|---|---|
| Splash | `pages/splash_page.dart` |
| Onboarding | `lib/features/onboarding/presentation/pages/onboarding_page.dart` (görseller `widgets/onboarding_visuals.dart`, 1850 satır) |
| Sonuç (görsel) | `pages/generated_result_page.dart` (+ `widgets/result_rating_card.dart`, `widgets/image_edit_flow.dart`, `widgets/image_to_video_flow.dart`) |
| Sonuç (video) | `pages/video_result_page.dart` |
| Satın alma | `pages/purchase_page.dart` (1500 satır; paketler 150/60/25/10) |
| Paywall | `widgets/paywall_dialog.dart` |
| Satın alma sonucu | `widgets/purchase_success_dialog.dart`, `widgets/purchase_failed_dialog.dart`, `widgets/subscription_info_dialog.dart` |
| Dünya / sezon haritası | `pages/season_map_page.dart` (2300 satır), giriş: `widgets/world_map_button.dart` |
| Uygulama ikonu seçimi | `pages/app_icon_page.dart` |
| İçerik şikayet | `pages/content_report_detail_page.dart` |
| Prompt detay | `widgets/prompt_detail_sheet.dart`, önizleme `widgets/prompt_preview.dart` |
| Prompt ekle | `widgets/add_prompt_dialog.dart` |
| Galeri grid | `widgets/masonry_grid.dart` |
| Ürün turu | `lib/features/tour/product_tour.dart` (`ProductTourKeys`) |
| `dont_delete_page.dart` | adı gereği kalıyor; yalnızca 1 referans |

## Ortak UI
`widgets/glass_icon_button.dart`, `widgets/loading_indicator.dart`,
`lib/core/widgets/token_display_widget.dart`,
toast: `lib/core/services/notification_service.dart`.
UI/UX notları: `UI_UX_REVIEW.md`.
