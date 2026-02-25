#!/bin/bash

# Build script for Flutter web with version information
# This script shows how to inject version info at build time

# Get current date and time
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_TIMESTAMP=$(date +%s)

# Build with version information as compile-time constants
echo "🚀 Building Flutter web with version information..."
echo "📅 Build Date: $BUILD_DATE"

flutter build web \
  --dart-define=BUILD_DATE="$BUILD_DATE" \
  --dart-define=BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
  --dart-define=BUILD_MODE="production" \
  --release

echo "✅ Build completed with version information embedded in main.dart.js"
echo "🌐 Version info will be available in browser console"
echo "📂 Build output is in: build/web/" 