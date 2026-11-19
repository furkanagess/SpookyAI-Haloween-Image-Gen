# SpookyAI — İçerik Üretim Prosedürü (TikTok + Instagram)

> **Bu dosya zorunlu prosedürdür.** Her video ya da carousel, fikirden
> yayına kadar bu sırayla ilerler. Her bölümün sonunda bir **KAPI** var.
> Kapıdaki maddelerin hepsi işaretlenmeden bir sonraki bölüme geçme.
>
> Hesap: **@spooky_ai_** · Hedef: **ABD** · Dil: **Amerikan İngilizcesi**
>
> Bağlantılı dosyalar:
> - Neyi üreteceğin: [PAYLASIM_TAKVIMI_DETAYLI.md](PAYLASIM_TAKVIMI_DETAYLI.md) (V01–V32)
> - Karakterler ve promptlar: [KARAKTER_PROMPTLARI.md](KARAKTER_PROMPTLARI.md)
> - Strateji, hook'lar, hashtag'ler: [SOSYAL_MEDYA_STRATEJISI.md](SOSYAL_MEDYA_STRATEJISI.md)

---

## Genel akış

```
0. Hazırlık (bir kere)      → klasörler, şablonlar, master karakterler
1. Brief kartı              → bu video ne, kime, neden?
2. Görsel üretimi           → uygulama → seçme → büyütme
3. Kurgu (CapCut)           → yerleşim, geçiş, yazı, kapak
4. Ses                      → trend kontrolü, seviye
5. Metin                    → açıklama, hashtag, sabit yorum
6. Kalite kontrol (QA)      → yayın öncesi son kontrol
7. Yükleme                  → TikTok ayarları / Instagram ayarları
8. Yayından sonraki 60 dk   → yorumlar, sabit yorum, story
9. Ölçüm                    → 24 saat ve 72 saat kontrolü
```

Bir videonun yaklaşık süresi: brief 5 dk · üretim 15 dk · kurgu 15 dk · metin
ve QA 5 dk · yükleme 3 dk → **~45 dk**. Toplu üretimde (aynı gün 5–7 video)
video başı ~25 dk'ya düşer.

---

## 0. Hazırlık (bir kere yapılır)

### 0.1 Klasör yapısı
Telefonda (Dosyalar / iCloud Drive) ve bilgisayarda aynı yapı:
```
SpookyAI_Social/
├── 00_Karakterler/        master_emma.jpg, master_maya.jpg, master_jake.jpg,
│                          master_lily_marco.jpg, master_mango.jpg, master_biscuit.jpg
├── 01_Ham_Uretim/         uygulamadan çıkan 512 px görseller ve videolar
├── 02_Buyutulmus/         2048 px versiyonlar
├── 03_Kurgu_Export/       CapCut'tan çıkan son videolar
├── 04_Kapaklar/           1080×1920 kapak görselleri
└── 05_Yayinlandi/         paylaşılanlar (tarihli)
```

### 0.2 Dosya adlandırma
```
[TARIH]_[VIDEO KODU]_[KARAKTER]_[STIL]_[VERSIYON]
2026-11-20_V02_emma_frostqueen_v1.jpg
2026-11-20_V02_emma_final.mp4
```
Böylece bir video viral olunca hangi görselden yapıldığını hemen bulursun.

### 0.3 CapCut şablonları
CapCut → yeni proje → **9:16, 1080×1920, 30 fps** → aşağıdaki şablonları
"Şablon olarak kaydet" ile kaydet:
- **T-F1** Beat Drop (5 görsel yuvası, beat işaretli)
- **T-F2** Oylama (2×2 ızgara + numaralar)
- **T-F4** Fotoğraftan videoya (donmuş kare → video)
- **T-F7** Nasıl yapılır (ekran kaydı yuvası + köşe sonuç)
- **T-F8** Carousel kapağı (Canva'da, 1080×1920)

Her şablonda **yerleşim**, **yazı stili** ve **arka plan bulanıklığı**
hazır olsun (bkz. Bölüm 3).

### 0.4 Marka stili (her videoda aynı)
| Öğe | Değer |
|---|---|
| Ana renk | Koyu mor `#0F0B1A` (uygulama ikonunun arka planı) |
| Vurgu (Noel) | Kırmızı `#C8102E` ve buz mavisi `#BDE3F2` |
| Vurgu (Halloween) | Turuncu `#FF7A1A` |
| Yazı fontu | CapCut: **TikTok Sans Bold** (yoksa "Classic" / Montserrat Bold) |
| Yazı stili | Beyaz yazı + siyah, %60 opak dış çizgi veya gölge (her arka planda okunur) |
| Uygulama adı | Her zaman **SpookyAI** (birleşik, S ve A büyük) |
| Watermark | Yok. Son karede küçük "App: SpookyAI" yazısı yeterli |

### KAPI 0
- [ ] Klasörler oluşturuldu
- [ ] 6 master karakter **onaylandı** ve `00_Karakterler`'de
- [ ] CapCut şablonları kaydedildi
- [ ] Upscayl kurulu (Real-ESRGAN / Ultrasharp, 4×)
- [ ] Metrik tablosu hazır (bkz. Bölüm 9)

---

## 1. Brief kartı (her video için, 5 dk)

Üretime başlamadan önce kartı doldur. Notlar uygulamasına ya da metrik
tablosunun "Brief" sekmesine kopyala. **Kart dolmadan üretime başlama.**

```
VIDEO KODU:        V__ (takvimden)
YAYIN:             __ Kas/Ara · Slot A / B / IG
PLATFORM:          TikTok / Instagram / ikisi
FORMAT:            F1 / F2 / F3 / F4 / F5 / F6 / F7 / F8 / F9
KARAKTER:          Emma / Maya / Jake / Lily&Marco / Mango / Biscuit / yok
STİL(LER):         (uygulamadaki hazır stil adı)
EK AÇIKLAMA:       (KARAKTER_PROMPTLARI.md, bölüm 7; yoksa "-")
HOOK (ekran):      (en fazla 8 kelime)
İLK KARE:          (izleyici 0. saniyede ne görüyor?)
SÜRE:              __ sn
SES TİPİ:          S1–S9
CTA:               yorum / kaydet / paylaş / indir
ANAHTAR KELİME:    (örn. "christmas pfp", aramada çıkması istenen)
NEDEN İŞE YARAR:   (tek cümle: merak / kimlik / komedi / fayda)
```

### Brief kuralları
1. **Tek video = tek fikir.** Hem oylama hem nasıl yapılır olmaz.
2. **İlk kare = sonuç ya da sonuç vaadi.** Logo, boş ekran, "Hi guys" ile açılmaz.
3. **Hook 8 kelimeyi geçmez**, 1,5 saniyede okunabilir.
4. **Anahtar kelime** hook'ta ya da açıklamanın ilk cümlesinde geçer.
5. **CTA tek** olur. "Like, follow, comment, share" olmaz; sadece biri.
6. Videoda gerçek bir kişi, ünlü, marka logosu ya da telifli karakter **yok**.

### KAPI 1
- [ ] Kartın bütün alanları dolu
- [ ] Hook ≤ 8 kelime, anahtar kelime var
- [ ] İlk karenin ne olacağı net
- [ ] Bu fikir son 7 günde aynı biçimde paylaşılmadı (paylaşıldıysa yeni karakter veya stil)

---

## 2. Görsel üretimi (15 dk)

### 2.1 Uygulamada üretim
1. Uygulamada sezonu kontrol et (25 Kasım öncesi **Sezon Haritası → Noel**).
2. Image modu → **master fotoğrafı** seç (`00_Karakterler`'den). Yeni yüz kullanma.
3. Brief'teki **hazır stili** seç.
4. Ek açıklama alanına `KARAKTER_PROMPTLARI.md` bölüm 7'deki cümleyi yapıştır.
   Her zaman `Keep the same face` ile başlasın.
5. Her stil için **en az 2 üretim** yap ve en iyisini seç.
6. Video modu gerekiyorsa: seçilen görsel → video modu → bölüm 8'deki hareket talimatı.

### 2.2 Seçme kriterleri (her görsel için)
| Kontrol | Geçti mi? |
|---|---|
| Yüz master'la **aynı kişi** (göz, burun, çene, ten) | ☐ |
| Eller ve parmaklar normal (ya da kadrajda değil) | ☐ |
| Görselde bozuk yazı veya sahte logo yok | ☐ |
| Gerçek bir ünlüye ya da tanıdık bir karaktere benzemiyor | ☐ |
| Stil net okunuyor (izleyici 1 saniyede "Frost Queen" etkisini görüyor) | ☐ |
| Yüz karenin ortasında ve üst yarısında | ☐ |
| Videoysa: yüz hareket boyunca bozulmuyor, ilk ve son kare temiz | ☐ |

Bir madde bile geçmezse **yeniden üret**. Kötü bir kareyle videoyu kurtarmaya çalışma.

### 2.3 Büyütme
1. Seçilen görselleri `01_Ham_Uretim`'den Upscayl'a at.
2. Model: **Real-ESRGAN** (gerçekçi) veya **Ultrasharp** (detaylı), **4×** → 2048×2048.
3. Çıktıyı `02_Buyutulmus`'e kaydet. Aynı dosya adı + `_up` eki.
4. Kontrol et: yüz "plastik" görünüyorsa daha yumuşak bir model dene.

### KAPI 2
- [ ] Her görsel 2.2'deki 7 kontrolü geçti
- [ ] Bütün görseller 2048×2048'e büyütüldü
- [ ] Videoysa yüz bozulması yok
- [ ] Dosyalar doğru adla doğru klasörde

---

## 3. Kurgu (CapCut, 15 dk)

### 3.1 Proje ayarları
- Oran **9:16** · Çözünürlük **1080×1920** · **30 fps**
- Doğru şablonu aç (T-F1, T-F2…)

### 3.2 Kare görselin dikey videoya yerleşimi
```
y=0     ┌─────────────────────┐
        │   (boş, TikTok üst  │  0–250 px: arayüzün altında kalır, yazı koyma
y=250   │    menüsü)          │
        │   HOOK YAZISI       │  250–420 px: ekran yazısı bölgesi
y=420   ├─────────────────────┤
        │                     │
        │   KARE GÖRSEL       │  420–1500 px: 1080×1080 görsel
        │   1080×1080         │  (sağ kenar 940 px'ten sonrası butonların altında;
        │                     │   yüz ortada olduğu için sorun değil)
y=1500  ├─────────────────────┤
        │  CTA / ikinci yazı  │  1500–1600 px: kısa CTA olabilir
y=1600  │  (boş: açıklama,    │  1600–1920 px: kullanıcı adı ve açıklama
        │   kullanıcı adı)    │  bölgesi, YAZI KOYMA
y=1920  └─────────────────────┘
```
- **Arka plan:** Canvas → **Blur** (aynı görselin bulanık kopyası). Siyah bant yok.
- **Alternatif tam ekran:** görseli %178 büyüt ve yanlardan kırp. Yalnızca 2048 px görsellerle.
- **Güvenli alan:** yazılar yatayda **x = 60–940** aralığında kalsın.

### 3.3 Zamanlama kuralları
| Kural | Değer |
|---|---|
| İlk kare | Sonuç ya da sonucu ima eden kare. **0,0. saniyede** görünür |
| Hook yazısı | 0,0 sn'de ekranda, en az **1,5 sn** kalır |
| Her görsel (beat drop) | 0,6–1,2 sn, beat'e oturtulmuş |
| Son kare | **1,5–2 sn** bekle (oylama veya CTA okunabilsin) |
| Toplam süre | Dönüşüm 7–12 sn · Nasıl yapılır 15–25 sn · POV 10–15 sn |
| Döngü | Son kare ilk kareye yakın olsun ki video baştan izlensin (izlenme süresini artırır) |

### 3.4 Geçişler ve efektler
- Beat drop'ta: **kesme** (cut) veya **zoom in** geçişi. Her geçişte farklı efekt kullanma; en fazla 2 tür.
- Noel: hafif **kar efekti** (Effects → "Snow", opaklık %40). Halloween: hafif sis.
- Fotoğraftan videoya: ilk 1–2 sn **donmuş kare** (Freeze), sonra video.
- **Yasak:** aşırı parlama, flaş efekti. Göz yorar, ayrıca bazı izleyiciler için ışığa duyarlılık riski var.

### 3.5 Ekran yazısı
- En fazla **2 satır**, satır başına en fazla ~4 kelime.
- Boyut: hook için **büyük** (ekran genişliğinin ~%80'i), ikinci yazı için orta.
- Her yazı en az **1,5 sn** ekranda kalsın.
- Yazım: Amerikan İngilizcesi (`color`, `favorite`). Yazım hatası güven kaybettirir.
- **Otomatik altyazı:** seslendirme varsa CapCut → Auto captions → İngilizce → kontrol et ve düzelt.

### 3.6 Kapak karesi
- **1080×1920** · en çarpıcı sonuç + **3–5 kelimelik** kapak yazısı.
- Önemli her şey ortadaki **1080×1440** alanda olsun (y = 240–1680). Instagram ve TikTok profil ızgarası görseli 3:4 kırpar.
- Kapağı ayrıca `04_Kapaklar`'a kaydet (Instagram'a ayrı yüklenecek).

### 3.7 Export
- **1080p · 30 fps · H.264 · bit hızı "Önerilen/Yüksek"** · watermark kapalı.
- **Trend ses kullanılacaksa:** CapCut'ta müziği **ekleme**. Ritim için beat'i referans alıp kurgula, export'u sessiz yap; sesi TikTok/Instagram içinde ekle (Bölüm 4).
- **Seslendirmeli video:** seslendirme + arka müzik (CapCut kütüphanesi, %15–20) dahil export.
- Kaydet: `03_Kurgu_Export/2026-11-20_V02_emma_final.mp4`

### KAPI 3
- [ ] İlk kare sonucu gösteriyor, hook 0. saniyede
- [ ] Yazılar güvenli alanda (x 60–940, y 250–1600)
- [ ] Yazım hatası yok, Amerikan İngilizcesi
- [ ] Süre formata uygun
- [ ] Kapak 3:4 güvenli alanına göre hazır
- [ ] 1080p/30 fps export, watermark yok

---

## 4. Ses (paylaşmadan 10 dk önce)

1. **TikTok Creative Center** → Trends → **Songs** → Ülke **United States** → **7 gün** → **Breakout**.
2. Brief'teki **ses tipine** (S1–S9) uyan bir Breakout sesi seç. Yoksa takvimdeki **yedek sesi** kullan.
3. Sesin **ticari kullanım** durumunu kontrol et: kişisel hesapta olur. Business hesaba geçince yalnızca Commercial Music Library sesleri kullanılabilir.
4. Ses seviyesi:
   - Sadece müzik: müzik %100, video sesi %0
   - Seslendirme + müzik: seslendirme %100, müzik **%10–20**
5. Beat drop videosunda: sesin **drop anını** videodaki ilk dönüşüm karesine hizala (TikTok'ta "Sesi kırp/Trim" ile başlangıç noktasını ayarla).
6. Instagram'da aynı sesi Reels kütüphanesinde ara. "Trending ↗" olanı seç. Yoksa aynı tipte başka bir trend ses.

### KAPI 4
- [ ] Ses ABD Breakout listesinden ya da yedek listeden
- [ ] Drop/beat ilk dönüşümle hizalı
- [ ] Seslendirme anlaşılır, müzik bastırmıyor

---

## 5. Metin: açıklama, hashtag, sabit yorum

### 5.1 Açıklama formülü
```
[1. cümle: anahtar kelime + kanca]  [emoji]  [CTA]
[3–5 hashtag]
```
- **İlk 100 karakter kritik:** Instagram yaklaşık 125, TikTok ekranda yaklaşık 2 satır gösterir.
- Anahtar kelime **düz metin** olarak ilk cümlede geçsin (aramalar açıklamayı indeksliyor).
- Uygulama adı: `App: SpookyAI` veya `Made with SpookyAI`.
- Karakter adı kullan: `Emma in 5 Christmas styles`. **"my selfie" deme**; görseller yapay zekâ ile üretildi.
- Takvim kataloğunda hazır metin varsa onu kullan; yalnızca karakter adını uyarla.

### 5.2 Hashtag kuralı (3–5 adet)
| Sıra | Tip | Örnek |
|---|---|---|
| 1 | Geniş | `#aiphoto` `#aiportrait` |
| 2 | Niş | `#christmaspfp` `#christmasphotoideas` |
| 3 | Sezon/kitle | `#christmas2026` `#catsoftiktok` |
| 4 | Marka (her zaman) | `#spookyai` |

**Kullanma:** `#fyp` `#foryou` `#viral` (artık katkısı yok), Türkçe hashtag, 10'dan fazla hashtag.

### 5.3 Sabit (pinned) yorum
Paylaşır paylaşmaz kendi hesabınla yorum yaz ve **sabitle**:
```
App: SpookyAI 🎄 on the App Store & Google Play (link in bio)
```
Oylama videolarında:
```
Vote below 👇 most voted style gets a new video tomorrow
```

### 5.4 Hazır cevaplar (kopyala)
| Yorum | Cevap |
|---|---|
| What app? | `SpookyAI 🎄 link in bio / search SpookyAI on the App Store` |
| Prompt? | `It's a built-in style in the app ✨ (Frost Queen)`. **Prompt metnini asla paylaşma** |
| Is it free? | `Free to try ✨` (yalnızca gerçekse; token/abonelik detayına girme) |
| Is she real? | `Emma is an AI character we created for our styles ✨` (dürüst ol) |
| Do mine! | `Send us a DM 💌` (fotoğraf kullanmadan önce DM'de yazılı izin al) |
| AI art is fake/theft | Kısa ve nazik bir cevap ver ya da gizle: `Totally get it, we just think it's fun for seasonal photos 🎄`. Tartışmaya girme |

### KAPI 5
- [ ] Anahtar kelime ilk cümlede
- [ ] "my selfie / my cat" yok, karakter adı var
- [ ] 3–5 hashtag, `#spookyai` dahil, Türkçe yok
- [ ] Sabit yorum metni hazır
- [ ] Fiyat/indirim iddiası yok (yalnızca gerçek ve mevcut kampanya)

---

## 6. Yayın öncesi kalite kontrol (QA, 3 dk)

Videoyu telefonda **sessiz ve sesli birer kez** baştan sona izle.

**İçerik**
- [ ] İlk 1 saniyede "neden izlemeliyim?" sorusunun cevabı var
- [ ] Hook okunuyor, yazılar arayüzün altında kalmıyor
- [ ] Yüz tutarlılığı: karakter tanınıyor
- [ ] Bozuk el, yazı veya yüz yok
- [ ] Son kare yeterince uzun

**Uyum ve güvenlik**
- [ ] Gerçek kişi, ünlü, 18 yaş altı görünümlü kişi **yok**
- [ ] Marka logosu veya telifli karakter adı **yok**
- [ ] Yanıltıcı iddia yok ("1M users", "100% free" gibi; gerçek değilse)
- [ ] Uygulamanın stil kütüphanesindeki prompt metni hiçbir yerde görünmüyor

**Teknik**
- [ ] 1080×1920, 30 fps, watermark yok
- [ ] Kapak hazır, 3:4 alanına uygun
- [ ] Açıklama ve sabit yorum panoda

### KAPI 6
- [ ] Bütün QA maddeleri işaretli. **Bir madde bile işaretli değilse yayınlama.**

---

## 7. Yükleme

### 7.1 TikTok
1. **+** → Yükle → `03_Kurgu_Export`'tan videoyu seç.
2. **Ses ekle** (trend ses kullanılıyorsa) → sesi seç → **drop noktasını kırp** → video sesi %0 (ya da seslendirme için %100, müzik %10–20).
3. **Ekran yazısı** CapCut'ta eklendiyse TikTok'ta ayrıca ekleme. Gerekirse küçük düzeltme yap.
4. Sonraki → **Kapak seç** → kapak karesini seç, gerekirse kapak yazısı ekle.
5. **Açıklama:** panodan yapıştır.
6. **Konum: EKLEME.**
7. **Diğer seçenekler:**
   | Ayar | Değer |
   |---|---|
   | Bu videoyu kim izleyebilir | **Herkes** |
   | Yorumlara izin ver | Açık |
   | Düet / Stitch | Açık |
   | **AI-generated content** | **AÇIK** (zorunlu) |
   | İçeriği açıkla (Disclose post content) | Uygulamayı doğrudan tanıtan videolarda (nasıl yapılır, CTA ağırlıklı) **Your brand** seçeneğini aç. Influencer işbirliğinde **Branded content** |
   | Yüksek kalitede yükle | Açık |
   | Taslak olarak cihazına kaydet | Kapalı |
8. **Zamanlanmış video (slot B, 03:30):** TikTok Studio (web) → Yükle → **Schedule** → tarih/saat. Kütüphaneden trend ses eklenemeyebilir; bu slotta yalnızca sesi içinde olan videolar.
9. **Paylaş.** Paylaşım saatini metrik tablosuna yaz.

### 7.2 Instagram Reels
1. **+** → Reel → videoyu seç.
2. **Ses:** "Ses ekle" → trend ses → başlangıç noktasını ayarla. Seslendirmeli videoda orijinal ses + müzik %10–20.
3. Sonraki → **Kapağı düzenle** → `04_Kapaklar`'dan **film rulosundan ekle**. Profil ızgarası önizlemesini (3:4) kontrol et.
4. **Açıklama:** panodan yapıştır.
5. **Konum: EKLEME.**
6. **Kişileri etiketle:** yalnızca Collab/influencer işbirliğinde.
7. **Gelişmiş ayarlar:**
   | Ayar | Değer |
   |---|---|
   | **AI etiketi ekle** | **AÇIK** |
   | Facebook'ta paylaş | Kapalı |
   | Otomatik altyazı | Açık (seslendirmeli videolarda) |
   | Beğeni sayılarını gizle | Kapalı |
   | Yorumları kapat | Kapalı |
   | **Trial reel** | Takipçilerin çoğu Türkiye'dense **açık** (video önce takipçi olmayanlara gösterilir) |
   | Paid partnership | Yalnızca ücretli influencer işbirliğinde |
8. **Paylaş** veya **zamanla** (Gelişmiş ayarlar → Zamanla).

### 7.3 Carousel / Photo Mode
- **TikTok Photo Mode:** + → Yükle → **Fotoğraf** sekmesi → 6–10 görsel (1080×1920 veya 1080×1440) → başlık alanına anahtar kelimeli kısa başlık (`10 Christmas photo ideas`) → açıklama → ses.
- **Instagram Carousel:** + → Gönderi → çoklu seç → oran **4:5 (1080×1350)** → kapak ilk kart → son kart CTA → açıklama → müzik ekle (isteğe bağlı) → AI etiketi.

### KAPI 7
- [ ] AI etiketi açık (iki platform)
- [ ] Konum eklenmedi
- [ ] Kapak doğru
- [ ] Ses başlangıç noktası doğru
- [ ] Açıklama ve hashtag'ler eksiksiz

---

## 8. Yayından sonraki ilk 60 dakika (algoritma için en kritik süre)

| Dakika | İş |
|---|---|
| **0** | Sabit yorumu yaz ve **sabitle** (5.3) |
| **0–60** | Her yoruma **İngilizce** cevap ver (ilk 30 yoruma 5 dk içinde). Soru soran cevaplar yaz: "Which one would you pick?" |
| **0–60** | En iyi 1–2 yorumu not et → yarın için **video ile cevap** (V19) |
| **60** | Instagram: Reel'i **Story'de paylaş** + anket/emoji kaydırıcı sticker |
| **60** | TikTok: ilk 1 saatin izlenmesini tabloya yaz |

**Yapma:**
- Türk arkadaşlarından beğeni veya paylaşım isteme; video Türkiye'ye kilitlenir.
- Kişisel hesabınla etkileşim yapma.
- İlk saatte videoyu silip yeniden yükleme.
- Türkçe yorumlara Türkçe cevap verme (kısa İngilizce bir cevap ya da sadece beğeni yeterli).

---

## 9. Ölçüm

### 9.1 Metrik tablosu sütunları
```
Tarih | Saat (TR) | Platform | Kod | Format | Karakter | Stil | Hook | Ses |
Süre | 1 saat izlenme | 24 saat izlenme | Ort. izlenme süresi | Tamamlanma % |
Beğeni | Yorum | Paylaşım | Kaydetme | Profil ziyareti | Takipçi kazanımı |
ABD % | Not
```

### 9.2 Kontrol noktaları
| Zaman | Bak | Karar |
|---|---|---|
| **1 saat** | İzlenme, ilk yorumlar | Ortalamanın 2 katıysa: aynı formatta 2 yeni video hazırla |
| **24 saat** | İzlenme, tamamlanma %, ABD % | Tamamlanma %50'nin altındaysa: bir sonraki videoda hook'u ve ilk kareyi değiştir |
| **72 saat** | Toplam performans, takipçi kazanımı | Instagram'a taşınacak mı? (TikTok'ta ortalamanın üstündeyse 2–3 gün sonra Reels'e) |
| **Pazar** | Haftalık analiz (takvim dosyası, Bölüm 5) | K1/K2 kazanan formatları seç |

### 9.3 Hedef değerler (ilk 6 hafta)
| Metrik | Zayıf | İyi | Çok iyi |
|---|---|---|---|
| Tamamlanma (≤12 sn video) | <%40 | %50–70 | >%70 |
| Ortalama izlenme süresi | <%50 | %60–90 | >%100 (döngü) |
| Paylaşım / izlenme | <%0,3 | %0,5–1 | >%1 |
| Kaydetme / izlenme (carousel) | <%1 | %2–4 | >%4 |
| ABD izleyici oranı | <%20 | %30–50 | >%50 |

---

## Ek A — Tek sayfa hızlı kontrol listesi (yazdır)

```
□ Brief kartı dolu (kod, format, karakter, stil, hook ≤8 kelime, ilk kare, ses tipi, CTA, anahtar kelime)
□ Master fotoğraf kullanıldı, "Keep the same face" ek açıklaması var
□ Her stilde en az 2 üretim, en iyisi seçildi, 7 seçim kontrolü geçti
□ 2048 px'e büyütüldü
□ CapCut 1080×1920/30 fps, kare görsel ortada, arka plan blur
□ İlk kare = sonuç, hook 0. sn'de ve ≥1,5 sn
□ Yazılar güvenli alanda, Amerikan İngilizcesi, yazım hatası yok
□ Kapak 1080×1920, önemli kısım ortadaki 3:4 alanda
□ Export: 1080p, watermark yok (trend ses varsa sessiz export)
□ Ses: ABD Breakout ya da yedek; drop hizalı
□ Açıklama: anahtar kelime ilk cümlede, karakter adı, 3–5 hashtag + #spookyai
□ QA: gerçek kişi/ünlü/logo/çocuk yok, yanıltıcı iddia yok, kütüphane promptu yok
□ Yükleme: AI etiketi AÇIK, konum YOK, doğru kapak, doğru saat
□ 0. dk sabit yorum · 60 dk yorumlara cevap · 60. dk Story
□ 1 saat / 24 saat / 72 saat metrikleri tabloya yazıldı
```

## Ek B — Asla yapma

1. Gerçek kişinin (ünlü, arkadaş, takipçi) fotoğrafını **izinsiz** kullanmak.
2. Pinterest veya başka yerden alınmış görselleri temel fotoğraf yapmak.
3. AI karakteri gerçek kişi gibi sunmak ("my selfie", "me").
4. Uygulamanın stil kütüphanesindeki prompt metnini paylaşmak.
5. Takipçi, beğeni veya izlenme satın almak.
6. VPN ile konum değiştirmek.
7. TikTok watermark'lı videoyu Instagram'a yüklemek.
8. Türkçe içerik, Türkçe hashtag veya Türkiye konumu kullanmak (ana hesapta).
9. Fiyat, indirim ya da kullanıcı sayısı hakkında doğrulanmamış iddia.
10. Bir videoyu ilk 24 saat içinde silmek (kötü gitse bile).
