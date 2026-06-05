#!/bin/bash
set -e

echo "Setting up build environment..."

# Try apt-get first (Ubuntu/Debian)
if command -v apt-get &> /dev/null; then
    echo "Found apt-get, installing dependencies..."
    sudo apt-get update || true
    sudo apt-get install -y git unzip xz-utils || true
fi

echo "Installing Flutter..."
mkdir -p ~/flutter
cd ~/flutter

# Download Flutter (with multiple retry attempts)
for i in {1..3}; do
    echo "Download attempt $i..."
    if curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz; then
        break
    fi
    sleep 2
done

if [ ! -f flutter.tar.xz ]; then
    echo "Failed to download Flutter"
    exit 1
fi

tar xf flutter.tar.xz
export PATH="$HOME/flutter/flutter/bin:$PATH"

echo "Verifying Flutter installation..."
flutter --version || echo "Flutter version check failed but continuing..."

echo "Disabling analytics..."
flutter config --no-analytics

echo "Getting Flutter pub dependencies..."
cd "$VERCEL_PROJECT_DIR"
flutter pub get

echo "Building web..."
flutter build web --release

echo "Copying build to public folder..."
rm -rf public/*
cp -r build/web/* public/

echo "Build complete!"
