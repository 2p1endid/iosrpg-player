#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-simulator}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for command in xcodegen xcodebuild; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'error: %s is required. Run this script on macOS with Xcode installed.\n' "$command" >&2
    exit 127
  fi
done

mkdir -p build
xcodegen generate

case "$MODE" in
  simulator)
    xcodebuild \
      -project RRPPGo.xcodeproj \
      -scheme RRPPGo \
      -sdk iphonesimulator \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath build/DerivedData \
      CODE_SIGNING_ALLOWED=NO \
      build

    xcodebuild \
      -project RRPPGo.xcodeproj \
      -scheme RRPPGo \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -derivedDataPath build/DerivedData \
      CODE_SIGNING_ALLOWED=NO \
      test
    ;;

  archive-unsigned)
    xcodebuild \
      -project RRPPGo.xcodeproj \
      -scheme RRPPGo \
      -configuration Release \
      -destination 'generic/platform=iOS' \
      -archivePath build/RRPPGo.xcarchive \
      CODE_SIGNING_ALLOWED=NO \
      archive
    ;;

  ipa)
    : "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple Developer team ID}"
    if [[ ! -f ExportOptions.plist ]]; then
      printf 'error: ExportOptions.plist is missing. Copy ExportOptions.example.plist and set teamID.\n' >&2
      exit 2
    fi

    xcodebuild \
      -project RRPPGo.xcodeproj \
      -scheme RRPPGo \
      -configuration Release \
      -destination 'generic/platform=iOS' \
      -archivePath build/RRPPGo.xcarchive \
      DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
      archive

    rm -rf build/ipa
    xcodebuild \
      -exportArchive \
      -archivePath build/RRPPGo.xcarchive \
      -exportPath build/ipa \
      -exportOptionsPlist ExportOptions.plist
    ;;

  *)
    printf 'Usage: %s [simulator|archive-unsigned|ipa]\n' "$0" >&2
    exit 2
    ;;
esac
