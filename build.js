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

    console.log('Getting dependencies...');
    execSync('cd ' + projectDir + ' && flutter pub get', { stdio: 'inherit' });

    console.log('Building web...');
    execSync('cd ' + projectDir + ' && flutter build web --release', { stdio: 'inherit' });

    console.log('Copying build to public...');
    execSync(`rm -rf ${projectDir}/public/* && cp -r ${projectDir}/build/web/* ${projectDir}/public/`, { stdio: 'inherit' });

    console.log('Build complete!');
  } catch (error) {
    console.error('Build failed:', error.message);
    process.exit(1);
  }
}
