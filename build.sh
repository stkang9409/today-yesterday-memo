#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="오늘어제메모"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PLIST_PATH="${CONTENTS_DIR}/Info.plist"
TMP_BUILD="$(mktemp -d /tmp/memo-build.XXXXXX)"
trap 'rm -rf "${TMP_BUILD}"' EXIT

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# 1. 앱 아이콘(AppIcon.icns) 자동 생성
ICONSET_DIR="${TMP_BUILD}/AppIcon.iconset"
mkdir -p "${ICONSET_DIR}"

swiftc -module-cache-path "${TMP_BUILD}/cache" - -o "${TMP_BUILD}/gen_icon" << 'SWIFT'
import Cocoa

func drawIcon(size: Int, to url: URL) throws {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let pad = s * 0.09
    let rect = NSRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
    let radius = s * 0.18
    let clip = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clip.addClip()

    // 좌(오늘 #F9F1B5) / 우(어제 #EFE6A2) 배경
    NSColor(srgbRed: 0.976, green: 0.945, blue: 0.710, alpha: 1.0).setFill()
    NSRect(x: rect.minX, y: rect.minY, width: rect.width * 0.5, height: rect.height).fill()

    NSColor(srgbRed: 0.937, green: 0.902, blue: 0.635, alpha: 1.0).setFill()
    NSRect(x: rect.midX, y: rect.minY, width: rect.width * 0.5, height: rect.height).fill()

    // 상단 헤더바 (#F3E794)
    let headerH = rect.height * 0.22
    NSColor(srgbRed: 0.953, green: 0.906, blue: 0.580, alpha: 1.0).setFill()
    NSRect(x: rect.minX, y: rect.maxY - headerH, width: rect.width, height: headerH).fill()

    // 구분선
    NSColor(srgbRed: 0.82, green: 0.76, blue: 0.45, alpha: 1.0).setFill()
    NSRect(x: rect.midX - max(1, s * 0.006), y: rect.minY, width: max(1, s * 0.012), height: rect.height - headerH).fill()
    NSRect(x: rect.minX, y: rect.maxY - headerH, width: rect.width, height: max(1, s * 0.012)).fill()

    // 메모 텍스트 라인 표현
    let lineH = max(2, s * 0.042)
    let leftInk = NSColor(srgbRed: 0.18, green: 0.17, blue: 0.11, alpha: 0.85)
    leftInk.setFill()
    for (idx, wRatio) in [0.30, 0.24, 0.28].enumerated() {
        let y = rect.maxY - headerH - s * (0.14 + CGFloat(idx) * 0.12)
        let r = NSRect(x: rect.minX + s * 0.08, y: y, width: rect.width * wRatio, height: lineH)
        NSBezierPath(roundedRect: r, xRadius: lineH * 0.5, yRadius: lineH * 0.5).fill()
    }

    let rightInk = NSColor(srgbRed: 0.42, green: 0.39, blue: 0.25, alpha: 0.65)
    rightInk.setFill()
    for (idx, wRatio) in [0.27, 0.20].enumerated() {
        let y = rect.maxY - headerH - s * (0.14 + CGFloat(idx) * 0.12)
        let r = NSRect(x: rect.midX + s * 0.07, y: y, width: rect.width * wRatio, height: lineH)
        NSBezierPath(roundedRect: r, xRadius: lineH * 0.5, yRadius: lineH * 0.5).fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])!
    try data.write(to: url)
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let specs: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, px) in specs {
    try drawIcon(size: px, to: outDir.appendingPathComponent(name))
}
SWIFT

"${TMP_BUILD}/gen_icon" "${ICONSET_DIR}"
/usr/bin/iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns"

# 2. Info.plist 생성
cat > "${PLIST_PATH}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MemoWidget</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>local.memo.today-yesterday</string>
    <key>CFBundleName</key>
    <string>오늘어제메모</string>
    <key>CFBundleDisplayName</key>
    <string>오늘어제메모</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 3. Universal Binary (Apple Silicon + Intel) 컴파일 시도 (실패 시 현재 아키텍처로 폴백)
SRCS=(Sources/LoginItemManager.swift Sources/MemoModel.swift Sources/MemoApp.swift)
if swiftc -module-cache-path "${TMP_BUILD}/cache" "${SRCS[@]}" -O -target arm64-apple-macos14.0 -o "${TMP_BUILD}/MemoWidget-arm64" 2>/dev/null \
   && swiftc -module-cache-path "${TMP_BUILD}/cache" "${SRCS[@]}" -O -target x86_64-apple-macos14.0 -o "${TMP_BUILD}/MemoWidget-x86_64" 2>/dev/null; then
    /usr/bin/lipo -create "${TMP_BUILD}/MemoWidget-arm64" "${TMP_BUILD}/MemoWidget-x86_64" -output "${MACOS_DIR}/MemoWidget"
else
    swiftc -module-cache-path "${TMP_BUILD}/cache" "${SRCS[@]}" -O -o "${MACOS_DIR}/MemoWidget"
fi

codesign --force --deep --sign - "${APP_BUNDLE}" >/dev/null 2>&1 || true

echo "빌드 완료: $(pwd)/${APP_BUNDLE}"
