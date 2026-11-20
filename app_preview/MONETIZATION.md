# Para kazanma: token, satın alma, ödüller

Fiyatlar ve token maliyetleri sahibin kararıdır; sorulmadan değiştirme.

| Konu | Dosya | Not |
|---|---|---|
| Üretim maliyetleri | `lib/core/services/token_costs.dart` | text→image 1, image→image 2, image→video 4 |
| Bakiye | `lib/core/services/token_service.dart` | yeni kurulum 3 token (`initialTokens`), SharedPreferences + SecureStorage |
| Bakiye UI | `token_provider.dart`, `lib/core/widgets/token_display_widget.dart` | |
| Deneme hakkı sunucu kontrolü | `trial_guard_service.dart` | `$base/trial/claim` (fal proxy worker) |
| Mağaza (RevenueCat) | `in_app_purchase_service.dart`, `ios_purchase_service.dart`, `android_purchase_service.dart` | `purchases_flutter`; anahtarlar `environment_config.dart` |
| Satın alma state | `purchase_provider.dart` | önerilen paket işareti |
| Paket sayfası | `pages/purchase_page.dart` | 150/60/25/10 token, Redeem butonu burada |
| Paywall | `widgets/paywall_dialog.dart` | onboarding sonrası ve Profil'den |
| Premium/abonelik | `premium_service.dart`, `lib/core/models/paywall_service.dart` | banner: `MainNavigationProvider` |
| Free limitleri | `prompts_provider.dart` | mod başına hazır prompt limiti |
| Promo / redeem kod | `promo_code_service.dart` | Firestore `promo_codes/{KOD}`: tokens, maxUses, remainingUses, expiresAt?, active?; transaction + `redemptions/{deviceId}`; kurallar `firestore.rules` |
| Günlük giriş / streak | `daily_login_service.dart` | |
| Puanlama ödülü | `rating_service.dart`, `widgets/result_rating_card.dart` | Firestore `ratings`; test `rating_reward_policy_test` |
| Başarı/hata diyalogları | `widgets/purchase_success_dialog.dart`, `purchase_failed_dialog.dart`, `low_balance_dialog.dart` | |

Testler: `token_costs_test`, `token_trial_test`, `promo_code_service_test`, `paywall_page_test`.
Elle oluşturulacak promo kodları Firebase Console'dan eklenir (istemci yazamaz).
