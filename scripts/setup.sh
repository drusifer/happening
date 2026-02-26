#!/usr/bin/env bash
# Verify Flutter and Linux desktop build dependencies are installed.
# Called by `make setup`. Does NOT install anything — tells you what's missing.
set -euo pipefail

ERRORS=()

# ── Flutter ───────────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  ERRORS+=("flutter: not found — install via: sudo snap install flutter --classic")
else
  echo "✓ flutter $(flutter --version --machine 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["frameworkVersion"])' 2>/dev/null || flutter --version | head -1 | awk '{print $2}')"
fi

# ── Linux desktop build deps ──────────────────────────────────────────────────
# C++ compiler, build system, package detection, GTK windowing, linker, secure storage plugin
APT_PKGS=(clang cmake ninja-build pkg-config libgtk-3-dev lld)
APT_NOTES=(
  "C++ compiler for the Linux runner"
  "build system for the Linux runner"
  "cmake build backend"
  "cmake package detection"
  "Flutter Linux GTK 3 windowing"
  "LLVM linker (Dart AOT requires lld)"
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
  echo "Quick fix: sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev lld"
  exit 1
fi

echo ""
echo "✓ All dependencies present"
