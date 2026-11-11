#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="오늘어제메모"
APP_BUNDLE="${APP_NAME}.app"
DIST_DIR="dist"

./build.sh

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}/dmg-staging"

# 1. ZIP 패키지 생성 (macOS 메타데이터 보존)
/usr/bin/ditto -c -k --keepParent "${APP_BUNDLE}" "${DIST_DIR}/${APP_NAME}-macOS.zip"

# 2. 드래그 앤 드롭 설치용 DMG 생성
cp -R "${APP_BUNDLE}" "${DIST_DIR}/dmg-staging/"
ln -s /Applications "${DIST_DIR}/dmg-staging/Applications"

/usr/bin/hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DIST_DIR}/dmg-staging" \
    -ov -format UDZO \
    "${DIST_DIR}/${APP_NAME}.dmg" >/dev/null

rm -rf "${DIST_DIR}/dmg-staging"

echo "패키징 완료:"
ls -lh "${DIST_DIR}"
