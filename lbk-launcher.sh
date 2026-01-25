#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"
exec /app/lbk-launcher/lbk-launcher --no-sandbox "$@"
