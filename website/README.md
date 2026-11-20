# SpookyAI website

Static landing page served by Firebase Hosting (`firebase.json` → `hosting.public = website/public`).
It is not part of the Flutter build.

- `/` English, `/tr/` Turkish, `/privacy/` and `/terms/` (generated from the repo's `PRIVACY_POLICY.md` and `TERMS_OF_USE.md`), `/get/` sends phones to the right store (the QR code points here).
- Only images and style names are published. Library prompt text never goes on the site.

## Update

```bash
website/tools/optimize-assets.sh   # only when source images change (needs cwebp + ffmpeg)
node website/tools/make-qr.cjs     # only if the site URL changes
node website/build.mjs             # after editing copy, styles.css or app.js
```

Copy (EN/TR), image lists, store links and the base URL are at the top of `build.mjs`.
`styles.css` and `app.js` in `public/` are hand-written; the HTML files are generated.

## Preview and deploy

```bash
python3 -m http.server 4173 --directory website/public
firebase deploy --only hosting --project spookyai-app-ratings
```

Live at https://spookyai-app.web.app (Hosting site `spookyai-app`). The project's default site,
spookyai-app-ratings.web.app, only 301-redirects to it (`website/redirect`).
