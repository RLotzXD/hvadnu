#!/usr/bin/env node
//
// Vercel build entry point (see vercel.json).
//
// Vercel's build image has no Flutter, so we fetch the SDK, build for web, and
// write the API keys into the generated index.html. Every step logs loudly:
// a failed deploy here costs ~5 minutes to reproduce, so the log needs to say
// what broke the first time.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const FLUTTER_VERSION = '3.24.0';
const FLUTTER_URL =
  `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz`;

const tmpDir = '/tmp';
const archivePath = path.join(tmpDir, 'flutter.tar.xz');
const flutterBin = path.join(tmpDir, 'flutter', 'bin');
const projectDir = process.env.VERCEL_PROJECT_DIR || process.cwd();

function run(command, options = {}) {
  return execSync(command, { stdio: 'inherit', ...options });
}

function step(message) {
  console.log(`\n=== ${message} ===`);
}

function downloadFlutter() {
  step(`Downloading Flutter ${FLUTTER_VERSION}`);

  // curl rather than https.get: it follows redirects, fails loudly on a non-2xx
  // instead of silently writing an error page into the archive, and retries.
  // Falls back to wget if the image happens not to ship curl.
  try {
    run(`curl -fSL --retry 3 --retry-delay 2 -o ${archivePath} "${FLUTTER_URL}"`);
  } catch (error) {
    console.warn(`curl failed (${error.message}); trying wget`);
    run(`wget -q -O ${archivePath} "${FLUTTER_URL}"`);
  }

  const bytes = fs.statSync(archivePath).size;
  console.log(`Downloaded ${(bytes / 1024 / 1024).toFixed(1)} MB`);
  if (bytes < 50 * 1024 * 1024) {
    throw new Error(
      `Archive is only ${bytes} bytes — expected several hundred MB. ` +
      'The download was probably an error page rather than the SDK.'
    );
  }
}

function extractFlutter() {
  step('Extracting Flutter');
  // -J forces xz. If the image lacks xz this fails here with a clear message
  // rather than further down with a confusing "flutter: not found".
  run(`tar -xJf ${archivePath} -C ${tmpDir}`);

  process.env.PATH = `${flutterBin}:${process.env.PATH}`;

  // Flutter shells out to `git log` against its own SDK directory to work out
  // its version. Git refuses to touch a repo owned by a different user than
  // the one running it ("detected dubious ownership"), which exits 128 and
  // fails the build. '*' rather than just /tmp/flutter, because the project
  // checkout has the same problem.
  run("git config --global --add safe.directory '*'");

  step('Flutter version');
  run('flutter --version');
}

function ensureEnvFile() {
  // pubspec.yaml lists `.env` as an asset because mobile reads it, but the file
  // is gitignored and so never exists on Vercel. Flutter treats a missing
  // declared asset as a hard build error, so create an empty one. Web takes its
  // keys from window.apiConfig, not from here.
  const envPath = path.join(projectDir, '.env');
  if (!fs.existsSync(envPath)) {
    step('Creating placeholder .env for the asset bundle');
    fs.writeFileSync(
      envPath,
      '# Placeholder for web builds. Keys come from window.apiConfig.\n'
    );
  }
}

function buildWeb() {
  step('Getting dependencies');
  run('flutter pub get', { cwd: projectDir });

  step('Building web');
  run('flutter build web --release', { cwd: projectDir });

  // public/ is gitignored, so on a clean checkout it will not exist.
  step('Copying build output to public/');
  run(`rm -rf ${projectDir}/public`);
  fs.mkdirSync(path.join(projectDir, 'public'), { recursive: true });
  run(`cp -r ${projectDir}/build/web/. ${projectDir}/public/`);
}

/**
 * Writes the API keys into the built index.html as `window.apiConfig`.
 *
 * vercel.json deploys public/ as static output, so server.js never runs and its
 * request-time injection never happens. Build time is the only hook available,
 * and Vercel exposes the project env vars here.
 *
 * NOTE: this ships both keys to every visitor in plain text. That is inherent
 * to calling Gemini and ElevenLabs directly from the browser. Anything
 * genuinely public should proxy these calls through a server instead.
 */
function injectApiConfig() {
  step('Injecting window.apiConfig');

  const gemini = process.env.GEMINI_API_KEY || '';
  const elevenLabs = process.env.ELEVENLABS_API_KEY || '';

  console.log(`GEMINI_API_KEY: ${gemini ? 'set' : 'MISSING'}`);
  console.log(`ELEVENLABS_API_KEY: ${elevenLabs ? 'set' : 'MISSING'}`);
  if (!gemini || !elevenLabs) {
    console.warn(
      'WARNING: the site will build but stop at the configuration screen. ' +
      'Set both in Vercel → Settings → Environment Variables.'
    );
  }

  const indexPath = path.join(projectDir, 'public', 'index.html');
  const html = fs.readFileSync(indexPath, 'utf8');
  if (!html.includes('</head>')) {
    throw new Error('No </head> found in index.html — cannot inject config');
  }

  const snippet =
    '<script>window.apiConfig = ' +
    JSON.stringify({ GEMINI_API_KEY: gemini, ELEVENLABS_API_KEY: elevenLabs }) +
    ';</script>';

  fs.writeFileSync(indexPath, html.replace('</head>', `${snippet}\n</head>`));
  console.log('Injected window.apiConfig into index.html');
}

try {
  downloadFlutter();
  extractFlutter();
  ensureEnvFile();
  buildWeb();
  injectApiConfig();
  step('Build complete');
} catch (error) {
  console.error(`\nBUILD FAILED: ${error.message}`);
  process.exit(1);
}
