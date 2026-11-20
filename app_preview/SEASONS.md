# Sezon / tema sistemi

Tam rehber: `docs/SEASONS.md` (§5 = yeni sezon ekleme kontrol listesi),
takvim: `docs/SEASON_CALENDAR.md`. Mevcut sezonlar: `SeasonId { halloween, christmas }`.

| Dosya (`lib/core/theme/seasons/`) | Rol |
|---|---|
| `season_theme.dart` | `SeasonId` enum + sezon tanım yapısı (yeni sezon buraya) |
| `season_registry.dart` | Tüm sezon tanımları + tarihe göre otomatik seçim |
| `season_provider.dart` | Aktif sezon; otomatik veya kullanıcı sabitlemesi |
| `season_palette.dart` | Context'siz renk erişimi |
| `season_decor.dart`, `season_ambient.dart`, `season_effects_layer.dart` | Parçacık efektleri (kor, kar...) |
| `season_art_image.dart` | Paketli görselin sezon karşılığı |
| `season_badge.dart` | App bar altındaki DLC tarzı sezon etiketi |
| `season_splash_stage.dart` | Splash ve sezon geçişi düzeni |
| `season_transition_overlay.dart` | Sezon değişince tam ekran geçiş |

Sezona bağlı diğer yerler:
- Stil kütüphanesi: `prompt_service.dart` (Halloween), `christmas_prompts.dart`
- Uygulama ikonu: `app_icon_service.dart`, `pages/app_icon_page.dart`, `assets/icons/`, native `ios/`/`android/` alternatif ikon kaydı
- Ortam sesi: `ambient_sound_service.dart`, `assets/sounds/`
- Dünya haritası: `pages/season_map_page.dart`, `widgets/world_map_button.dart`
- Seçili stil sezon değişince temizlenir: `MainNavigationProvider._dropStylesOfOtherSeason`
- Genel tema: `lib/core/theme/app_theme.dart`

Testler: `season_theme_test`, `season_completeness_test`, `color_contrast_test`,
`app_icon_service_test`, `ambient_sound_service_test`.
