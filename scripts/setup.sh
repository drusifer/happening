#!/usr/bin/env bash
# Bootstrap Flutter SDK into .flutter/ — runs on Linux (x64 + arm64), macOS, Windows (WSL).
# Called by `make setup`. Safe to run multiple times.
set -euo pipefail

FLUTTER_DIR=".flutter/flutter"
FLUTTER_BIN=".flutter/flutter/bin/flutter"

# ── already installed? ───────────────────────────────────────────────────────
if [[ -x "$FLUTTER_BIN" ]]; then
  echo "✓ Flutter already at $FLUTTER_DIR"
  exit 0
fi

# ── clone Flutter stable ─────────────────────────────────────────────────────
echo "⬇ Cloning Flutter stable channel into $FLUTTER_DIR ..."
mkdir -p .flutter
git clone \
  https://github.com/flutter/flutter.git \
  --depth 1 \
  --branch stable \
  "$FLUTTER_DIR"

export PATH="$(pwd)/$FLUTTER_DIR/bin:$PATH"

# ── precache host platform artifacts ─────────────────────────────────────────
echo "⬇ Precaching platform artifacts ..."
case "$(uname -s)" in
  Linux)  flutter precache --linux ;;
  Darwin) flutter precache --macos ;;
  *)      flutter precache ;;
esac

echo ""
echo "✓ Flutter ready: $(flutter --version | head -1)"
