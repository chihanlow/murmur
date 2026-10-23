#!/bin/sh
# Builds Murmur.app and installs it in /Applications.
set -e
cd "$(dirname "$0")/.."
swift build -c release

app=build/Murmur.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/Murmur "$app/Contents/MacOS/"
cp Resources/Info.plist "$app/Contents/"

iconset=build/AppIcon.iconset
mkdir -p "$iconset"
swift scripts/make-icon.swift build/icon-1024.png
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon-1024.png --out "$iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) build/icon-1024.png --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$app"
pkill -x Murmur || true
rm -rf /Applications/Murmur.app
cp -R "$app" /Applications/
echo "Installed /Applications/Murmur.app"
