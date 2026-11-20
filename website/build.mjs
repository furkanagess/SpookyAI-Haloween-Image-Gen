// Generates the static SpookyAI site into website/public (no dependencies).
//   node website/build.mjs
// Pages: / (EN), /tr/ (TR), /privacy/, /terms/, /get/ (device-aware store redirect).
// Rule: library prompt text is never published here; only images and style names.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const OUT = join(HERE, 'public');
const BASE = 'https://spookyai-app.web.app';
const PLAY = 'https://play.google.com/store/apps/details?id=com.furkanages.spookyai';
const APPSTORE = 'https://apps.apple.com/app/id6753217831';
const EMAIL = 'spookyaihelp@gmail.com';
const V = createHash('sha1').update(['styles.css', 'app.js'].map((f) => readFileSync(join(HERE, 'public', f))).join('')).digest('hex').slice(0, 8); // cache-buster

const HALLOWEEN = [
  ['enchantedd_witch', 'Enchanted Witch'], ['pumpkin_king', 'Pumpkin King'], ['haunted_carnival', 'Haunted Carnival'],
  ['spectral_ghost', 'Spectral Ghost'], ['raven_queen', 'Raven Queen'], ['werewolf', 'Werewolf'],
  ['gothic_ball', 'Gothic Ball'], ['fortune_teller', 'Fortune Teller'], ['ghost_bride', 'Ghost Bride'],
  ['golden_pumpkin', 'Golden Pumpkin'], ['skeleton_musician', 'Skeleton Musician'], ['mirror_ghost', 'Mirror Ghost'],
  ['crimson_vampire', 'Crimson Vampire'], ['moonlit_graveyard', 'Moonlit Graveyard'], ['apothercy_witch', 'Apothecary Witch'],
  ['friendly_ghosty', 'Friendly Ghost'], ['haunted_mansion_portrait', 'Haunted Portrait'], ['jacko_lantern', "Jack-o'-Lantern"],
];
const CHRISTMAS = [
  ['ice_queen', 'Ice Queen'], ['jolly_santa', 'Jolly Santa'], ['frost_dragon', 'Frost Dragon'],
  ['sleigh_ride', 'Sleigh Ride'], ['cabin_window', 'Cabin Window'], ['nutcracker', 'Nutcracker'],
  ['reindeer', 'Reindeer'], ['gingerbread_baker', 'Gingerbread Baker'], ['skater', 'Ice Skater'],
  ['santa_workshop', "Santa's Workshop"], ['winter_angel', 'Winter Angel'], ['carolers', 'Carolers'],
  ['gingerbread_village', 'Gingerbread Village'], ['christmas_morning', 'Christmas Morning'], ['winter_market', 'Winter Market'],
  ['lantern_snowman', 'Lantern Snowman'], ['fireside_cat', 'Fireside Cat'], ['vintage_christmas_card', 'Vintage Card'],
];
const TRENDS = [
  ['film_flash', '90s Film Flash'], ['collector', 'Action Figure Box'], ['snow_globe', 'Inside a Snow Globe'],
  ['chibi', 'Chibi Sticker'], ['mini_me', 'Desk Mini-Me'], ['pajama', 'Holiday Pajamas'], ['red_hood', 'Red Hood'],
];
const SCREENS = ['spookyai_ios_1', 'spookyai_ios_4', 'spookyai_ios_trends', 'spookyai_ios_5', 'spookyai_ios_2', 'spookyai_ios_3'];

const T = {
  en: {
    lang: 'en', locale: 'en_US', path: '/', other: { code: 'tr', path: '/tr/', label: 'Türkçe' },
    title: 'SpookyAI – AI Photo & Art Maker for Every Season',
    desc: 'Turn a selfie into a vampire, an ice queen or a viral trend. Create AI art from text and bring photos to life as video. Free on iPhone and Android.',
    nav: { gallery: 'Gallery', faq: 'FAQ', get: 'Get the app' },
    heroKicker: 'AI photo & art maker',
    heroTitle: ['Your selfie,', 'any season.'],
    heroSub: 'One photo becomes a vampire, a winter royal or this week’s viral trend. Type an idea, get art. Tap once, watch it move.',
    dl: { as1: 'Download on the', as2: 'App Store', gp1: 'Get it on', gp2: 'Google Play' },
    free: 'Free on iPhone, iPad and Android',
    qr: 'Scan to download', qrSub: 'Your phone opens the right store.',
    seasonLabel: 'Season', halloween: 'Halloween', christmas: 'Christmas',
    scroll: 'Scroll to explore',
    chips: ['Selfie to art', 'Text to image', 'Photo to video', 'Viral trends', 'Halloween', 'Christmas', 'New styles every season', 'One-tap styles'],
    baKicker: 'Before / after', baTitle: 'Drag the line. Meet the other you.',
    baSub: 'A real selfie on the left, real SpookyAI results on the right. Same face, new world.',
    baBefore: 'Your selfie', baTabs: ['Vampire Noble', 'Winter Royal'],
    vidKicker: 'Photo to video', vidTitle: 'Stills that breathe.',
    vidSub: 'Pick a photo and SpookyAI turns it into a short living clip, ready to share.',
    vidPhoto: 'Photo', vidVideo: 'Video',
    trendKicker: 'Trending now', trendTitle: 'One selfie. Every trend.',
    trendSub: 'Action figure boxes, snow globes, 90s film flash: the looks everyone is posting, ready for your photo in one tap.',
    galKicker: 'Made with SpookyAI', galTitle: 'A new world every season.',
    galSub: 'Spooky in October, cozy in December. Styles change with the calendar.',
    screensKicker: 'Inside the app', screensTitle: 'Take a closer look.',
    faqKicker: 'FAQ', faqTitle: 'Questions, answered.',
    faq: [
      ['Is SpookyAI free?', 'The app is free to download and new installs get starter tokens to try it. Each creation uses tokens; you can get more in the app.'],
      ['What happens to my photos?', 'Photos are sent securely to our AI provider only to create the result you asked for. Your results are saved on your device. See the privacy policy for details.'],
      ['Which devices are supported?', 'iPhone and iPad from the App Store, and Android phones from Google Play.'],
      ['Do I need ideas or prompts?', 'No. Pick a ready-made style or a trend and tap once. You can also type your own idea.'],
    ],
    ctaTitle: ['Your next look', 'is one tap away.'], ctaSub: 'Download free and create your first image in seconds.',
    footer: { privacy: 'Privacy Policy', terms: 'Terms of Use', contact: 'Contact', rights: 'All rights reserved.' },
    switchHint: 'Bu sayfayı Türkçe görüntüle', legalNote: '',
  },
  tr: {
    lang: 'tr', locale: 'tr_TR', path: '/tr/', other: { code: 'en', path: '/', label: 'English' },
    title: 'SpookyAI – Her Sezon İçin Yapay Zekâ Fotoğraf ve Sanat Uygulaması',
    desc: 'Selfie’ni vampire, buz kraliçesine ya da viral bir trende dönüştür. Yazıdan görsel üret, fotoğraflarını videoya çevir. iPhone ve Android’de ücretsiz.',
    nav: { gallery: 'Galeri', faq: 'SSS', get: 'Uygulamayı indir' },
    heroKicker: 'Yapay zekâ fotoğraf ve sanat',
    heroTitle: ['Selfie’n,', 'her sezonda.'],
    heroSub: 'Tek fotoğraf; vampir, kış kraliyeti ya da bu haftanın viral trendi olur. Bir fikir yaz, görsel gelsin. Tek dokunuşla hareketlensin.',
    dl: { as1: 'Şuradan indir', as2: 'App Store', gp1: 'Şuradan edin', gp2: 'Google Play' },
    free: 'iPhone, iPad ve Android’de ücretsiz',
    qr: 'İndirmek için tara', qrSub: 'Telefonun doğru mağazayı açar.',
    seasonLabel: 'Sezon', halloween: 'Cadılar Bayramı', christmas: 'Yılbaşı',
    scroll: 'Keşfetmek için kaydır',
    chips: ['Selfie’den sanata', 'Yazıdan görsel', 'Fotoğraftan video', 'Viral trendler', 'Cadılar Bayramı', 'Yılbaşı', 'Her sezon yeni stiller', 'Tek dokunuşla stil'],
    baKicker: 'Önce / sonra', baTitle: 'Çizgiyi kaydır. Öteki seninle tanış.',
    baSub: 'Solda gerçek bir selfie, sağda gerçek SpookyAI sonuçları. Aynı yüz, yeni bir dünya.',
    baBefore: 'Senin selfie’n', baTabs: ['Vampir Asilzade', 'Kış Kraliyeti'],
    vidKicker: 'Fotoğraftan video', vidTitle: 'Nefes alan kareler.',
    vidSub: 'Bir fotoğraf seç; SpookyAI onu paylaşmaya hazır, kısa ve canlı bir klibe dönüştürsün.',
    vidPhoto: 'Fotoğraf', vidVideo: 'Video',
    trendKicker: 'Şu an trend', trendTitle: 'Tek selfie. Bütün trendler.',
    trendSub: 'Aksiyon figürü kutusu, kar küresi, 90’lar flaş filmi: herkesin paylaştığı görünümler tek dokunuşla senin fotoğrafında.',
    galKicker: 'SpookyAI ile üretildi', galTitle: 'Her sezon yeni bir dünya.',
    galSub: 'Ekimde ürpertici, aralıkta sıcacık. Stiller takvimle birlikte değişir.',
    screensKicker: 'Uygulamadan', screensTitle: 'Uygulamayı yakından gör.',
    faqKicker: 'SSS', faqTitle: 'Merak edilenler.',
    faq: [
      ['SpookyAI ücretsiz mi?', 'Uygulamayı indirmek ücretsiz; yeni kurulumlar denemek için başlangıç jetonu alır. Her üretim jeton kullanır, uygulama içinden daha fazlasını alabilirsin.'],
      ['Fotoğraflarıma ne oluyor?', 'Fotoğraflar yalnızca istediğin sonucu üretmek için yapay zekâ sağlayıcımıza güvenli şekilde gönderilir. Sonuçların cihazında saklanır. Ayrıntılar gizlilik politikasında.'],
      ['Hangi cihazlarda çalışıyor?', 'App Store’dan iPhone ve iPad, Google Play’den Android telefonlar.'],
      ['Fikir ya da prompt yazmam gerekiyor mu?', 'Hayır. Hazır bir stil ya da trend seç ve dokun. İstersen kendi fikrini de yazabilirsin.'],
    ],
    ctaTitle: ['Yeni görünümün', 'bir dokunuş uzağında.'], ctaSub: 'Ücretsiz indir, ilk görselini saniyeler içinde üret.',
    footer: { privacy: 'Gizlilik Politikası', terms: 'Kullanım Şartları', contact: 'İletişim', rights: 'Tüm hakları saklıdır.' },
    switchHint: 'View this page in English', legalNote: 'Bu belge İngilizcedir.',
  },
};

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const img = (src, alt, w, h, extra = '') =>
  `<img src="${src}" alt="${esc(alt)}" width="${w}" height="${h}" loading="lazy" decoding="async"${extra}>`;

const appleSvg = `<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M16.37 12.77c-.02-2.3 1.88-3.4 1.96-3.46-1.07-1.56-2.73-1.78-3.32-1.8-1.41-.14-2.76.83-3.48.83-.72 0-1.82-.81-3-.79-1.54.02-2.96.9-3.76 2.28-1.6 2.78-.41 6.9 1.15 9.16.76 1.1 1.67 2.34 2.86 2.3 1.15-.05 1.58-.74 2.97-.74 1.38 0 1.77.74 2.98.72 1.23-.02 2.01-1.12 2.76-2.23.87-1.28 1.23-2.52 1.25-2.58-.03-.01-2.4-.92-2.42-3.65zM14.1 6.02c.63-.77 1.06-1.83.94-2.89-.91.04-2.01.61-2.66 1.37-.58.67-1.1 1.76-.96 2.8 1.02.08 2.05-.52 2.68-1.28z"/></svg>`;
const playSvg = `<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#00d7fe" d="M3.6 2.2 13.3 12l-9.7 9.8c-.4-.2-.6-.6-.6-1.1V3.3c0-.5.2-.9.6-1.1z"/><path fill="#ffce00" d="m16.6 15.3-3.3-3.3 3.3-3.3 3.8 2.2c1.1.6 1.1 1.6 0 2.2l-3.8 2.2z"/><path fill="#ff3a44" d="M16.6 15.3 13.3 12l-9.7 9.8c.4.4 1 .4 1.6.1l11.4-6.6z"/><path fill="#00f076" d="M16.6 8.7 5.2 2.1c-.6-.4-1.2-.3-1.6.1l9.7 9.8 3.3-3.3z"/></svg>`;

function storeButtons(t, where) {
  return `<div class="stores" data-where="${where}">
  <a class="store store-ios" href="${APPSTORE}" rel="noopener" data-store="ios">${appleSvg}<span><small>${t.dl.as1}</small><b>${t.dl.as2}</b></span></a>
  <a class="store store-android" href="${PLAY}" rel="noopener" data-store="android">${playSvg}<span><small>${t.dl.gp1}</small><b>${t.dl.gp2}</b></span></a>
</div>`;
}

const pfx = (t) => (t.lang === 'en' ? '' : '../'); // relative path to site root

function landing(t) {
  const r = pfx(t);
  const m = `${r}media`;
  const heroCards = (set, items) => items.map(([n, label = ''], i) =>
    `<figure class="hcard hcard-${i + 1}" data-set="${set}">${img(`${m}/${set}/${n}.webp`, label, 420, 420, i < 2 ? ' fetchpriority="high" loading="eager"' : '')}</figure>`).join('');
  const row = (set, items) => {
    const cells = items.map(([n, label]) => `<figure class="tile">${img(`${m}/${set}/${n}.webp`, label, 420, 420)}<figcaption>${esc(label)}</figcaption></figure>`).join('');
    return `<div class="marquee-row" data-set="${set}"><div class="marquee-track">${cells}${cells.replace(/<figure class="tile">/g, '<figure class="tile" aria-hidden="true">')}</div></div>`;
  };
  const chips = t.chips.map((c) => `<span>${esc(c)}</span>`).join('');
  return `<!doctype html>
<html lang="${t.lang}" data-season="halloween" data-device="desktop">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(t.title)}</title>
<meta name="description" content="${esc(t.desc)}">
<link rel="canonical" href="${BASE}${t.path}">
<link rel="alternate" hreflang="en" href="${BASE}/">
<link rel="alternate" hreflang="tr" href="${BASE}/tr/">
<link rel="alternate" hreflang="x-default" href="${BASE}/">
<meta name="theme-color" content="#0f0b1a">
<meta name="apple-itunes-app" content="app-id=6753217831">
<meta property="og:type" content="website">
<meta property="og:site_name" content="SpookyAI">
<meta property="og:title" content="${esc(t.title)}">
<meta property="og:description" content="${esc(t.desc)}">
<meta property="og:url" content="${BASE}${t.path}">
<meta property="og:image" content="${BASE}/og-image.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="${t.locale}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(t.title)}">
<meta name="twitter:description" content="${esc(t.desc)}">
<meta name="twitter:image" content="${BASE}/og-image.jpg">
<link rel="icon" type="image/png" href="${r}favicon.png">
<link rel="apple-touch-icon" href="${r}apple-touch-icon.png">
<link rel="preload" as="image" href="${m}/icon.webp">
<link rel="stylesheet" href="${r}styles.css?v=${V}">
<script>/* set device + season before paint to avoid flicker */
(function(d){var u=navigator.userAgent,ios=/iPhone|iPad|iPod/.test(u)||(/Macintosh/.test(u)&&navigator.maxTouchPoints>1);
d.dataset.device=ios?'ios':/Android/i.test(u)?'android':'desktop';
var s;try{s=localStorage.getItem('season')}catch(e){}var mo=new Date().getMonth();
d.dataset.season=s||(mo>=10||mo===0?'christmas':'halloween');})(document.documentElement);</script>
<script type="application/ld+json">${JSON.stringify({
    '@context': 'https://schema.org', '@type': 'MobileApplication', name: 'SpookyAI', operatingSystem: 'iOS, Android',
    applicationCategory: 'PhotographyApplication', description: t.desc, image: `${BASE}/og-image.jpg`, url: `${BASE}${t.path}`,
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' }, sameAs: [APPSTORE, PLAY],
  })}</script>
<script type="application/ld+json">${JSON.stringify({
    '@context': 'https://schema.org', '@type': 'FAQPage',
    mainEntity: t.faq.map(([q, a]) => ({ '@type': 'Question', name: q, acceptedAnswer: { '@type': 'Answer', text: a } })),
  })}</script>
</head>
<body>
<canvas id="fx" aria-hidden="true"></canvas>
<div class="glow" aria-hidden="true"></div>

<header class="nav">
  <a class="brand" href="${r || './'}" aria-label="SpookyAI">
    <img class="brand-icon" src="${m}/icon.webp" alt="" width="36" height="36"><span>SpookyAI</span>
  </a>
  <nav class="nav-links">
    <a href="#gallery">${t.nav.gallery}</a><a href="#faq">${t.nav.faq}</a>
  </nav>
  <div class="nav-right">
    <a class="lang" href="${r}${t.other.path.slice(1)}" hreflang="${t.other.code}" lang="${t.other.code}" data-lang="${t.other.code}">${t.other.code.toUpperCase()}</a>
    <a class="btn-mini" href="#get">${t.nav.get}</a>
  </div>
</header>

<main>
<section class="hero">
  <div class="hero-copy">
    <div class="app-icon" aria-hidden="true">
      <img class="icon-h" src="${m}/icon.webp" alt="" width="128" height="128">
      <img class="icon-c" src="${m}/icon_christmas.webp" alt="" width="128" height="128">
    </div>
    <p class="kicker">${t.heroKicker}</p>
    <h1><span class="line">${t.heroTitle[0]}</span> <span class="line grad">${t.heroTitle[1]}</span></h1>
    <p class="lead">${t.heroSub}</p>
    ${storeButtons(t, 'hero')}
    <p class="fine">${t.free}</p>
    <div class="season-toggle" role="group" aria-label="${t.seasonLabel}">
      <button type="button" data-season-btn="halloween">🎃 ${t.halloween}</button>
      <button type="button" data-season-btn="christmas">❄️ ${t.christmas}</button>
    </div>
  </div>
  <div class="hero-art" aria-hidden="true">
    ${heroCards('halloween', [['pumpkin_king'], ['enchantedd_witch'], ['spectral_ghost'], ['raven_queen'], ['haunted_carnival']])}
    ${heroCards('christmas', [['ice_queen'], ['jolly_santa'], ['frost_dragon'], ['reindeer'], ['sleigh_ride']])}
  </div>
  <a class="scroll-cue" href="#compare">${t.scroll}<span></span></a>
</section>

<div class="chips" aria-hidden="true"><div class="chips-track">${chips}${chips}</div></div>

<section id="compare" class="section split reveal">
  <div class="copy">
    <p class="kicker">${t.baKicker}</p>
    <h2>${t.baTitle}</h2>
    <p class="lead">${t.baSub}</p>
    <div class="tabs" role="tablist">
      <button role="tab" aria-selected="true" data-after="${m}/compare/vampire.webp">🧛 ${t.baTabs[0]}</button>
      <button role="tab" aria-selected="false" data-after="${m}/compare/winter.webp">👑 ${t.baTabs[1]}</button>
    </div>
  </div>
  <div class="ba" style="--pos:50%">
    <img class="ba-after" src="${m}/compare/vampire.webp" alt="${esc(t.baTabs[0])}" width="600" height="750" loading="lazy">
    <div class="ba-before"><img src="${m}/compare/selfie.webp" alt="${esc(t.baBefore)}" width="600" height="750" loading="lazy"></div>
    <span class="ba-label l">${t.baBefore}</span><span class="ba-label r">SpookyAI</span>
    <div class="ba-handle" aria-hidden="true"><span></span></div>
    <input class="ba-range" type="range" min="0" max="100" value="50" aria-label="${esc(t.baKicker)}">
  </div>
</section>

<section class="section split reverse reveal">
  <div class="copy">
    <p class="kicker">${t.vidKicker}</p>
    <h2>${t.vidTitle}</h2>
    <p class="lead">${t.vidSub}</p>
  </div>
  <div class="vid-pair">
    ${['blackcat', 'telephone'].map((n) => `<div class="vid-card">
      <img src="${m}/video/${n}.webp" alt="${t.vidPhoto}" width="560" height="560" loading="lazy">
      <video muted loop playsinline preload="none" poster="${m}/video/${n}.webp" data-lazy-video>
        <source data-src="${m}/video/${n}.webm" type="video/webm"><source data-src="${m}/video/${n}.mp4" type="video/mp4">
      </video>
      <span class="pill"><i>${t.vidPhoto}</i> → <b>${t.vidVideo}</b></span>
    </div>`).join('')}
  </div>
</section>

<section class="section reveal">
  <div class="center">
    <p class="kicker">${t.trendKicker}</p>
    <h2>${t.trendTitle}</h2>
    <p class="lead">${t.trendSub}</p>
  </div>
  <div class="trends">
    ${TRENDS.map(([n, label]) => `<figure class="trend">${img(`${m}/trends/${n}.webp`, label, 560, 560)}<figcaption>${esc(label)}</figcaption></figure>`).join('')}
  </div>
</section>

<section id="gallery" class="section gallery reveal">
  <div class="center">
    <p class="kicker">${t.galKicker}</p>
    <h2>${t.galTitle}</h2>
    <p class="lead">${t.galSub}</p>
  </div>
  ${row('halloween', HALLOWEEN.slice(0, 9))}
  ${row('christmas', CHRISTMAS.slice(0, 9))}
  ${row('halloween', HALLOWEEN.slice(9))}
  ${row('christmas', CHRISTMAS.slice(9))}
</section>

<section class="section reveal">
  <div class="center"><p class="kicker">${t.screensKicker}</p><h2>${t.screensTitle}</h2></div>
  <div class="screens">
    ${SCREENS.map((n) => `<figure class="screen">${img(`${m}/screens/${n}.webp`, 'SpookyAI', 420, 908)}</figure>`).join('')}
  </div>
</section>

<section id="faq" class="section narrow reveal">
  <div class="center"><p class="kicker">${t.faqKicker}</p><h2>${t.faqTitle}</h2></div>
  ${t.faq.map(([q, a]) => `<details class="qa"><summary>${q}</summary><p>${a}</p></details>`).join('')}
</section>

<section id="get" class="section cta reveal">
  <div class="app-icon small" aria-hidden="true">
    <img class="icon-h" src="${m}/icon.webp" alt="" width="96" height="96">
    <img class="icon-c" src="${m}/icon_christmas.webp" alt="" width="96" height="96">
  </div>
  <h2><span>${t.ctaTitle[0]}</span> <span class="grad">${t.ctaTitle[1]}</span></h2>
  <p class="lead">${t.ctaSub}</p>
  <div class="cta-row">
    ${storeButtons(t, 'cta')}
    <div class="qr"><img src="${r}qr.svg" alt="QR" width="112" height="112" loading="lazy"><div><b>${t.qr}</b><small>${t.qrSub}</small></div></div>
  </div>
</section>
</main>

${footer(t)}
<script src="${r}app.js?v=${V}" defer></script>
</body>
</html>
`;
}

function footer(t, r = pfx(t)) {
  return `<footer class="footer">
  <div class="brand"><img class="brand-icon" src="${r}media/icon.webp" alt="" width="28" height="28"><span>SpookyAI</span></div>
  <nav><a href="${r}privacy/">${t.footer.privacy}</a><a href="${r}terms/">${t.footer.terms}</a><a href="mailto:${EMAIL}">${t.footer.contact}</a>
  <a href="${r}${t.other.path.slice(1)}" hreflang="${t.other.code}" data-lang="${t.other.code}">${t.other.label}</a></nav>
  <small>© ${new Date().getFullYear()} SpookyAI. ${t.footer.rights}</small>
</footer>`;
}

// --- Minimal Markdown → HTML for the two legal documents (headings, lists, tables, emphasis, links) ---
function inline(s) {
  return esc(s)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^*])\*([^*]+)\*/g, '$1<em>$2</em>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, txt, href) => `<a href="${href.replace(/\.md$/, '')}">${txt}</a>`)
    .replace(/(^|[\s(])([\w.+-]+@[\w-]+\.[\w.]+)/g, '$1<a href="mailto:$2">$2</a>');
}
function md(src) {
  const lines = src.replace(/\r/g, '').split('\n');
  const out = []; let i = 0;
  while (i < lines.length) {
    const l = lines[i];
    if (!l.trim()) { i++; continue; }
    let h = l.match(/^(#{1,4})\s+(.*)$/);
    if (h) { const n = Math.min(h[1].length + (h[1].length === 1 ? 0 : 0), 4); out.push(`<h${n}>${inline(h[2])}</h${n}>`); i++; continue; }
    if (/^(-{3,}|\*{3,})$/.test(l.trim())) { out.push('<hr>'); i++; continue; }
    if (l.trim().startsWith('|')) {
      const rows = []; while (i < lines.length && lines[i].trim().startsWith('|')) rows.push(lines[i++]);
      const cells = (r) => r.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
      const head = cells(rows[0]); const body = rows.slice(2).map(cells);
      out.push(`<div class="table"><table><thead><tr>${head.map((c) => `<th>${inline(c)}</th>`).join('')}</tr></thead><tbody>${body.map((r) => `<tr>${r.map((c) => `<td>${inline(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`);
      continue;
    }
    if (/^\s*([-*]|\d+\.)\s+/.test(l)) {
      const ordered = /^\s*\d+\./.test(l); const items = [];
      while (i < lines.length && /^\s*([-*]|\d+\.)\s+/.test(lines[i])) {
        let item = lines[i++].replace(/^\s*([-*]|\d+\.)\s+/, '');
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !/^\s*([-*]|\d+\.)\s+/.test(lines[i])) item += ' ' + lines[i++].trim();
        items.push(`<li>${inline(item)}</li>`);
      }
      out.push(`<${ordered ? 'ol' : 'ul'}>${items.join('')}</${ordered ? 'ol' : 'ul'}>`); continue;
    }
    const para = []; while (i < lines.length && lines[i].trim() && !/^(#{1,4}\s|\||\s*([-*]|\d+\.)\s)/.test(lines[i]) && !/^(-{3,})$/.test(lines[i].trim())) para.push(lines[i++].trim());
    out.push(`<p>${inline(para.join(' '))}</p>`);
  }
  return out.join('\n');
}

function legal(file, slug, titleEn) {
  const t = T.en; const body = md(readFileSync(join(ROOT, file), 'utf8'));
  return `<!doctype html>
<html lang="en" data-season="halloween">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${titleEn} – SpookyAI</title>
<meta name="description" content="${titleEn} for the SpookyAI app.">
<link rel="canonical" href="${BASE}/${slug}/">
<meta name="theme-color" content="#0f0b1a">
<link rel="icon" type="image/png" href="../favicon.png">
<link rel="stylesheet" href="../styles.css?v=${V}">
</head>
<body class="legal-page">
<header class="nav"><a class="brand" href="../"><img class="brand-icon" src="../media/icon.webp" alt="" width="36" height="36"><span>SpookyAI</span></a>
<div class="nav-right"><a class="btn-mini" href="../#get">${t.nav.get}</a></div></header>
<main class="legal"><p class="legal-note" lang="tr">${T.tr.legalNote} <a href="../tr/">Türkçe ana sayfa</a></p>${body}</main>
${footer(t, '../')}
</body>
</html>
`;
}

const getPage = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Get SpookyAI</title><meta name="robots" content="noindex"><link rel="canonical" href="${BASE}/">
<script>(function(){var u=navigator.userAgent,ios=/iPhone|iPad|iPod/.test(u)||(/Macintosh/.test(u)&&navigator.maxTouchPoints>1);
location.replace(ios?${JSON.stringify(APPSTORE)}:/Android/i.test(u)?${JSON.stringify(PLAY)}:'/#get');})();</script>
</head><body style="background:#0f0b1a;color:#fff;font-family:system-ui;text-align:center;padding:40px">
<p><a style="color:#ffb36b" href="${APPSTORE}">App Store</a> · <a style="color:#ffb36b" href="${PLAY}">Google Play</a></p></body></html>
`;

function write(rel, content) { const p = join(OUT, rel); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, content); }
write('index.html', landing(T.en));
write('tr/index.html', landing(T.tr));
write('privacy/index.html', legal('PRIVACY_POLICY.md', 'privacy', 'Privacy Policy'));
write('terms/index.html', legal('TERMS_OF_USE.md', 'terms', 'Terms of Use'));
write('get/index.html', getPage);
write('robots.txt', `User-agent: *\nAllow: /\nDisallow: /get/\nSitemap: ${BASE}/sitemap.xml\n`);
const today = new Date().toISOString().slice(0, 10);
write('sitemap.xml', `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${['/', '/tr/'].map((p) => `<url><loc>${BASE}${p}</loc><lastmod>${today}</lastmod><xhtml:link rel="alternate" hreflang="en" href="${BASE}/"/><xhtml:link rel="alternate" hreflang="tr" href="${BASE}/tr/"/></url>`).join('\n')}
<url><loc>${BASE}/privacy/</loc><lastmod>${today}</lastmod></url>
<url><loc>${BASE}/terms/</loc><lastmod>${today}</lastmod></url>
</urlset>
`);
console.log('Built site into', OUT);
