#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required to bootstrap the project." >&2
  exit 1
fi

echo "Fetching Flutter dependencies..."
flutter pub get

echo "Ensuring platform folders exist..."
flutter create --platforms=android,ios,macos,windows,linux . >/dev/null 2>&1 || true

echo "Running format + analyze..."
flutter format lib >/dev/null
flutter analyze
