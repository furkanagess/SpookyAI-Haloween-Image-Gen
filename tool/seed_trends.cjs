// Writes the Trends screen content to Firestore with your logged-in
// Firebase CLI account (existing documents with the same id are replaced):
//   docs/trend_sections.sample.json -> trend_sections/{id}
//   docs/trend_config.sample.json   -> trend_config/screen
//
// Items with "imageFile" (a local image path, relative to the JSON file)
// are uploaded to Storage at trends/<section>/<item id>.<ext> first, and
// their imageUrl is set to that path.
//
// Usage: node tool/seed_trends.cjs [sections.json] [config.json]
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

const project = 'spookyai-app-ratings';
const bucket = 'spookyai-app-ratings.firebasestorage.app';
const mime = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };
const file =
  process.argv[2] || path.join(__dirname, '../docs/trend_sections.sample.json');
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const configFile =
  process.argv[3] || path.join(__dirname, '../docs/trend_config.sample.json');
const writes = Object.entries(data).map(([id, doc]) => [`trend_sections/${id}`, doc]);
if (fs.existsSync(configFile)) {
  writes.push(['trend_config/screen', JSON.parse(fs.readFileSync(configFile, 'utf8'))]);
}
const iso = /^\d{4}-\d{2}-\d{2}T/;

function val(v) {
  if (typeof v === 'string')
    return iso.test(v) ? { timestampValue: v } : { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number')
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return {
    mapValue: {
      fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, val(x)])),
    },
  };
}

(async () => {
  const root = execSync('npm root -g').toString().trim();
  const auth = require(path.join(root, 'firebase-tools/lib/auth.js'));
  const cfg = JSON.parse(
    fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'),
  );
  const tok = await auth.getAccessToken(cfg.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform',
  ]);
  const access = tok.access_token || tok;

  // Upload local preview images first.
  const base = path.dirname(file);
  for (const [sectionId, section] of Object.entries(data)) {
    for (const item of section.items || []) {
      if (!item.imageFile) continue;
      const local = path.resolve(base, item.imageFile);
      const ext = path.extname(local).toLowerCase();
      if (!mime[ext]) throw new Error(`Unsupported image type: ${local}`);
      const dest = `trends/${sectionId}/${item.id || 'item'}${ext}`;
      const up = await fetch(
        `https://firebasestorage.googleapis.com/v0/b/${bucket}/o?name=${encodeURIComponent(dest)}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${access}`, 'Content-Type': mime[ext] },
          body: fs.readFileSync(local),
        },
      );
      console.log('upload', dest, up.status, up.ok ? 'ok' : (await up.text()).slice(0, 300));
      if (up.ok) item.imageUrl = dest;
      delete item.imageFile;
    }
  }
  for (const [docPath, doc] of writes) {
    const url =
      `https://firestore.googleapis.com/v1/projects/${project}` +
      `/databases/(default)/documents/${docPath}`;
    const r = await fetch(url, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields: val(doc).mapValue.fields }),
    });
    console.log(docPath, r.status, r.ok ? 'ok' : (await r.text()).slice(0, 300));
  }
})().catch((e) => {
  console.error('ERR', e.message);
  process.exit(1);
});
