// SpookyAI landing: seasons, particles, reveals, before/after, lazy video, parallax.
(() => {
  const doc = document.documentElement;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const store = { get: (k) => { try { return localStorage.getItem(k); } catch { return null; } },
                  set: (k, v) => { try { localStorage.setItem(k, v); } catch { /* private mode */ } } };

  // Remember an explicit language choice; honour it on the next visit to the root.
  document.querySelectorAll('[data-lang]').forEach((a) => a.addEventListener('click', () => store.set('lang', a.dataset.lang)));
  if (store.get('lang') === 'tr' && doc.lang === 'en' && !document.body.classList.contains('legal-page')) location.replace('tr/');

  // Season switch
  const metaTheme = document.querySelector('meta[name="theme-color"]');
  const setSeason = (s, save) => {
    doc.dataset.season = s;
    if (metaTheme) metaTheme.content = s === 'christmas' ? '#0b1220' : '#0f0b1a';
    if (save) store.set('season', s);
    fx && fx.reset();
  };
  document.querySelectorAll('[data-season-btn]').forEach((b) =>
    b.addEventListener('click', () => setSeason(b.dataset.seasonBtn, true)));

  // Nav border on scroll
  const nav = document.querySelector('.nav');
  const onScroll = () => nav && nav.classList.toggle('scrolled', scrollY > 8);
  addEventListener('scroll', onScroll, { passive: true }); onScroll();

  // Reveal on scroll
  const io = new IntersectionObserver((es) => es.forEach((e) => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }), { rootMargin: '0px 0px -12% 0px' });
  document.querySelectorAll('.reveal').forEach((el) => io.observe(el));

  // Before / after slider
  const ba = document.querySelector('.ba');
  if (ba) {
    const range = ba.querySelector('.ba-range');
    const set = (v) => ba.style.setProperty('--pos', v + '%');
    range.addEventListener('input', () => { ba.classList.remove('hint'); set(range.value); });
    // Show the effect once when it scrolls into view
    if (!reduce) new IntersectionObserver((es, o) => es.forEach((e) => {
      if (!e.isIntersecting) return; o.disconnect(); ba.classList.add('hint');
      const seq = [[300, 82], [1300, 18], [2300, 50]];
      seq.forEach(([t, v]) => setTimeout(() => { if (ba.classList.contains('hint')) { set(v); range.value = v; } }, t));
      setTimeout(() => ba.classList.remove('hint'), 3300);
    }), { threshold: .6 }).observe(ba);
    const after = ba.querySelector('.ba-after');
    document.querySelectorAll('.tabs [role="tab"]').forEach((tab, _, all) => tab.addEventListener('click', () => {
      all.forEach((t) => t.setAttribute('aria-selected', String(t === tab)));
      after.style.opacity = '0';
      const next = new Image(); next.src = tab.dataset.after;
      next.decode().catch(() => {}).then(() => { after.src = next.src; after.alt = tab.textContent.trim(); after.style.opacity = '1'; });
    }));
  }

  // Lazy videos: load + play only while visible
  const vio = new IntersectionObserver((es) => es.forEach((e) => {
    const v = e.target;
    if (e.isIntersecting) {
      if (!v.dataset.loaded) { v.querySelectorAll('source').forEach((s) => { s.src = s.dataset.src; }); v.load(); v.dataset.loaded = '1'; }
      v.play().then(() => v.classList.add('playing')).catch(() => {});
    } else v.pause();
  }), { threshold: .35 });
  if (!reduce) document.querySelectorAll('video[data-lazy-video]').forEach((v) => vio.observe(v));

  // Hero parallax (pointer on desktop, scroll everywhere)
  const cards = [...document.querySelectorAll('.hcard')];
  if (!reduce && cards.length) {
    let mx = 0, my = 0, raf = 0;
    const apply = () => {
      raf = 0; const sy = Math.min(scrollY, 800);
      cards.forEach((c, i) => {
        const d = (i % 5 + 1) * 0.6;
        c.style.setProperty('--px', (mx * d * 6).toFixed(1) + 'px');
        c.style.setProperty('--py', (my * d * 6 - sy * d * 0.06).toFixed(1) + 'px');
      });
    };
    const req = () => { if (!raf) raf = requestAnimationFrame(apply); };
    addEventListener('pointermove', (e) => { if (e.pointerType !== 'mouse') return; mx = e.clientX / innerWidth - .5; my = e.clientY / innerHeight - .5; req(); }, { passive: true });
    addEventListener('scroll', req, { passive: true });
  }

  // Seasonal particles: snow for Christmas, drifting pumpkins/ghosts/bats for Halloween
  const canvas = document.getElementById('fx');
  const fx = canvas && !reduce ? (() => {
    const ctx = canvas.getContext('2d');
    let w, h, dpr, parts = [], running = true, last = 0;
    const SPOOKY = ['🎃', '👻', '🦇', '🕸️', '✨'];
    const size = () => {
      dpr = Math.min(devicePixelRatio || 1, 2); w = innerWidth; h = innerHeight;
      canvas.width = w * dpr; canvas.height = h * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    const make = (initial) => {
      const xmas = doc.dataset.season === 'christmas';
      if (xmas) return { kind: 'snow', x: Math.random() * w, y: initial ? Math.random() * h : -10, r: Math.random() * 2.6 + .8,
        vy: Math.random() * .6 + .35, vx: Math.random() * .4 - .2, ph: Math.random() * 6.28, a: Math.random() * .5 + .4 };
      return { kind: 'emoji', ch: SPOOKY[(Math.random() * SPOOKY.length) | 0], x: Math.random() * w, y: initial ? Math.random() * h : h + 30,
        s: Math.random() * 14 + 14, vy: -(Math.random() * .35 + .15), vx: Math.random() * .3 - .15, ph: Math.random() * 6.28, a: Math.random() * .35 + .25, rot: Math.random() * .6 - .3 };
    };
    const count = () => (doc.dataset.season === 'christmas' ? Math.min(140, (w * h) / 9000) : Math.min(22, (w * h) / 60000)) | 0;
    const reset = () => { parts = Array.from({ length: count() }, () => make(true)); };
    const tick = (t) => {
      if (!running) return;
      const dt = Math.min(48, t - last || 16) / 16; last = t;
      ctx.clearRect(0, 0, w, h);
      for (const p of parts) {
        p.ph += .01 * dt; p.x += (p.vx + Math.sin(p.ph) * .3) * dt; p.y += p.vy * dt;
        if (p.kind === 'snow') {
          if (p.y > h + 10) Object.assign(p, make(false));
          ctx.globalAlpha = p.a; ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, 6.283); ctx.fill();
        } else {
          if (p.y < -40) Object.assign(p, make(false));
          ctx.save(); ctx.globalAlpha = p.a; ctx.translate(p.x, p.y); ctx.rotate(p.rot + Math.sin(p.ph) * .2);
          ctx.font = p.s + 'px serif'; ctx.fillText(p.ch, 0, 0); ctx.restore();
        }
      }
      requestAnimationFrame(tick);
    };
    size(); reset(); requestAnimationFrame(tick);
    addEventListener('resize', () => { size(); reset(); });
    document.addEventListener('visibilitychange', () => { running = !document.hidden; if (running) requestAnimationFrame(tick); });
    return { reset };
  })() : null;
})();
