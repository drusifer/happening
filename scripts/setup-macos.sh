#!/usr/bin/env bash
# Verify macOS desktop build dependencies.
# Called by `make setup` on macOS.
set -euo pipefail

FLUTTER_SDK="${HOME}/flutter"

ERRORS=()

# ── Flutter SDK ───────────────────────────────────────────────────────────────
if [ -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "✓ flutter SDK ($FLUTTER_SDK)"
else
  echo "==> Flutter SDK not found — cloning stable into ${FLUTTER_SDK} ..."
  mkdir -p "${FLUTTER_SDK}"
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1 "$FLUTTER_SDK"
  echo "✓ flutter SDK cloned"
fi

# ── Xcode ─────────────────────────────────────────────────────────────────────
if xcodebuild -version &>/dev/null; then
  echo "✓ Xcode ($(xcodebuild -version 2>/dev/null | head -1))"
else
  ERRORS+=("Xcode — install from the App Store, then run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer")
fi

# ── CocoaPods ─────────────────────────────────────────────────────────────────
if command -v pod &>/dev/null; then
  echo "✓ cocoapods ($(pod --version))"
else
  ERRORS+=("cocoapods — install with: brew install cocoapods")
fi

# ── Report ────────────────────────────────────────────────────────────────────
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "✗ Missing dependencies:"
  for e in "${ERRORS[@]}"; do
    echo "  • $e"
  done
  echo ""
  echo "Quick fix: install Xcode from the App Store, then: brew install cocoapods"
  exit 1
fi

echo ""
echo "✓ All dependencies present"
