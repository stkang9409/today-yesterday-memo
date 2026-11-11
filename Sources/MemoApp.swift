import Cocoa
import SwiftUI

enum StickyPalette {
    static let headerBar = Color(red: 0.953, green: 0.906, blue: 0.580)      // #F3E794
    static let headerDivider = Color(red: 0.865, green: 0.812, blue: 0.485)  // #DCD07C
    static let todayPaper = Color(red: 0.976, green: 0.945, blue: 0.710)     // #F9F1B5
    static let yesterdayPaper = Color(red: 0.937, green: 0.902, blue: 0.635) // #EFE6A2
    static let splitDivider = Color(red: 0.850, green: 0.800, blue: 0.495)   // #D9CC7E

    static let todayInk = Color(red: 0.10, green: 0.10, blue: 0.08)
    static let yesterdayInk = Color(red: 0.33, green: 0.31, blue: 0.20)
    static let todayHeader = Color(red: 0.13, green: 0.12, blue: 0.08)
    static let yesterdayHeader = Color(red: 0.40, green: 0.37, blue: 0.24)
    static let placeholder = Color(red: 0.56, green: 0.52, blue: 0.34)
    static let badgeActiveBg = Color(red: 0.20, green: 0.19, blue: 0.12)
    static let badgeInactiveBg = Color.black.opacity(0.08)
}

struct MemoRootView: View {
    @ObservedObject var model: MemoModel

    private var streakHelpText: String {
        if model.isStreakCompletedToday {
            return "어제·오늘 연속 메모 스트릭 \(model.streakDays)일 달성 중"
        } else if model.streakDays > 0 {
            return "오늘 메모를 작성하면 \(model.streakDays + 1)일 연속으로 이어집니다 (어제·오늘 모두 비워지면 0일 초기화)"
        } else {
            return "어제와 오늘 메모가 모두 채워진 날부터 1일로 시작합니다"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 스티커 프로 타이틀바 (좌측 78pt는 맥 표준 빨·노·초 신호등 버튼 영역)
            HStack(spacing: 6) {
                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: model.isStreakCompletedToday ? "flame.fill" : "flame")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            model.isStreakCompletedToday
                                ? Color(red: 0.85, green: 0.32, blue: 0.08)
                                : StickyPalette.todayHeader.opacity(model.streakDays > 0 ? 0.65 : 0.40)
                        )
                    Text("\(model.streakDays)일")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            StickyPalette.todayHeader.opacity(model.streakDays > 0 ? 0.95 : 0.50)
                        )
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(model.streakDays > 0 ? 0.07 : 0.04))
                )
                .help(streakHelpText)

                Button {
                    model.followAllSpaces.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: model.followAllSpaces ? "rectangle.on.rectangle.fill" : "rectangle")
                            .font(.system(size: 10, weight: .semibold))
                        Text(model.followAllSpaces ? "따라다니기 켜짐" : "현재 데스크탑만")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(model.followAllSpaces ? Color(red: 0.99, green: 0.96, blue: 0.76) : StickyPalette.todayHeader.opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(model.followAllSpaces ? StickyPalette.badgeActiveBg : StickyPalette.badgeInactiveBg)
                    )
                }
                .buttonStyle(.plain)
                .help("모든 데스크탑 화면 전환 시 메모장이 함께 따라다닙니다")

                Button {
                    model.pinOnTop.toggle()
                } label: {
                    Image(systemName: model.pinOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(StickyPalette.todayHeader.opacity(model.pinOnTop ? 1.0 : 0.45))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("항상 다른 창 위에 고정")

                Menu {
                    Toggle("모든 데스크탑 따라다니기", isOn: $model.followAllSpaces)
                    Toggle("다음날 자동으로 따라다니기 켜기", isOn: $model.autoFollowOnNewDay)
                    Toggle("항상 위에 고정", isOn: $model.pinOnTop)
                    Divider()
                    Button(model.launchAtLogin ? "✓ 로그인 시 자동 실행" : "로그인 시 자동 실행") {
                        model.toggleLaunchAtLogin()
                    }
                    Divider()
                    Button("종료 (⌘Q)") {
                        NSApp.terminate(nil)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(StickyPalette.todayHeader)
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.leading, 78)
            .padding(.trailing, 10)
            .frame(height: 32)
            .background(
                StickyPalette.headerBar
                    .gesture(WindowDragGesture())
            )

            Rectangle()
                .fill(StickyPalette.headerDivider)
                .frame(height: 1)

            // 좌·우 50:50 이분할 본문 (오늘 | 어제)
            HStack(spacing: 0) {
                // 왼쪽: 오늘 메모 (편집 가능)
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.todayTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(StickyPalette.todayHeader)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $model.todayText)
                            .font(.system(size: 14.5))
                            .lineSpacing(4)
                            .foregroundStyle(StickyPalette.todayInk)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 9)
                            .padding(.bottom, 8)

                        if model.todayText.isEmpty {
                            Text("오늘 메모...")
                                .font(.system(size: 14.5))
                                .foregroundStyle(StickyPalette.placeholder)
                                .padding(.horizontal, 14)
                                .padding(.top, 1)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(StickyPalette.todayPaper)

                Rectangle()
                    .fill(StickyPalette.splitDivider)
                    .frame(width: 1)

                // 오른쪽: 어제 메모 (읽기 및 드래그 복사 전용)
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.yesterdayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(StickyPalette.yesterdayHeader)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)

                    ScrollView {
                        if model.yesterdayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("어제 메모 없음")
                                .font(.system(size: 14.5))
                                .foregroundStyle(StickyPalette.placeholder)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.top, 1)
                        } else {
                            Text(model.yesterdayText)
                                .font(.system(size: 14.5))
                                .lineSpacing(4)
                                .foregroundStyle(StickyPalette.yesterdayInk)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.top, 1)
                                .padding(.bottom, 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(StickyPalette.yesterdayPaper)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .environment(\.colorScheme, .light)
    }
}

final class StickyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || event.type == .rightMouseDown {
            if !isKeyWindow {
                makeKeyAndOrderFront(nil)
            }
        }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command, let key = event.charactersIgnoringModifiers?.lowercased() {
            switch key {
            case "c": return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
            case "v": return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
            case "x": return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
            case "a": return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
            case "z": return NSApp.sendAction(Selector(("undo:")), to: nil, from: self)
            case "w": performClose(nil); return true
            case "q": NSApp.terminate(nil); return true
            default: break
            }
        } else if flags == [.command, .shift], event.charactersIgnoringModifiers?.lowercased() == "z" {
            return NSApp.sendAction(Selector(("redo:")), to: nil, from: self)
        }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = MemoModel()
    private var window: StickyPanel!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        setupWindow()
        model.onWindowBehaviorChanged = { [weak self] in
            self?.applyWindowBehavior()
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.model.followAllSpaces,
                      self.window != nil, self.window.isVisible, !self.window.isMiniaturized else { return }
                self.window.orderFrontRegardless()
            }
        }
        applyWindowBehavior()
        showWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showWindow() }
        return true
    }

    func applicationWillResignActive(_ notification: Notification) {
        model.flush()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.flush()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        model.refreshIfNeeded()
    }

    func windowDidResignKey(_ notification: Notification) {
        model.flush()
    }

    private func setupWindow() {
        let hostingView = NSHostingView(rootView: MemoRootView(model: model))
        window = StickyPanel(
            contentRect: NSRect(x: 120, y: 420, width: 540, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.appearance = NSAppearance(named: .aqua)
        window.hidesOnDeactivate = false
        window.becomesKeyOnlyIfNeeded = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 360, height: 220)
        window.backgroundColor = NSColor(srgbRed: 0.953, green: 0.906, blue: 0.580, alpha: 1.0)
        window.contentView = hostingView
        window.setFrameAutosaveName("TodayYesterdayMemoStandardWindow")
    }

    private func applyWindowBehavior() {
        guard window != nil else { return }
        if model.followAllSpaces {
            window.isFloatingPanel = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            if window.isVisible && !window.isMiniaturized {
                window.orderFrontRegardless()
            }
        } else {
            window.isFloatingPanel = model.pinOnTop
            window.level = model.pinOnTop ? .floating : .normal
            window.collectionBehavior = [.moveToActiveSpace]
            if window.isVisible && !window.isMiniaturized {
                window.orderFront(nil)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.model.followAllSpaces else { return }
                self.window.collectionBehavior = [.managed]
            }
        }
    }

    @objc private func showWindow() {
        model.refreshIfNeeded()
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "오늘 어제 메모")
            btn.image?.isTemplate = true
            btn.target = self
            btn.action = #selector(showWindow)
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "창 닫기", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        appMenu.addItem(withTitle: "가리기", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "편집")
        editMenu.addItem(withTitle: "실행 취소", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "다시 실행", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "오려두기", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "복사하기", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "붙여넣기", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "전체 선택", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }
}

@main
@MainActor
struct TodayYesterdayApp {
    static var delegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let appDelegate = AppDelegate()
        delegate = appDelegate
        app.delegate = appDelegate
        app.run()
    }
}
