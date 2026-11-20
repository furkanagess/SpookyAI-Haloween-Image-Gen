// Writes public/qr.svg for the device-aware /get link.
// Uses the QR encoder bundled with npm (qrcode-terminal/vendor), so no install is needed.
const fs = require('fs'), path = require('path'), { execSync } = require('child_process');
const npmRoot = execSync('npm root -g').toString().trim();
const QRCode = require(path.join(npmRoot, 'npm/node_modules/qrcode-terminal/vendor/QRCode'));
const ECL = require(path.join(npmRoot, 'npm/node_modules/qrcode-terminal/vendor/QRCode/QRErrorCorrectLevel'));
const url = process.argv[2] || 'https://spookyai-app.web.app/get';
const qr = new QRCode(-1, ECL.M); qr.addData(url); qr.make();
const n = qr.getModuleCount(), m = 2; let d = '';
for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) if (qr.isDark(y, x)) d += `M${x + m} ${y + m}h1v1h-1z`;
const s = n + m * 2;
fs.writeFileSync(path.join(__dirname, '../public/qr.svg'),
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${s} ${s}" shape-rendering="crispEdges"><rect width="${s}" height="${s}" fill="#fff"/><path d="${d}" fill="#140d22"/></svg>\n`);
console.log('qr.svg', n, 'modules for', url);
