#!/bin/bash
# 需要 macOS + Xcode 命令行工具(xcode-select --install)
set -e; cd "$(dirname "$0")"
A=Notapple.app; rm -rf $A; mkdir -p $A/Contents/MacOS $A/Contents/Resources
swiftc -O -o $A/Contents/MacOS/Notapple main.swift -framework Cocoa -framework PDFKit -framework WebKit
# 用程序自身绘制图标 -> iconset -> icns(Finder/Dock/Launchpad 均使用它)
I="$(mktemp -d)/AppIcon.iconset"
$A/Contents/MacOS/Notapple --make-icon "$I"
iconutil -c icns "$I" -o $A/Contents/Resources/AppIcon.icns
cat > $A/Contents/Info.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Notapple</string><key>CFBundleDisplayName</key><string>Notapple</string>
<key>CFBundleExecutable</key><string>Notapple</string><key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIdentifier</key><string>local.Notapple</string><key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>0.2</string>
<key>LSMinimumSystemVersion</key><string>11.0</string><key>NSHighResolutionCapable</key><true/>
<key>CFBundleDocumentTypes</key><array><dict>
<key>CFBundleTypeName</key><string>Text</string><key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>LSItemContentTypes</key><array><string>public.text</string><string>public.source-code</string><string>com.adobe.pdf</string><string>public.image</string><string>public.folder</string><string>public.data</string></array>
</dict></array></dict></plist>
P
codesign --force --deep -s - $A 2>/dev/null || true
touch $A
echo "完成 / Done: $(pwd)/$A"
