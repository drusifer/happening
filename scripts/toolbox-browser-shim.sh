#!/usr/bin/env bash
# Toolbox/distrobox containers have no web browser, so url_launcher and
# flutter_web_auth_2 (which resolve http/https via GIO) fail to open links.
# Install a container-local handler that forwards URLs to the host's default
# browser via `flatpak-spawn --host xdg-open`. Writes only to the container's
# /usr/local, never to the shared ~/.config or ~/.local (the host uses those).
set -euo pipefail

if [[ ! -f /run/.containerenv ]]; then
  echo "Not inside a toolbox container — nothing to do."
  exit 0
fi

APPS_DIR=/usr/local/share/applications
sudo mkdir -p "$APPS_DIR"

sudo tee "$APPS_DIR/host-browser.desktop" >/dev/null <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Host Browser (toolbox)
Comment=Opens URLs in the host's default browser from inside a toolbox container
Exec=flatpak-spawn --host xdg-open %u
NoDisplay=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;
DESKTOP

sudo tee "$APPS_DIR/mimeapps.list" >/dev/null <<'MIME'
[Default Applications]
x-scheme-handler/http=host-browser.desktop
x-scheme-handler/https=host-browser.desktop
MIME

gio mime x-scheme-handler/https | head -1
