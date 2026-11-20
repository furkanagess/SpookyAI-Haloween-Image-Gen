# SpookyAI — Sabit Karakterler ve Üretim Promptları

> Bu promptlar **sosyal medya içeriği** içindir. Hepsi sıfırdan yazıldı,
> uygulamanın stil kütüphanesindeki promptlarla ilgisi yok. Kütüphane
> promptlarını hiçbir yerde paylaşma.
>
> Takvim: [PAYLASIM_TAKVIMI_DETAYLI.md](PAYLASIM_TAKVIMI_DETAYLI.md)

## 0. Uygulama nasıl üretiyor? (promptları buna göre yazdım)

- Text ve image modları **512×512, kare, orta kalite** çıktı veriyor. Image
  modunun modeli bir düzenleme (edit) modeli; düz cümlelerle yazılmış net
  talimatları iyi anlıyor.
- Uygulama, kullanıcının yazdığı **ek açıklamayı** hazır stilin önüne koyuyor
  ve ona öncelik veriyor. Bu yüzden ek açıklamalar **kısa ve stille çelişmeyen**
  olmalı: saç, renk, aksesuar, ışık. Stilin sahnesini baştan değiştirmeye
  çalışma.
- Çıktıyı her zaman **Upscayl 4× → 2048×2048** büyüt (takvim dosyası, 1.4).

### Master fotoğraf kuralları (bütün karakterler için)
1. Her karakterin **tek** bir master fotoğrafı olur. Bütün stiller bu fotoğrafa uygulanır.
2. Her karakter için 4–6 deneme üret. Şu ölçütlerle seç:
   - Yüz simetrik ama **kusursuz değil** (cilt dokusu, hafif çil, doğal ten).
   - Eller kadrajda değil (yapay zekâ ellerde en çok hata yapar).
   - Arka plan sade ve odak dışı.
   - Gözler kameraya bakıyor, ifade nötr veya hafif gülümseme.
3. Master'ı **`master_emma.jpg`** gibi adlandır ve bir "Karakterler" albümüne kaydet.
4. Bir master'ı kesinleştirdikten sonra **değiştirme**. İzleyici o yüzü tanıyacak.

### Prompt yapısı (master için)
```
[çekim tipi] + [kişi: yaş, köken, saç, göz, ten, ayırt edici detay] +
[kıyafet] + [kadraj ve poz] + [ışık] + [arka plan] + [kamera/kalite] +
[istenmeyenler]
```

---

## 1. Emma: ana karakter

**Rol:** kraliçe ve glam stiller, saç rengi serisi, pfp videoları, hikâye anlatıcısı.
**Sabit özellikler (onaylı master'a göre):** 25 yaş · uzun, dalgalı, koyu kahve saç, yüzüne düşen perçemler · **kahve/ela göz** · belirgin kaşlar · hafif çil · açık ten · gri sweatshirt (lacivert şeritli) · sıcak, kapalı dudaklı gülümseme
**Master:** `assets/images/characters/emma/emma.jpg` · Alternatifler: `emma_smile.png` (gülerken), `emma_cozy.png` (kanepe + kupa)

> Aşağıdaki prompt ilk üretim içindi. Master onaylandı, Emma'yı bir daha sıfırdan üretme.

**Master prompt (text modu):**
```
A casual smartphone photo of a 25-year-old American woman with long, loose, wavy medium-brown hair falling past her shoulders, green eyes, light natural freckles across her nose and cheeks, and fair to medium skin with visible natural skin texture. She is wearing a plain oatmeal-colored knit sweater. Chest-up portrait, facing the camera directly, head slightly tilted, soft natural smile with closed lips. Soft daylight from a window on the left, gentle shadows on the right side of her face. Plain, slightly blurred living room background with a beige wall and a hint of a green plant. Realistic amateur phone camera photo, slight grain, true-to-life colors, centered composition, square format. No makeup look, no jewelry, no glasses, no hands in frame, no text.
```

**Alternatif pozlar (image modu, master'ın üzerine):**
```
Keep the exact same woman, same face, same hair and freckles. Change only the pose: she is laughing naturally and looking slightly off-camera to the right. Same lighting and background.
```
```
Keep the exact same woman, same face and hair. She is now sitting on a light grey couch holding a white mug at chest height, cozy evening lamp light, realistic phone photo, square format.
```

---

## 2. Maya: oylama ve pfp yüzü

**Master:** `assets/images/characters/maya/maya.jpg` ✅

**Sabit özellikler:** 24 yaş · Siyahi Amerikalı · omuz hizasında doğal kıvırcık saç (3C–4A) · koyu kahve göz · parlak, geniş gülüşü · küçük altın halka küpe (tek aksesuarı)

**Master prompt:**
```
A casual smartphone photo of a 24-year-old Black American woman with shoulder-length natural curly hair with defined 3C curls, warm dark brown eyes, deep brown skin with natural texture and a healthy glow, and a bright, wide smile showing teeth. She wears small gold hoop earrings and a simple white crew-neck t-shirt. Chest-up portrait, facing the camera, shoulders slightly angled. Bright natural daylight from a large window in front of her, even soft light on her face. Plain, softly blurred bedroom background with a white wall and warm wooden furniture. Realistic phone camera photo, natural colors, centered composition, square format. No heavy makeup, no glasses, no hands in frame, no text.
```

**Alternatif poz:**
```
Keep the exact same woman, same face, curls and earrings. She is now giving a playful side glance to the camera with a half smile, same light, same background.
```

---

## 3. Jake: erkek karakter

**Master:** `assets/images/characters/jake/jake.jpg` ✅

**Sabit özellikler:** 28 yaş · kısa, yanları kısa koyu sarı saç · açık sakal · mavi göz · güçlü çene · rahat, esprili ifade

**Master prompt:**
```
A casual smartphone photo of a 28-year-old American man with short dark-blond hair, shorter on the sides and slightly tousled on top, light stubble, blue eyes, a defined jawline, and fair skin with natural texture. He wears a plain heather-grey crew-neck t-shirt. Chest-up portrait, facing the camera, relaxed friendly expression with a slight smirk. Natural daylight from a kitchen window on the right. Plain, softly blurred modern kitchen background with white cabinets. Realistic amateur phone photo, slight grain, true-to-life colors, centered composition, square format. No hat, no glasses, no jewelry, no hands in frame, no text.
```

---

## 4. Lily & Marco: çift

**Master:** `assets/images/characters/lilly-marco/lilly-marco.jpg` ✅

**Sabit özellikler:**
- **Lily:** 26 yaş · omuz boyu, düz, bal sarısı saç · ela göz · açık ten
- **Marco:** 27 yaş · Latin Amerika kökenli · kısa siyah saç · düzgün kısa sakal · kahve göz · buğday ten
- Her zaman **Lily solda, Marco sağda** (videolarda tutarlılık için)

**Master prompt:**
```
A casual smartphone photo of a young couple sitting close together on a light grey couch. On the left, Lily, a 26-year-old woman with straight, shoulder-length honey-blonde hair, hazel eyes and fair skin. On the right, Marco, a 27-year-old Latino man with short black hair, a neatly trimmed short beard, brown eyes and warm tan skin. She wears a cream knit sweater, he wears a navy henley shirt. Both are facing the camera, smiling naturally, her head slightly leaning toward his shoulder. Warm living room lamp light mixed with soft daylight. Plain, softly blurred background with a bookshelf. Realistic phone camera photo, natural skin texture, centered composition, square format. Both faces fully visible, no hands covering faces, no text.
```

**Tek kişilik versiyonlar** (oylama ve "who wore it better" videoları için):
```
Keep the exact same man from this photo, same face, hair and beard. Show only him, chest-up, facing the camera, same lighting, plain background, square format.
```
Aynı talimatı "same woman" ile Lily için tekrarla.

---

## 5. Mango: kedi

**Master:** `assets/images/characters/mango(cat)/mango.jpg` ✅

**Sabit özellikler:** turuncu tekir · kabarık tüy · kehribar göz · beyaz göğüs ve patiler · hafif "huysuz" yüz ifadesi (videolarda espri bunun üzerine kurulu)

**Master prompt:**
```
A casual smartphone photo of a fluffy orange tabby cat with clear tabby stripes, a white chest and white paws, and large amber eyes. The cat sits upright on a light grey couch cushion, looking directly at the camera with a slightly grumpy, unimpressed expression. Soft natural daylight from a window. Softly blurred living room background. Realistic pet photo taken with a phone, detailed fur texture, true-to-life colors, centered composition, square format. No collar, no text.
```

**"Kızgın" tepki karesi** (videonun son karesi için, image modunda):
```
Keep the exact same cat, same fur pattern and eyes. Now the cat has flattened ears and narrowed eyes, looking annoyed straight at the camera. Same couch, same lighting.
```

---

## 6. Biscuit: köpek

**Master:** `assets/images/characters/biscuit(dog)/biscuit.jpg` ✅

**Sabit özellikler:** golden retriever · açık altın tüy · kırmızı tasma · dili dışarıda, mutlu ifade

**Master prompt:**
```
A casual smartphone photo of a happy golden retriever with a light golden coat and a red fabric collar, sitting on a warm wooden floor, looking up at the camera with its tongue out and a friendly expression. Soft natural daylight. Softly blurred living room background with a beige rug. Realistic phone pet photo, detailed fur, natural colors, centered composition, square format. No text.
```

---

## 7. Stil üzerine ek açıklamalar (image modu → hazır stil + "ek açıklama" alanı)

**Kural:** Ek açıklama **tek cümle, en fazla ~20 kelime.** Her zaman
`Keep the same face` ile başlasın. Yüz kimliği böyle korunur.

### 7.1 Kimlik koruyucu temel (her stile eklenebilir)
```
Keep the same face, eye color and facial features as the photo.
```

### 7.2 Saç rengi serisi (V12–V16): Emma + Frost Queen
```
V12: Keep the same face; change her hair to long, glossy platinum-blonde waves.
V13: Keep the same face; keep her long dark-brown waves, add frosted silver tips.
V14: Keep the same face; change her hair to voluminous curly copper-red hair.
V15: Keep the same face; change her hair to sleek jet-black hair in a high ponytail.
V16: Keep the same face; change her hair to a short silver pixie cut.
```

### 7.3 Çift videoları (V09, V26, V27, V30): Lily & Marco
```
Keep both faces exactly the same; Lily on the left, Marco on the right.
```
```
Keep both faces; matching red and green Christmas sweaters, both laughing.
```

### 7.4 Evcil hayvan (V04, V17)
```
Mango + Fireside Cat: Keep the same orange tabby markings and amber eyes; grumpy expression.
Mango + Jolly Santa: Keep the same cat markings; tiny Santa hat, unimpressed face.
Biscuit + Jolly Santa: Keep the same golden retriever and red collar; joyful, tongue out.
Biscuit + Workshop Elf: Keep the same dog; small green elf hat with a bell.
```

### 7.5 Yılbaşı (V31): Emma, Maya + Winter Royalty
```
Keep the same face; gold sequin outfit, gold confetti in the air, party lights.
Keep the same face and curls; silver sequin dress, champagne glow, New Year's Eve lights.
```

### 7.6 ABD dokunuşu (isteğe bağlı, her Noel stiline)
```
Keep the same face; cozy American suburban house with Christmas lights in background.
Keep the same face; snowy New York street with a giant Christmas tree behind.
```

---

## 8. Video modu hareket talimatları (detaylı)

**Kural:** **Tek ana hareket + tek kamera hareketi + bir atmosfer öğesi.**
Hareket çok olursa yüz bozulur. Videonun "kimliği koru" cümlesiyle bitmesi önemli.

| Video | Talimat |
|---|---|
| V06 Cabin Window (Emma) | `Gentle snowfall outside the window, she slowly blinks and breaks into a soft smile, camera slowly pushes in. Keep her face unchanged.` |
| V20 Snow Globe (Emma) | `Snow swirls slowly inside the globe, she looks up at the falling snow and smiles, camera slowly orbits a little to the right. Keep her face unchanged.` |
| V24 Ice Queen (Maya) | `Her hair and cape move in a cold wind, frost slowly spreads across the background, she turns her head toward the camera. Keep her face unchanged.` |
| V26 Rink Skater (Lily & Marco) | `The couple glides slowly forward holding hands, light snow falls, camera tracks backward with them. Keep both faces unchanged.` |
| V27 Sleigh Ride (Lily & Marco) | `The sleigh moves forward through a snowy forest, scarves flutter in the wind, she laughs and leans on his shoulder. Keep both faces unchanged.` |
| V30 Christmas Morning (Lily & Marco) | `Soft morning light, she opens a small gift box and they both laugh, snow falls outside the window, static camera. Keep both faces unchanged.` |
| V04 Mango (son kare) | `The cat slowly flattens its ears and squints at the camera, candle light flickers, static camera.` |
| V17 Biscuit | `The dog tilts its head and wags its tail, the bell on its hat jingles, light snow falls, camera slowly pushes in.` |

---

## 9. Yüz göstermeyen text-to-image promptları (V21 ve atmosfer serileri)

Uygulama kare üretiyor. Bu yüzden promptlarda `vertical` değil **`square
composition, subject centered`** kullan. Kare görsel dikey videonun ortasına yerleşir.

```
A snowy New York City avenue at blue hour with a giant decorated Christmas tree glowing at the end of the street, yellow taxis with light trails, warm shop window lights reflecting on wet pavement, light snowfall, cinematic photography, rich warm and cool contrast, square composition, subject centered.
```
```
A cozy Chicago residential street in heavy snow, red brick two-flat buildings with string lights on every porch, a lone person in a red coat walking away, soft orange streetlights, cinematic photography, square composition, subject centered.
```
```
A Boston brownstone street in gentle snowfall, a green wreath with a red bow on every black front door, gas lamps glowing, quiet early evening, cinematic photography, square composition, subject centered.
```
```
A Seattle waterfront Christmas market at dusk in light drizzle, wooden stalls with fairy lights, steam rising from hot cider cups, the Ferris wheel blurred in the background, cinematic photography, square composition, subject centered.
```
```
A New Orleans French Quarter street at night, wrought-iron balconies wrapped in Christmas garlands and warm lanterns, wet cobblestones reflecting the lights, cinematic photography, square composition, subject centered.
```

---

## 10. Hızlı kontrol: üretilen görsel kullanılabilir mi?

- [ ] Yüz master'la aynı kişi mi? (Gözler, burun, çene. Şüphen varsa kullanma)
- [ ] Eller ve parmaklar normal mi? Değilse kadrajı kırp ya da yeniden üret
- [ ] Görselde yazı veya logo bozukluğu var mı?
- [ ] Büyütüldü mü (2048×2048)?
- [ ] Gerçek bir kişiye, ünlüye ya da markaya benziyor mu? Benziyorsa kullanma
