#!/bin/bash
# 需要 macOS + Xcode 命令行工具(xcode-select --install)
set -e; cd "$(dirname "$0")"
A=Notapple.app; rm -rf $A; mkdir -p $A/Contents/MacOS $A/Contents/Resources
for L in en zh-Hans; do mkdir -p $A/Contents/Resources/$L.lproj; echo '"CFBundleName" = "Notapple";' > $A/Contents/Resources/$L.lproj/InfoPlist.strings; done
swiftc -O -o $A/Contents/MacOS/Notapple main.swift -framework Cocoa -framework PDFKit -framework WebKit
# 用程序自身绘制图标 -> iconset -> icns(Finder/Dock/Launchpad 均使用它)
I="$(mktemp -d)/AppIcon.iconset"
$A/Contents/MacOS/Notapple --make-icon "$I"
iconutil -c icns "$I" -o $A/Contents/Resources/AppIcon.icns
# 吉他谱(.gp .gpx .gp5)渲染组件:alphaTab(MPL-2.0)+ Bravura 字体(SIL OFL),构建时从 npm 下载;失败则跳过,其余功能不受影响
AT=1.8.4; R=$A/Contents/Resources/alphatab; W=$(mktemp -d)
if curl -fsSL "https://registry.npmjs.org/@coderline/alphatab/-/alphatab-$AT.tgz" -o "$W/at.tgz" && tar -xzf "$W/at.tgz" -C "$W"; then
  mkdir -p "$R/font"
  cp "$W/package/dist/alphaTab.min.js" "$R/"; cp "$W/package/LICENSE" "$R/LICENSE-alphaTab.txt"
  cp "$W/package/dist/font/Bravura.woff2" "$W/package/dist/font/Bravura.woff" "$W/package/dist/font/Bravura-OFL.txt" "$R/font/"
  cat > "$R/viewer.html" <<'V'
<!doctype html><meta charset="utf-8">
<style>
body{margin:0;background:#f2f2f0;color:#222;font:13px -apple-system,"PingFang SC",sans-serif}
#bar{position:sticky;top:0;z-index:5;display:flex;gap:10px;align-items:center;padding:8px 14px;background:#fffe;border-bottom:1px solid #0001}
#at{background:#fff;margin:14px auto;max-width:1100px;padding:10px 20px 30px;box-shadow:0 1px 6px #0002;border-radius:6px}
@media print{#bar{display:none}body{background:#fff}}
</style>
<div id="bar"><select id="tr"></select><button onclick="z(-.1)">&minus;</button><span id="zv">100%</span><button onclick="z(.1)">+</button></div>
<div id="at"></div>
<script src="alphaTab.min.js"></script>
<script>
var PR=!!window.PRINT,step=0,sc=1,api=new alphaTab.AlphaTabApi(document.getElementById('at'),{core:{fontDirectory:'font/',useWorkers:false},display:{scale:1.0}});
if(PR){document.getElementById('bar').style.display='none';document.body.style.background='#fff';document.getElementById('at').style.cssText='box-shadow:none;margin:0;max-width:none;padding:0;background:#fff'}
api.renderFinished.on(function(){if(PR&&step==0){step=1;api.renderTracks(api.score.tracks);return}window.__done=true});
api.scoreLoaded.on(function(s){var t=document.getElementById('tr');t.innerHTML='';
  s.tracks.forEach(function(k,i){var o=document.createElement('option');o.value=i;o.textContent=(i+1)+'. '+(k.name||'Track');t.appendChild(o)});document.title=s.title||''});
document.getElementById('tr').onchange=function(){api.renderTracks([api.score.tracks[this.value]])};
api.error.on(function(e){window.__err=true;document.getElementById('at').textContent='Error: '+(e&&e.message?e.message:e)});
function z(d){sc=Math.max(.5,Math.min(2,sc+d));api.settings.display.scale=sc;api.updateSettings();api.render();document.getElementById('zv').textContent=Math.round(sc*100)+'%'}
function loadScore(b){var s=atob(b),a=new Uint8Array(s.length);for(var i=0;i<s.length;i++)a[i]=s.charCodeAt(i);api.load(a)}
</script>
V
else echo "提示:未能下载 alphaTab,吉他谱查看功能将不可用(其余功能不受影响)"; fi
cat > $A/Contents/Info.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Notapple</string><key>CFBundleDisplayName</key><string>Notapple</string>
<key>CFBundleExecutable</key><string>Notapple</string><key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIdentifier</key><string>local.Notapple</string><key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>0.2</string>
<key>CFBundleDevelopmentRegion</key><string>en</string><key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array><key>LSMinimumSystemVersion</key><string>11.0</string><key>NSHighResolutionCapable</key><true/>
<key>CFBundleDocumentTypes</key><array><dict>
<key>CFBundleTypeName</key><string>Text</string><key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>LSItemContentTypes</key><array><string>public.text</string><string>public.source-code</string><string>com.adobe.pdf</string><string>public.image</string><string>public.folder</string><string>public.data</string></array>
</dict></array></dict></plist>
P
codesign --force --deep -s - $A 2>/dev/null || true
touch $A
echo "完成 / Done: $(pwd)/$A"
