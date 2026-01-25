#!/bin/bash
export TMPDIR="$XDG_RUNTIME_DIR/app/$FLATPAK_ID"

exec /app/lbk-launcher/lbk-launcher \
    --no-sandbox \
    --enable-gpu-rasterization \
    --enable-zero-copy \
    --ignore-gpu-blocklist \
    --enable-features=VaapiVideoDecoder,CanvasOopRasterization,UseOzonePlatform \
    --ozone-platform-hint=auto \
    "$@"
