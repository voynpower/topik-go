#!/bin/bash
set -e

# Move to topik-go root directory
cd "$(dirname "$0")/.."

echo "🔨 Building TOPIK Go Android APK pointing to AWS Production Server..."
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://topik-api.duckdns.org \
  --dart-define=MEDIA_BASE_URL=https://damqug77a9y1r.cloudfront.net "$@"

echo ""
echo "✅ Build completed successfully!"
echo "📁 APK location for modern Android phones (Galaxy, Pixel, etc.):"
echo "   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
