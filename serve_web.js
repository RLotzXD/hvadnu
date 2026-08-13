#!/usr/bin/env node
//
// Local web test harness:  node serve_web.js
//
// Builds for web, injects the keys from .env the same way build.js does on
// Vercel, and serves the result on http://localhost:8080.
//
// Why this exists: `flutter run -d chrome` skips .env on web and expects
// window.apiConfig, which only the deploy pipeline creates — so it always
// shows the configuration error. This reproduces the real web build locally,
// with the browser console right there, instead of waiting five minutes for
// a Vercel deploy to find out what broke.
//
// localhost counts as a secure context, so camera and microphone work here
// exactly as they do over HTTPS.

const fs = require('fs');
const http = require('http');
const path = require('path');
const { execSync } = require('child_process');

const projectDir = __dirname;
const webDir = path.join(projectDir, 'build', 'web');
const port = 8080;

function readEnvFile() {
  const envPath = path.join(projectDir, '.env');
  if (!fs.existsSync(envPath)) return {};

  return Object.fromEntries(
    fs.readFileSync(envPath, 'utf8')
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const index = line.indexOf('=');
        return [line.slice(0, index).trim(), line.slice(index + 1).trim()];
      })
  );
}

const env = readEnvFile();
const gemini = process.env.GEMINI_API_KEY || env.GEMINI_API_KEY || '';
const elevenLabs = process.env.ELEVENLABS_API_KEY || env.ELEVENLABS_API_KEY || '';

console.log(`GEMINI_API_KEY:     ${gemini ? 'set' : 'MISSING'}`);
console.log(`ELEVENLABS_API_KEY: ${elevenLabs ? 'set' : 'MISSING'}`);

console.log('\nBuilding web (this takes about a minute)...');
execSync('flutter build web --release', { cwd: projectDir, stdio: 'inherit' });

const indexPath = path.join(webDir, 'index.html');
const snippet =
  '<script>window.apiConfig = ' +
  JSON.stringify({ GEMINI_API_KEY: gemini, ELEVENLABS_API_KEY: elevenLabs }) +
  ';</script>';
fs.writeFileSync(
  indexPath,
  fs.readFileSync(indexPath, 'utf8').replace('</head>', `${snippet}\n</head>`)
);
console.log('Injected window.apiConfig');

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
};

http.createServer((req, res) => {
  const requested = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(webDir, requested === '/' ? 'index.html' : requested);

  // SPA fallback.
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = indexPath;
  }

  // No caching, so a reload always picks up the newest build rather than a
  // stale service-worker copy.
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.setHeader('Content-Type', contentTypes[path.extname(filePath)] || 'application/octet-stream');
  fs.createReadStream(filePath).pipe(res);
}).listen(port, () => {
  console.log(`\nServing on http://localhost:${port}`);
  console.log('Open that in Chrome, then View → Developer → JavaScript Console.');
  console.log('Ctrl+C to stop.');
});
