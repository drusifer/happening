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
# Checked by command / pkg-config module so this works on any distro (Debian, Fedora, toolbox...).
# Format: kind|name|debian-pkg|fedora-pkg|note
DEPS=(
  "cmd|clang++|clang|clang|C++ compiler for the Linux runner"
  "cmd|cmake|cmake|cmake|build system for the Linux runner"
  "cmd|ninja|ninja-build|ninja-build|cmake build backend"
  "cmd|pkg-config|pkg-config|pkgconf-pkg-config|cmake package detection"
  "cmd|ld.lld|lld|lld|LLVM linker (Dart AOT requires lld)"
  "pc|gtk+-3.0|libgtk-3-dev|gtk3-devel|Flutter Linux GTK 3 windowing"
  "pc|libsecret-1|libsecret-1-dev|libsecret-devel|flutter_secure_storage Linux backend (libsecret / GNOME Keyring)"
  "pc|gstreamer-1.0|libgstreamer1.0-dev|gstreamer1-devel|audioplayers_linux playback"
  "pc|gstreamer-app-1.0|libgstreamer-plugins-base1.0-dev|gstreamer1-plugins-base-devel|audioplayers_linux playback"
  "pc|gstreamer-audio-1.0|libgstreamer-plugins-base1.0-dev|gstreamer1-plugins-base-devel|audioplayers_linux playback"
  "pc|webkit2gtk-4.1|libwebkit2gtk-4.1-dev|webkit2gtk4.1-devel|desktop_webview_window (OAuth login window)"
  "pc|libsoup-3.0|libsoup-3.0-dev|libsoup3-devel|desktop_webview_window HTTP backend"
)

MISSING_APT=()
MISSING_DNF=()
for dep in "${DEPS[@]}"; do
  IFS='|' read -r kind name apt_pkg dnf_pkg note <<<"$dep"
  if [[ $kind == cmd ]]; then
    command -v "$name" &>/dev/null && ok=1 || ok=0
  else
    pkg-config --exists "$name" 2>/dev/null && ok=1 || ok=0
  fi
  if [[ $ok == 1 ]]; then
    echo "✓ $name — $note"
  else
    ERRORS+=("$name ($note)")
    MISSING_APT+=("$apt_pkg")
    MISSING_DNF+=("$dnf_pkg")
  fi
done

# ── Toolbox: browser handler ──────────────────────────────────────────────────
# Inside a toolbox there is no browser; links/OAuth need a host-forwarding shim.
if [[ -f /run/.containerenv ]] && ! gio mime x-scheme-handler/https 2>/dev/null | grep -q 'Default application'; then
  ERRORS+=("https URL handler (toolbox has no browser — run ./scripts/toolbox-browser-shim.sh)")
elif [[ -f /run/.containerenv ]]; then
  echo "✓ https URL handler — toolbox forwards links to host browser"
fi

# ── Report ────────────────────────────────────────────────────────────────────
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "✗ Missing dependencies:"
  for e in "${ERRORS[@]}"; do
    echo "  • $e"
  done
  echo ""
  if [[ ${#MISSING_DNF[@]} -eq 0 ]]; then
    :
  elif command -v dnf &>/dev/null; then
    echo "Quick fix: sudo dnf install $(printf '%s\n' "${MISSING_DNF[@]}" | sort -u | xargs)"
  else
    echo "Quick fix: sudo apt install $(printf '%s\n' "${MISSING_APT[@]}" | sort -u | xargs)"
  fi
  exit 1
fi

echo ""
echo "✓ All dependencies present"
