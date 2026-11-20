# SpookyAI — Yapılacaklar Takibi

Projedeki tüm açık işlerin tek listesi. Ayrıntılar bağlantı verilen
belgelerde; burada yalnızca durum tutulur.

Son güncelleme: 2026-11-19 · Sürüm: `2.0.0+20` · Dal: `feat/analytics-seasons-growth`

`[x]` tamam · `[~]` kısmen / sürüyor · `[ ]` yapılmadı

---

## 1. Şimdi (sürüm öncesi)

- [~] Analitik değişikliklerini bitir ve commit et (`analytics_service.dart`,
      `main.dart`, `firebase.json` commit edilmemiş)
- [ ] `website/` klasörünü (Firebase Hosting, site `spookyai-app`) yayınla ve commit et
- [x] Android appbundle release build'i alındı (2.0.0+20, upload sertifikasıyla imzalı)
- [x] Android SDK + NDK 28.2 kuruldu, Flutter ona yönlendirildi
- [ ] iOS release build (`tool/build_release.sh ios`)
- [ ] Play Console'a yükle, App Store Connect'e gönder
- [x] App Review notları yazıldı (galeri erişimi, farklılaştırıcı özellikler, Çin bölgesi yanıtı)

## 2. Güvenlik ve fal anahtarı ([SECURITY.md](SECURITY.md))

- [x] Kaynak koddaki anahtar kaldırıldı, sır taraması testi eklendi
- [x] fal proxy yazıldı ve testleri var (`tool/fal_proxy`)
- [ ] Eski fal anahtarını iptal et, yenisini oluştur
- [ ] fal hesabına harcama limiti koy
- [ ] Proxy'yi Cloudflare'e deploy et (`wrangler` kurulu değil; yeni anahtar secret olarak)
- [ ] Release build'i tekrar proxy'ye bağla — **şu an release, `.env` içindeki
      doğrudan `FAL_AI_API_KEY` ile derleniyor; anahtar uygulamadan çıkarılabilir**
- [ ] `build_release.sh` korumasını proxy zorunlu hâline geri al
- [ ] (İsteğe bağlı) `git filter-repo` ile eski anahtarı geçmişten sil

## 3. Promo kod (Firestore)

- [x] Redeem akışı Firestore `promo_codes` belgelerine bağlandı (limit, kalan kullanım, token, son tarih)
- [x] Cihaz başına tek kullanım, transaction ile sayaç düşürme
- [x] Firestore kuralları deploy edildi (`spookyai-app-ratings`)
- [x] Birim testleri geçiyor
- [ ] Firebase Console'da `TEST10` kodunu elle oluştur
- [ ] Cihazda redeem akışını test et
- [ ] Bu değişikliği içeren sürümü yayınla (eski sürümler kod kullanamaz)

## 4. Büyüme yol haritası ([docs/BUYUME_YOL_HARITASI.md](docs/BUYUME_YOL_HARITASI.md))

### Faz 1 — Ölçüm ve sağlık
- [x] Firebase Analytics + Crashlytics eklendi
- [~] Huni olayları: `onboarding_complete`, `first_generation`, `image_shared`,
      `paywall_view` var · `image_saved`, `purchase`, `day1/day7_return` eksik
- [ ] iOS ATT gerekiyorsa ekle; App Store gizlilik etiketleri + `PRIVACY_POLICY.md` güncelle
- [ ] Hedef metrik tablosunu kur (D1 ≥ %30, D7 ≥ %12, ilk görsel ≥ %60, çökmesiz ≥ %99,5)

### Faz 2 — Mağaza optimizasyonu (ASO)
- [ ] Anahtar kelime araştırması
- [ ] Başlık / alt başlık / açıklamaları yeniden yaz (yıl boyu sezonları yansıtacak şekilde)
- [ ] İlk 3 ekran görüntüsünü yenile

### Faz 3 — Yerelleştirme
- [ ] Uygulamaya l10n altyapısı ekle (`flutter_localizations` yok)
- [ ] Mağaza sayfasını 5–10 dile çevir

### Faz 4 — Viral döngü
- [x] Paylaşım (`share_plus`) var
- [ ] Paylaşılan görsele filigran + mağaza linki
- [ ] Deep link / davet sistemi

### Faz 5 — Elde tutma ve geri çağırma
- [x] Günlük giriş serisi, token ödülü, puanlama isteği var
- [ ] FCM push bildirimleri
- [ ] Sezon / trend bildirimleri

### Faz 6–7 — Ücretli edinme, platforma özel
- [ ] Her sezon için iOS In-App Event ve Play promosyon içeriği
- [ ] Ölçüm oturduktan sonra ücretli kampanya / iş birlikleri

### Haftalık rutin
- [ ] Konsollarda kurulum, dönüşüm, D1/D7'ye bak
- [ ] Crashlytics'teki ilk 3 çökmeyi düzelt
- [ ] Yeni yorumlara yanıt ver
- [ ] Sosyal medya paylaşımlarını yap
- [ ] Açık A/B testini oku, kazananı uygula

## 5. Sezonlar ([docs/SEASON_CALENDAR.md](docs/SEASON_CALENDAR.md))

- [x] Sezon sistemi (registry, palet, efektler, geçiş) kuruldu
- [x] Halloween yayında
- [x] Christmas yayında
- [ ] Sevgililer Günü (25 Oca – 15 Şub) — öncelik 1, **yakında**
- [ ] İlkbahar / Paskalya (15 Mar – 25 Nis) — öncelik 2
- [ ] Yaz (1 Haz – 31 Ağu) — öncelik 3
- [ ] Yılbaşı gecesi (26 Ara – 2 Oca) — öncelik 4
- [ ] Sahip kararları (bölüm 6): hedef pazarlar, sezon dışı yedek dünya,
      remote-config takvimi, ücretli kullanıcıya erken erişim

## 6. UI/UX ([UI_UX_REVIEW.md](UI_UX_REVIEW.md))

- [x] Renk token'ları + kontrast testi (`color_contrast_test.dart`)
- [x] Minimum yazı boyutu 12
- [x] Erişilebilirlik: eksik `Semantics` ve tooltip'ler
- [x] Paywall metni tek dile (İngilizce)
- [x] Onay butonunda token maliyeti
- [ ] Kalan sabit `Colors.white` kullanımlarını token'lara taşı
- [ ] Büyük yazı, VoiceOver/TalkBack ve "hareketi azalt" ile cihazda akış testi

## 7. Kullanıcı tutma fikirleri ([USER_RETENTION_FEATURES.md](USER_RETENTION_FEATURES.md))

- [x] Günlük ödül + seri
- [ ] Profil ve istatistikler
- [ ] Başarımlar / gamification
- [ ] Referans ve davet sistemi
- [ ] Premium abonelik
- [ ] Akıllı bildirimler

## 8. Teknik borç

- [ ] Boş test dosyaları: `prompt_builder_test.dart`, `widget_test.dart` (doldur ya da sil)
- [x] Prompt motoru, moderasyon, sahne kitleri ([PROMPT_ARCHITECTURE.md](PROMPT_ARCHITECTURE.md))
