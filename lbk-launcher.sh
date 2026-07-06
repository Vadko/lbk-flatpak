#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"

# Auto-detect Wayland/X11 (Electron 20+)
# app_id is set via patch-desktop-filename in build
exec /app/lbk-launcher/lbk-launcher --no-sandbox --ozone-platform-hint=auto "$@"
