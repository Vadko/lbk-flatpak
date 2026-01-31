#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"

# GPU optimizations are handled in the app itself based on environment detection
exec /app/lbk-launcher/lbk-launcher --no-sandbox "$@"
