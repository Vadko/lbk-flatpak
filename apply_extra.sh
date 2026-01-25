#!/bin/bash
# Extract the AppImage into /app/extra/
chmod +x LBK-Launcher-linux.AppImage
./LBK-Launcher-linux.AppImage --appimage-extract
rm -f LBK-Launcher-linux.AppImage
mv squashfs-root lbk-launcher
