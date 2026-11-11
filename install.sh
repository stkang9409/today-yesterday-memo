#!/bin/zsh
set -euo pipefail

APP_NAME="오늘어제메모"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_BUNDLE}"
REPO="${MEMO_GITHUB_REPO:-stkang9409/today-yesterday-memo}"

echo "🗒 ${APP_NAME} 설치를 시작합니다..."

# 로컬 저장소 안에서 실행된 경우 직접 빌드, 원격(curl | zsh) 실행인 경우 GitHub Release 다운로드
if [[ -f "build.sh" && -d "Sources" ]]; then
    ./build.sh
    killall MemoWidget 2>/dev/null || true
    rm -rf "${INSTALL_PATH}"
    cp -R "${APP_BUNDLE}" "${INSTALL_PATH}"
else
    TMP_DIR="$(mktemp -d /tmp/memo-install.XXXXXX)"
    trap 'rm -rf "${TMP_DIR}"' EXIT

    ZIP_URL="https://github.com/${REPO}/releases/latest/download/%EC%98%A4%EB%8A%98%EC%96%B4%EC%A0%9C%EB%A9%94%EB%AA%A8-macOS.zip"
    if curl -fsSL "${ZIP_URL}" -o "${TMP_DIR}/app.zip" 2>/dev/null; then
        /usr/bin/ditto -x -k "${TMP_DIR}/app.zip" "${TMP_DIR}"
        killall MemoWidget 2>/dev/null || true
        rm -rf "${INSTALL_PATH}"
        cp -R "${TMP_DIR}/${APP_BUNDLE}" "${INSTALL_PATH}"
    else
        echo "릴리스 패키지를 찾지 못해 소스에서 직접 빌드합니다..."
        git clone --depth 1 "https://github.com/${REPO}.git" "${TMP_DIR}/repo"
        (cd "${TMP_DIR}/repo" && ./build.sh)
        killall MemoWidget 2>/dev/null || true
        rm -rf "${INSTALL_PATH}"
        cp -R "${TMP_DIR}/repo/${APP_BUNDLE}" "${INSTALL_PATH}"
    fi
fi

# Gatekeeper 격리 속성 제거 후 즉시 실행
xattr -cr "${INSTALL_PATH}" 2>/dev/null || true
open "${INSTALL_PATH}"

echo "✅ 설치 완료: ${INSTALL_PATH}"
