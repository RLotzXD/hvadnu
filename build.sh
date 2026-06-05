#!/bin/bash
set -e

echo "Installing Flutter..."
cd /tmp
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz
tar xf flutter.tar.xz
export PATH="/tmp/flutter/bin:$PATH"

echo "Verifying Flutter installation..."
flutter --version

echo "Getting Flutter pub dependencies..."
cd "$VERCEL_PROJECT_DIR"
flutter pub get

echo "Building web..."
flutter build web --release

echo "Copying build to public folder..."
rm -rf public/*
cp -r build/web/* public/

echo "Build complete!"
