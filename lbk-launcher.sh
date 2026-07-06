#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"

# Steam Deck Game Mode: run on X11 so the launcher shares the game Xwayland with
# Proton installer windows (which are X11). On Wayland it's a separate surface and
# gamescope won't show the installer. Desktop keeps auto-detect.
if [ "$XDG_CURRENT_DESKTOP" = "gamescope" ] || [ -n "$GAMESCOPE_WAYLAND_DISPLAY" ]; then
  unset WAYLAND_DISPLAY
  exec /app/lbk-launcher/lbk-launcher --no-sandbox --ozone-platform=x11 "$@"
fi

# Desktop: auto-detect Wayland/X11 (Electron 20+); app_id via patch-desktop-filename.
exec /app/lbk-launcher/lbk-launcher --no-sandbox --ozone-platform-hint=auto "$@"
