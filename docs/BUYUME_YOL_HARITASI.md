# SpookyAI — Kullanıcı Büyüme Yol Haritası (Android + iOS)

> Hazırlanma: 19 Kasım 2026. Mevcut sürüm: 2.0.0+20.
> Sosyal medya içerik takvimi zaten [marketing/ICERIK_TAKVIMI_VE_BUYUME_PLANI.md](marketing/ICERIK_TAKVIMI_VE_BUYUME_PLANI.md)
> ve [marketing/SOSYAL_MEDYA_STRATEJISI.md](marketing/SOSYAL_MEDYA_STRATEJISI.md) içinde var.
> Bu dosya onları tekrar etmez; **uygulama içi ürün, mağaza (ASO), ölçüm ve
> kanal** tarafını sıraya koyar.

---

## 0. Bugünkü durum (koddan çıkarıldı)

| Alan | Durum | Büyümeye etkisi |
|---|---|---|
| Sezon sistemi (Halloween, Christmas) | Var | Güçlü: yıl boyu güncel kalma imkânı |
| Günlük giriş serisi, token, promo kod (Firestore) | Var | Elde tutma için iyi temel |
| Paylaşım (`share_plus`), puanlama (`in_app_review`) | Var | Viral döngü ve yıldız için temel |
| RevenueCat (`purchases_flutter`) | Var | Gelir ölçümü hazır |
| **Analitik (Firebase Analytics vb.)** | **Yok** | Neyin işe yaradığı ölçülemiyor |
| **Çökme takibi (Crashlytics)** | **Yok** | Mağaza puanını sessizce düşüren hatalar görünmüyor |
| **Push bildirim (FCM)** | **Yok** (yalnızca uygulama içi bildirim servisi) | Geri çağırma kanalı yok |
| **Çoklu dil (l10n)** | **Yok** | Mağaza ve uygulama tek dilde: pazarların çoğu kapalı |
| **Deep link / davet sistemi** | **Yok** | Paylaşılan görsel yeni kullanıcı getirmiyor |

**Sonuç:** Önce ölç, sonra dil + mağaza, sonra viral döngü. Ölçüm olmadan
yapılan her kampanya tahmindir.

---

## Faz 1 — Ölçüm ve sağlık (1–2 hafta, hemen)

Amaç: Hangi kullanıcı nereden geliyor, nerede bırakıyor, görmek.

1. **Firebase Analytics + Crashlytics ekle** (`firebase_analytics`,
   `firebase_crashlytics`). Firebase projesi zaten var.
2. **Temel olayları tanımla** (huni):
   `onboarding_complete` → `first_generation` → `image_saved` →
   `image_shared` → `paywall_view` → `purchase` → `day1/day7_return`.
3. **iOS: App Tracking Transparency** gerekirse (reklam ölçümü yapılacaksa),
   App Store gizlilik etiketlerini ve `PRIVACY_POLICY.md`'yi güncelle.
4. **Hedef metrikler** (takip tablosu):
   - D1 elde tutma ≥ %30, D7 ≥ %12
   - Kurulum → ilk görsel ≥ %60
   - Çökmesiz kullanıcı ≥ %99,5
   - Mağaza puanı ≥ 4,5
5. Mağaza konsollarında haftalık bak: Play Console *Edinme raporları*,
   App Store Connect *Analytics → Kaynaklar*.

## Faz 2 — Mağaza optimizasyonu (ASO) (2–3 hafta)

Organik kurulumun en ucuz kaynağı mağaza aramasıdır.

1. **Anahtar kelime araştırması**: "AI photo", "Halloween filter",
   "Christmas photo editor", "AI avatar", "photo to cartoon" vb. Ücretsiz
   başlangıç: mağaza arama önerileri; ücretli: AppTweak / Sensor Tower / Astro.
2. **Başlık ve alt başlık**:
   - iOS: Başlık (30 kr) + Alt başlık (30 kr) + Anahtar kelime alanı (100 kr).
   - Android: Başlık (30 kr) + Kısa açıklama (80 kr) + Uzun açıklama
     (Google uzun açıklamayı da indeksler; kelimeleri doğal kullan).
   - İsim sadece "Halloween" çağrıştırıyor; yıl boyu sezonlar olduğu için
     ör. *"SpookyAI: AI Photo Themes"* gibi daha geniş bir alt başlık düşün.
3. **Ekran görüntüleri**: İlk 3 görsel her şeydir. Önce/sonra karşılaştırması,
   büyük yazı, tek mesaj. Sezona göre değiştir (Christmas şimdi, Valentine Ocak).
4. **Önizleme videosu** (15–30 sn): mevcut Reels videolarından kırpılabilir.
5. **A/B testi**:
   - Android: *Store listing experiments* (ikon, ekran görüntüsü, kısa açıklama).
   - iOS: *Product Page Optimization* + *Custom Product Pages* (reklam/kanal
     başına farklı sayfa).
6. **Sezonsal mağaza etkinlikleri**:
   - iOS **In-App Events** (ör. "Christmas Theme Week") — arama ve Bugün
     sekmesinde görünür.
   - Android **Promotional Content / LiveOps** — Play Console'dan başvur.
7. **Yorum yönetimi**: Her yoruma (özellikle 1–3 yıldız) 48 saat içinde
   yanıt. Puan isteğini doğru anda göster: başarılı bir görsel kaydedildikten
   sonra, asla hata/ödeme ekranından sonra değil (`rating_service` zaten var,
   tetikleme anını kontrol et).

## Faz 3 — Yerelleştirme (3–5 hafta)

Tek dil = pazarın küçük bir kısmı. AI görsel uygulamaları dil bağımsız
olduğundan çeviri çok verimli.

1. **Mağaza sayfasını önce yerelleştir** (kod değişikliği gerektirmez, en hızlı
   kazanç): EN, TR, ES, PT-BR, DE, FR, IT, JA, KO, AR, ID, RU.
2. **Uygulama arayüzünü yerelleştir**: `flutter_localizations` + `intl`
   (ARB dosyaları). Kütüphane prompt metinleri kullanıcıya gösterilmediği
   için çeviri gerektirmez; yalnızca arayüz metinleri.
3. **Yerel sezonlar**: [SEASON_CALENDAR.md](SEASON_CALENDAR.md) içindeki
   Ramazan, Diwali, Ay Yeni Yılı gibi sezonlar o pazarlarda mağaza
   etkinliğiyle birlikte açılırsa çok güçlü olur.
4. Fiyatlandırma kararları sahibine aittir; yalnızca mağazanın bölgesel fiyat
   önerilerinin gözden geçirilmesi not edilir.

## Faz 4 — Viral döngü (paylaşım = kurulum) (4–6 hafta)

Bu uygulamanın en büyük büyüme kaldıracı: her üretilen görsel bir reklamdır.

1. **Paylaşılan görsele ince filigran / köşe logosu** + "SpookyAI ile
   yapıldı". Premium kullanıcı kapatabilir (premium'a da sebep olur).
2. **Paylaşım metnine mağaza linki** ekle (tek link; cihaza göre App Store /
   Play Store'a yönlendiren bir yönlendirme sayfası).
3. **Davet (referral) sistemi**: Davet eden ve edilen token kazanır. Firestore
   + promo kod altyapısı zaten var; davet kodu aynı yapıyla yapılabilir.
   Kötüye kullanım için cihaz kimliği sınırı (promo kodlardaki gibi).
4. **Deep link**: Firebase Dynamic Links kapandı; `app_links` + iOS
   Universal Links / Android App Links (veya Branch / AppsFlyer OneLink).
   Linkle gelen kişi doğrudan o stile/trende düşsün.
5. **Paylaşım anını öne çıkar**: Sonuç ekranında "Kaydet" kadar görünür bir
   "Story'de paylaş" düğmesi (Instagram/TikTok story formatında 9:16 çıktı).
6. **Trend/challenge formatı**: Haftalık "trend stili" (`trend_service` var)
   + hashtag → sosyal medya planıyla aynı takvimde.

## Faz 5 — Elde tutma ve geri çağırma (paralel, 3–4 hafta)

Yeni kullanıcı getirmek, kaybetmekten pahalıdır; ayrıca mağaza algoritmaları
elde tutmayı ödüllendirir.

1. **Push bildirim (FCM)**: Yeni sezon açıldı, yeni trend stili, günlük
   ödülün hazır, serin bozulmak üzere. Haftada en fazla 2–3; izin isteğini
   ilk başarılı görselden sonra iste.
2. **Remote Config** (`firebase_remote_config`): Sezon, trend, paywall
   metni, onboarding varyantlarını uygulama güncellemesi olmadan değiştir ve
   A/B test et.
3. **Onboarding'i kısalt**: Hedef, açılıştan ilk görsele 60 saniyenin altı.
   Ücretsiz ilk üretim hakkı net görünsün.
4. **Seri ve koleksiyon**: Günlük giriş serisine sezon rozeti / koleksiyon
   ekle (ör. "12 Christmas stili topla").
5. **Kazan-geri kampanyası**: 14 gün girmeyen kullanıcıya push + ücretsiz
   token (promo kod altyapısıyla).

## Faz 6 — Ücretli edinme ve iş birlikleri (ölçüm hazır olunca)

Faz 1 olmadan bu fazı başlatma: kurulum başına maliyet ölçülemez.

1. **Apple Search Ads**: Önce *Basic*, küçük bütçe, marka + rakip + jenerik
   kelimeler. Custom Product Page ile eşleştir.
2. **Google App Campaigns (UAC)**: Hedef "uygulama içi etkinlik" (ilk görsel
   veya satın alma) olsun, yalnızca kurulum değil.
3. **TikTok / Meta reklamları**: En iyi organik Reels'i reklam olarak kullan
   (Spark Ads). Ölçüm için SKAdNetwork / AdAttributionKit (iOS) ve bir MMP
   (AppsFlyer, Adjust veya ücretsiz başlangıç için Firebase).
4. **Mikro influencer**: 10k–100k takipçili "AI art", "Halloween/Christmas
   makeup", "aile/evcil hayvan" hesapları. Ödeme yerine kullanıcı başı promo
   kod (Firestore'da `remainingUses` ile sınırlı) ve takip edilebilir link.
5. **Ürün listeleri / topluluklar**: Product Hunt, Reddit (r/aiArt vb.,
   kurallara uyarak), Türk teknoloji toplulukları, AI araç dizinleri.

## Faz 7 — Platforma özel ekstralar

**iOS**
- Ana ekran **widget**'ı (günün stili / son görsel) — görünürlük ve geri dönüş.
- **App Clip** veya Shortcuts eylemi (isteğe bağlı, sonra).
- Apple "Featured" başvurusu: App Store Connect → *Featuring Nominations*
  (sezon güncellemelerinden 2–3 hafta önce başvur).

**Android**
- Play Console *Featuring* / Editoryal başvuru formu.
- **Play Instant** veya hafif deneme (isteğe bağlı).
- Uygulama boyutunu küçült (App Bundle zaten var): büyük asset'leri sezon
  bazlı indirilebilir yap; düşük boyut, gelişmekte olan pazarlarda kurulumu
  artırır.
- Android Vitals: ANR ve çökme oranı eşiği aşılırsa Play görünürlüğü düşürür.

---

## Takvim (sezonlara bağlı)

| Tarih | Odak | Mağaza / kanal işi |
|---|---|---|
| 19 Kas – 1 Ara 2026 | Faz 1 (ölçüm) + Christmas ASO | Christmas ekran görüntüleri, iOS In-App Event |
| Aralık 2026 | Faz 2 bitir, Faz 4 başla (filigran + paylaşım linki) | Christmas zirvesi, yorum yanıtları |
| Ocak 2027 | Faz 3 (mağaza çevirileri) + Valentine sezonu | Valentine In-App Event, featuring başvurusu (Ara sonu) |
| Şubat 2027 | Faz 5 (FCM, Remote Config), davet sistemi | Ay Yeni Yılı (yerel pazarlar) |
| Mart – Nisan 2027 | Arayüz çevirisi, Bahar/Paskalya sezonu | İlk ücretli test: Apple Search Ads + UAC küçük bütçe |
| Mayıs – Ağustos 2027 | Yaz sezonu, influencer iş birlikleri | Ölçeklenen reklamlar (yalnızca karlı kanallar) |
| Eylül 2027 | Halloween hazırlığı | Featuring başvurusu (Ağustos sonu), yeni ekran görüntüleri |
| Ekim 2027 | **Ana sezon** | Tüm kanallar aynı anda; In-App Event, reklam bütçesi zirve |

---

## Öncelik özeti (yalnızca 5 iş yapılacaksa)

1. Firebase Analytics + Crashlytics.
2. Mağaza sayfasını yeniden yaz + ilk 3 ekran görüntüsü + 5–10 dilde çeviri.
3. Paylaşılan görsele filigran + mağaza linki.
4. FCM push + sezon/trend bildirimi.
5. Her sezon için iOS In-App Event ve Play promosyon içeriği.

## Haftalık kontrol listesi

- [ ] Konsollarda kurulum, dönüşüm oranı, D1/D7 elde tutmaya bak
- [ ] Crashlytics'teki ilk 3 çökmeyi düzelt
- [ ] Tüm yeni yorumlara yanıt ver
- [ ] Sosyal medya takvimindeki paylaşımları yap
- [ ] Bir A/B testi açık mı? Sonucu oku, kazananı uygula
