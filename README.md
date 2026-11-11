# 오늘 | 어제 메모 (Today | Yesterday Memo)

복잡한 기능 없이 **`오늘 (n월 m일) | 어제 (n월 m일)`** 딱 두 칸으로만 이루어진 초경량 macOS 네이티브 스티커 메모 앱입니다.

하루가 지나면 오늘 적었던 메모가 자동으로 오른쪽 **어제** 칸으로 넘어가고, 왼쪽 **오늘** 칸은 새로 비워집니다.

---

## 주요 기능

- **오늘 | 어제 50:50 이분할 메모**: 날짜 선택이나 이동 없이 오늘 쓸 메모와 어제 적은 메모만 나란히 보여줍니다.
- **자정 자동 전환 & 실시간 자동 저장**: 타이핑 즉시 날짜별 로컬 텍스트 파일로 저장되며 자정·절전 해제 시 자동 전환됩니다.
- **연속 작성 스트릭 (`🔥 N일`)**: 어제와 오늘 메모가 모두 채워진 첫날 `1일`부터 매일 연속 기록을 우측 상단에 표시하고, 둘 다 비워지면 `0일`로 초기화됩니다.
- **다중 데스크탑 따라다니기 & 다음날 자동 재활성화**: 하루가 시작되면 모든 데스크탑과 전체화면 창을 따라다니며, 할 일을 마친 뒤 배지를 눌러 끄면 다음날 자정에 다시 자동으로 켜집니다.
- **로그인 시 자동 실행**: 우측 상단 `⋯` 메뉴에서 원클릭으로 재부팅 후 자동 실행을 켜고 끌 수 있습니다.

---

## 설치 방법 (macOS 14.0 이상)

### 1. 터미널 한 줄 설치 (권장 · Gatekeeper 경고 자동 처리)

터미널을 열고 아래 명령어 한 줄을 붙여넣으면 `/Applications/오늘어제메모.app` 설치와 실행이 한 번에 완료됩니다.

```bash
curl -fsSL https://raw.githubusercontent.com/stkang9409/today-yesterday-memo/main/install.sh | zsh
```

### 2. DMG 파일로 설치

1. [Releases](../../releases/latest) 페이지에서 **`오늘어제메모.dmg`** 파일을 다운로드합니다.
2. DMG를 열고 **`오늘어제메모.app`**을 **`Applications`** 폴더로 드래그합니다.
3. 최초 실행 시 macOS 보안 경고가 뜨면 터미널에서 아래 명령어를 한 번 실행하거나 **우클릭 → 열기**를 선택하세요.

```bash
xattr -cr /Applications/오늘어제메모.app
```

### 3. 소스에서 직접 빌드 및 설치

외부 의존성 없이 순수 Swift / AppKit / SwiftUI로만 작성되어 Xcode 프로젝트 없이 바로 빌드됩니다.

```bash
git clone https://github.com/stkang9409/today-yesterday-memo.git
cd today-yesterday-memo
./install.sh
```

---

## 메모 저장 위치

모든 메모는 외부 서버 전송 없이 맥 로컬 경로에만 순수 텍스트 파일(`YYYY-MM-DD.txt`)로 저장됩니다.

```text
~/Library/Application Support/TodayYesterdayMemo/
```

## 라이선스

[MIT License](LICENSE)
