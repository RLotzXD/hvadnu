#!/usr/bin/env node
const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const FLUTTER_URL = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz';
const tmpDir = '/tmp';
const flutterPath = path.join(tmpDir, 'flutter.tar.xz');

console.log('Downloading Flutter...');

const file = fs.createWriteStream(flutterPath);
https.get(FLUTTER_URL, (response) => {
  response.pipe(file);
  file.on('finish', () => {
    file.close();
    console.log('Flutter downloaded successfully');
    buildFlutterWeb();
  });
}).on('error', (err) => {
  fs.unlink(flutterPath, () => {
    console.error('Download failed:', err.message);
    process.exit(1);
  });
});

function buildFlutterWeb() {
  try {
    console.log('Extracting Flutter...');
    execSync(`cd ${tmpDir} && tar xf flutter.tar.xz`, { stdio: 'inherit' });

    console.log('Setting up Flutter...');
    process.env.PATH = `/tmp/flutter/bin:${process.env.PATH}`;

    console.log('Verifying Flutter installation...');
    execSync('flutter --version', { stdio: 'inherit' });

    const projectDir = process.env.VERCEL_PROJECT_DIR || process.cwd();
    console.log(`Project directory: ${projectDir}`);

    // pubspec.yaml lists `.env` as an asset because mobile reads it, but the
    // file is gitignored and so never exists on Vercel. Flutter treats a
    // missing declared asset as a hard build error, so create an empty one.
    // Web takes its keys from window.apiConfig, not from here.
    const envPath = path.join(projectDir, '.env');
    if (!fs.existsSync(envPath)) {
      console.log('Creating placeholder .env for the asset bundle...');
      fs.writeFileSync(envPath, '# Placeholder for web builds. Keys come from window.apiConfig.\n');
    }

    console.log('Getting dependencies...');
    execSync('cd ' + projectDir + ' && flutter pub get', { stdio: 'inherit' });

    console.log('Building web...');
    execSync('cd ' + projectDir + ' && flutter build web --release', { stdio: 'inherit' });

    // public/ is gitignored, so on a clean checkout it won't exist yet.
    console.log('Copying build to public...');
    execSync(`rm -rf ${projectDir}/public && mkdir -p ${projectDir}/public && cp -r ${projectDir}/build/web/. ${projectDir}/public/`, { stdio: 'inherit' });

    injectApiConfig(path.join(projectDir, 'public', 'index.html'));

    console.log('Build complete!');
  } catch (error) {
    console.error('Build failed:', error.message);
    process.exit(1);
  }
}

/**
 * Writes the API keys into the built index.html as `window.apiConfig`.
 *
 * vercel.json deploys `public/` as static output, so server.js never runs and
 * its request-time injection never happens. Build time is the only hook we
 * actually get, and Vercel exposes the project env vars here.
 *
 * NOTE: this ships both keys to every visitor in plain text. That is inherent
 * to calling Gemini and ElevenLabs directly from the browser. Anything
 * public-facing should proxy these calls through a server instead.
 */
function injectApiConfig(indexPath) {
  const gemini = process.env.GEMINI_API_KEY || '';
  const elevenLabs = process.env.ELEVENLABS_API_KEY || '';

  if (!gemini || !elevenLabs) {
    console.warn(
      'WARNING: GEMINI_API_KEY and/or ELEVENLABS_API_KEY are not set. ' +
      'The web build will start but show a configuration error.'
    );
  }

  if (!fs.existsSync(indexPath)) {
    throw new Error(`Cannot inject config: ${indexPath} does not exist`);
  }

  const snippet =
    '<script>window.apiConfig = ' +
    JSON.stringify({ GEMINI_API_KEY: gemini, ELEVENLABS_API_KEY: elevenLabs }) +
    ';</script>';

  const html = fs.readFileSync(indexPath, 'utf8');
  if (!html.includes('</head>')) {
    throw new Error('Cannot inject config: no </head> found in index.html');
  }

  fs.writeFileSync(indexPath, html.replace('</head>', `${snippet}\n</head>`));
  console.log('Injected window.apiConfig into index.html');
}
