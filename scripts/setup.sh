#!/usr/bin/env bash
# Bootstrap Flutter SDK and verify Linux desktop build dependencies.
# Called by `make setup`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_SDK="${HOME}/flutter"

ERRORS=()

# ── Flutter SDK ───────────────────────────────────────────────────────────────
if [ -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "✓ flutter SDK ($FLUTTER_SDK)"
else
  echo "==> Flutter SDK not found — cloning stable into .flutter/flutter ..."
  mkdir -p "${HOME}/flutter"
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1 "$FLUTTER_SDK"
  echo "✓ flutter SDK cloned"
fi

# ── Linux desktop build deps ──────────────────────────────────────────────────
# C++ compiler, build system, package detection, GTK windowing, linker, secure storage plugin
APT_PKGS=(clang cmake ninja-build pkg-config libgtk-3-dev lld libsecret-1-dev)
APT_NOTES=(
  "C++ compiler for the Linux runner"
  "build system for the Linux runner"
  "cmake build backend"
  "cmake package detection"
  "Flutter Linux GTK 3 windowing"
  "LLVM linker (Dart AOT requires lld)"
  "flutter_secure_storage Linux backend (libsecret / GNOME Keyring)"
)

for i in "${!APT_PKGS[@]}"; do
  pkg="${APT_PKGS[$i]}"
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✓ $pkg — ${APT_NOTES[$i]}"
  else
    ERRORS+=("$pkg (${APT_NOTES[$i]})")
  fi
done

# ── Report ────────────────────────────────────────────────────────────────────
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "✗ Missing dependencies:"
  for e in "${ERRORS[@]}"; do
    echo "  • $e"
  done
  echo ""
  echo "Quick fix: sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev lld libsecret-1-dev"
  exit 1
fi

echo ""
echo "✓ All dependencies present"
