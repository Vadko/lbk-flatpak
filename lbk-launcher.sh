#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"
exec /app/extra/lbk-launcher/lbk-launcher --no-sandbox "$@"
