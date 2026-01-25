#!/bin/bash
# Extract the AppImage into /app/extra/
chmod +x LB-Launcher-linux.AppImage
./LB-Launcher-linux.AppImage --appimage-extract
rm -f LB-Launcher-linux.AppImage
mv squashfs-root lbk-launcher
