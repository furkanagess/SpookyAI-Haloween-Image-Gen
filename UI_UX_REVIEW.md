# SpookyAI — UI/UX İncelemesi

Tarih: 2026-11-14 · Yöntem: `ui-ux-pro-max` kural seti (öncelik 1→10) ile `lib/` statik kod incelemesi.
Kapsam notu: Uygulama cihazda çalıştırılmadı; kontrast ve yerleşim yorumları koddan çıkarıldı, ekranda doğrulanmalı.

**Proje tipi:** Flutter mobil uygulama (eğlence / AI görsel üretimi), varsayılan karanlık tema (`core/theme/app_theme.dart:14`), mevsimsel tema sistemi (`core/theme/seasons/`), 5 sekmeli alt navigasyon, onboarding var.

---

## Bulgular (önem sırasıyla)

### KRİTİK

**1. Okunamayacak kadar küçük metinler (12px altı 15 yer)**
- `core/theme/seasons/season_badge.dart:53,64` — mevsim rozeti 9px, harfleri büyük, `letterSpacing 1.1`.
- `features/home/presentation/pages/prompts_page.dart:754` (11.5), `:796` (10.5); `generated_result_page.dart:266`; `widgets/style_picker_card.dart:91`; `widgets/generation_progress_dialog.dart:267`; `pages/purchase_page.dart:719` (11).
- **Öneri:** En küçük gövde metni 12sp, bilgi/etiket metni 13–14sp olsun. Rozet için 10–11sp + w800 yeterli; büyük harf + geniş harf aralığı küçük boyutta okunmayı daha da zorlaştırır. Boyutları `TextTheme` üzerinden (`labelSmall` vb.) tek yerden yönetin.

**2. Renk kontrastı / sabit kodlanmış renkler (features altında 465 adet `Colors.white/black/Color(0x..)`)**
- Örnek: `pages/photos_page.dart:846` `Colors.white38` (koyu zeminde ≈ 3:1, WCAG AA 4.5:1 altında), `photos_page.dart:605` `white.withOpacity(0.22)`, `season_map_page.dart:909` `white 0.35`.
- `app_theme.dart:36-37` tüm metni `Colors.white`'a zorluyor; açık zemine düşen bir yüzeyde (örneğin açık renkli mevsim paleti) metin kaybolur. Önceki low-balance dialog'unda bu tam olarak yaşandı.
- **Öneri:** `ColorScheme.onSurface / onSurfaceVariant` ve `SeasonPalette` içinde anlamsal token'lar (`textPrimary`, `textMuted` ≥ 4.5:1, `iconDisabled` ≥ 3:1) tanımlayın; widget'larda ham `Colors.white*` kullanımını kaldırın. Her mevsim paletinin accent-üzeri-beyaz kontrastını bir testle doğrulayın (rozet: `season_badge.dart:44` accent zemin + beyaz 9px metin).

**3. Ekran okuyucu desteği zayıf**
- Tüm `lib/` içinde yalnızca 33 `Semantics/tooltip/semanticLabel` kullanımı var; 35 `GestureDetector` ise semantik rol ve dokunma geri bildirimi (ripple) vermiyor (ör. `generated_result_page.dart:324,526,646,665`, `profile_page.dart:190`).
- 11 `IconButton`'dan yaklaşık 5'inde `tooltip` yok (tooltip aynı zamanda erişilebilir etikettir).
- Üretilen görseller ve galeri kartları için `semanticLabel` yok.
- **Öneri:** Tıklanabilir `GestureDetector`'ları `InkWell`/`IconButton`'a çevirin veya `Semantics(button: true, label: ...)` ile sarın; her ikon butonuna `tooltip` verin; galeri görsellerine "Oluşturulan görsel, <stil adı>" gibi etiket ekleyin.

### YÜKSEK

**4. Metin ölçekleme (Dynamic Type) hiç ele alınmamış**
- Kodda `textScaler` / `textScaleFactor` kontrolü yok. Sabit yükseklikli rozet (`season_badge.dart` `_height`), kartlar ve alt nav, sistem yazı boyutu %130+ olduğunda taşar veya kırpılır.
- **Öneri:** iOS/Android'de en büyük yazı boyutunda ana ekranları test edin; sabit `height` yerine `minHeight`/esnek düzen kullanın, gerekiyorsa `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4)` ile sınır koyun.

**5. Emoji ikon olarak kullanılıyor (99 yer)**
- `data/services/prompt_service.dart:11,147`, `christmas_prompts.dart:13,139`, `season_badge.dart:51` (`season.emoji`).
- Emoji platforma göre farklı görünür, renk/boyut temaya uymaz ve ekran okuyucu "Noel ağacı" gibi alakasız şeyler okur.
- **Öneri:** Kategori/stil ikonlarını tek bir ikon setine (Material Symbols veya özel SVG) taşıyın; emoji kalacaksa dekoratif olarak `ExcludeSemantics` ile sarın.

**6. Dil tutarsızlığı (Türkçe + İngilizce karışık)**
- `widgets/paywall_dialog.dart:137,164-185` Türkçe ("Görsel oluşturmak için token satın alın"), alt nav ve yeni low-balance dialog'u İngilizce (`main_navigation_page_refactored.dart:796`). Paywall `main_navigation_page_refactored.dart:130`'da hâlâ kullanılıyor.
- **Öneri:** Kısa vadede paywall metnini uygulamanın diline çevirin; orta vadede `flutter_localizations` + ARB'ye geçin.

**7. Hata durumları sessizce yutuluyor**
- `main_navigation_page_refactored.dart:124,302,329,346` `catch (_) {}`. Üretim hatası için `_showFailure` + `GenerationFailure.classify` (`:182`) iyi bir yapı, ama premium/token yenileme gibi yan akışlarda hata olursa kullanıcı bakiyeyi yanlış görebilir.
- **Öneri:** En azından debug log + kullanıcının etkilendiği yerlerde ("Bakiye güncellenemedi, tekrar dene") ince bir SnackBar.

### ORTA

**8. Hareketi azaltma (reduced motion) yalnızca mevsim efektlerinde**
- `season_ambient.dart:40`, `season_effects_layer.dart:25`, `season_transition_overlay.dart:42` doğru şekilde `disableAnimations`'a bakıyor 👍. Ama alt nav kayması (`main_navigation_page_refactored.dart:786`), low-balance ölçek animasyonu ve üretim ilerleme dialog'u buna uymuyor.
- **Öneri:** Ortak bir `motionDuration(context)` yardımcı fonksiyonu yazın; `disableAnimations` açıkken süreyi 0'a çeksin.

**9. Alt navigasyon kaydırınca gizleniyor**
- `main_navigation_page_refactored.dart:786-789` `navHidden` ile nav ekran dışına kayıyor. Mobilde kabul gören bir desen, ama ekran okuyucu ve klavye kullanıcıları nav'ı "kaybedebilir".
- **Öneri:** `MediaQuery.accessibleNavigationOf(context)` true ise nav'ı gizlemeyin.

**10. Görsel üretim akışı**
- İyi: onay sheet'i (`generate_confirm_sheet.dart`), iptal destekli ilerleme dialog'u (`generation_progress_dialog.dart:28,54`), sınıflandırılmış hata + yeniden dene.
- Eksik: ilerleme dialog'unda tahmini süre / aşama metni küçük (11px, `:267`); işlem sırasında uygulamadan çıkılırsa ne olacağı belirtilmiyor; token maliyeti üretim butonunun üstünde değil sheet içinde görünüyor.
- **Öneri:** Üret butonunda maliyeti göster ("Oluştur · 1 token"); ilerleme ekranına 14sp aşama metni ve "Arka planda devam et" seçeneği ekleyin.

**11. Galeri boş/yükleniyor/hata durumları**
- `photos_page.dart:353` yükleniyor (spinner), `:357` boş durum, `:845` kırık görsel ikonu var — temel durumlar mevcut 👍.
- **Öneri:** Spinner yerine ızgara iskeleti (skeleton) kullanın; kırık görsel ikonu `white38` yerine okunur bir renk + "Yeniden yükle" eylemi alsın; boş durumda doğrudan "İlk görselini oluştur" butonu olsun.

**12. Onboarding**
- `features/onboarding/presentation/pages/onboarding_page.dart:91-109` "Skip" var 👍.
- **Öneri:** Skip butonunun dokunma alanı ≥ 44×44 olmalı; son sayfada ücretsiz başlangıç token'ını ve tek bir örnek üretimi göstermek (ilk değeri hızlı göstermek) dönüşümü artırır. Sayfa göstergesine `Semantics(label: 'Sayfa 2 / 4')` ekleyin.

### DÜŞÜK

**13. Dev dosyalar bakım ve tutarlılığı zorlaştırıyor** — `season_map_page.dart` 2294, `main_navigation_page_refactored.dart` 1135, `prompts_page.dart` 993 satır. Ayrıca kullanılmayan görünen `prompt_service_backup.dart`, `prompt_service_organized.dart`, `prompt_service_updated.dart`. Ortak kart/buton/boşluk bileşenleri (`app_metrics.dart` var) çıkarılmadıkça stil kayması sürer.

**14. Boşluk tutarlılığı** — `app_metrics.dart` mevcut ama örneğin `season_badge.dart:46` `left: 7, right: _height/2 + 6` gibi tek seferlik değerler yaygın. 4/8 tabanlı bir ölçeğe (`AppSpacing.xs/s/m/l`) sabitleyin.

---

## En etkili ilk 5 düzeltme

1. **Anlamsal renk token'ları + kontrast testi** (Bulgu 2) — tema hatalarının ve okunmazlığın kök nedeni; her mevsimi otomatik doğrular.
2. **Minimum yazı boyutu 12sp ve `TextTheme` üzerinden tipografi** (Bulgu 1) — 15 yeri tek seferde düzeltir.
3. **Erişilebilirlik geçişi:** `GestureDetector` → `InkWell`/`Semantics`, `IconButton` tooltip'leri, görsel etiketleri (Bulgu 3).
4. **Paywall metnini tek dile çevirmek** (Bulgu 6) — satın alma anında güven kaybını önler, küçük iş.
5. **Üretim akışında maliyeti butonda göstermek + okunur ilerleme metni** (Bulgu 10) — ana akışın netliği ve token sürprizlerini azaltır.

## Uygulanan düzeltmeler (2026-11-14)

1. `SeasonPalette.onAccent`, `subtleIcon`, `onColor()`, `contrastRatio()` eklendi. Yeni `test/color_contrast_test.dart` her mevsim × açık/koyu mod için WCAG oranlarını kontrol ediyor. Test, Halloween koyu modda soluk metnin 4.04:1 olduğunu yakaladı; renk `0xFF9F8FB8` yapıldı (≥4.5:1). Filtre çipleri, kırık görsel ikonu ve mevsim rozeti token'lara geçirildi. Kalan yüzlerce `Colors.white` kullanımı ayrı bir iş olarak duruyor.
2. 12px altındaki tüm yazılar 12'ye (rozet 11 kalın) çekildi; rozet yüksekliği 19 yapıldı.
3. Düzeltme: ilk sayımın aksine çoğu `GestureDetector` zaten `Semantics` ile sarılıydı. Eksik 6 dokunma alanı ve 4 `IconButton` tooltip'i tamamlandı. Galeri kartı etiketi prompt metni yerine "Generated image" oldu (prompt metni kullanıcıya gösterilmez kuralı).
4. Paywall ve stil seçicideki Türkçe metinler İngilizceye çevrildi.
5. Düzeltme: ana üret butonu maliyeti zaten gösteriyordu. Onay sayfasının butonuna "Generate · N tokens" eklendi; ilerleme ekranındaki süre metni 14sp ve tema rengine geçti.

Doğrulama önerisi: değişikliklerden sonra iOS/Android'de en büyük yazı boyutu, VoiceOver/TalkBack ve "hareketi azalt" açıkken Generate → Sonuç → Galeri akışını yürüyün.
