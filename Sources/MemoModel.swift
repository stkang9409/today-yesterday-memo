import Cocoa
import Combine

@MainActor
final class MemoModel: ObservableObject {
    @Published var todayTitle: String = ""
    @Published var yesterdayTitle: String = ""
    @Published var todayText: String = "" {
        didSet {
            updateStreak()
            guard !isReloading else { return }
            scheduleSave()
        }
    }
    @Published var yesterdayText: String = ""
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var isStreakCompletedToday: Bool = false

    @Published var followAllSpaces: Bool {
        didSet {
            UserDefaults.standard.set(followAllSpaces, forKey: Keys.followAllSpaces)
            onWindowBehaviorChanged?()
        }
    }
    @Published var autoFollowOnNewDay: Bool {
        didSet {
            UserDefaults.standard.set(autoFollowOnNewDay, forKey: Keys.autoFollowOnNewDay)
        }
    }
    @Published var pinOnTop: Bool {
        didSet {
            UserDefaults.standard.set(pinOnTop, forKey: Keys.pinOnTop)
            onWindowBehaviorChanged?()
        }
    }
    @Published var launchAtLogin: Bool = LoginItemManager.isEnabled

    var onWindowBehaviorChanged: (() -> Void)?

    private enum Keys {
        static let followAllSpaces = "followAllSpaces"
        static let autoFollowOnNewDay = "autoFollowOnNewDay"
        static let pinOnTop = "pinOnTop"
        static let lastAutoFollowDate = "lastAutoFollowDate"
    }

    let directoryURL: URL
    private var activeTodayKey: String = ""
    private var priorFilledDaysBeforeYesterday: Int = 0
    private var isReloading = false
    private var saveTimer: Timer?
    private var midnightTimer: Timer?

    init(directoryURL: URL? = nil) {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Keys.followAllSpaces: true,
            Keys.autoFollowOnNewDay: true,
            Keys.pinOnTop: false
        ])
        self.followAllSpaces = defaults.bool(forKey: Keys.followAllSpaces)
        self.autoFollowOnNewDay = defaults.bool(forKey: Keys.autoFollowOnNewDay)
        self.pinOnTop = defaults.bool(forKey: Keys.pinOnTop)

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
            self.directoryURL = base.appendingPathComponent("TodayYesterdayMemo", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)

        refreshIfNeeded(force: true)
        setupObservers()
    }

    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 1, c.day ?? 1)
    }

    static func displayTitle(prefix: String, for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return "\(prefix) (\(c.month ?? 1)월 \(c.day ?? 1)일)"
    }

    func toggleLaunchAtLogin() {
        let target = !LoginItemManager.isEnabled
        LoginItemManager.setEnabled(target)
        launchAtLogin = LoginItemManager.isEnabled
    }

    func flush() {
        saveTimer?.invalidate()
        saveTimer = nil
        guard !activeTodayKey.isEmpty else { return }
        save(todayText, dateKey: activeTodayKey)
    }

    func refreshIfNeeded(force: Bool = false) {
        let cal = Calendar.current
        let now = Date()
        let todayKey = Self.dateKey(for: now, calendar: cal)

        guard force || todayKey != activeTodayKey else { return }

        if !activeTodayKey.isEmpty {
            flush()
        }

        let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
        let yesterdayKey = Self.dateKey(for: yesterday, calendar: cal)

        activeTodayKey = todayKey
        todayTitle = Self.displayTitle(prefix: "오늘", for: now, calendar: cal)
        yesterdayTitle = Self.displayTitle(prefix: "어제", for: yesterday, calendar: cal)

        isReloading = true
        yesterdayText = load(dateKey: yesterdayKey)
        priorFilledDaysBeforeYesterday = countPriorFilledDays(before: yesterday, calendar: cal)
        todayText = load(dateKey: todayKey)
        isReloading = false
        updateStreak()

        // 새로운 날이 시작되면(자정 경과 또는 다음날 첫 실행) 설정에 따라 '모든 데스크탑 따라다니기' 자동 재활성화
        let lastReset = UserDefaults.standard.string(forKey: Keys.lastAutoFollowDate) ?? ""
        if lastReset != todayKey {
            UserDefaults.standard.set(todayKey, forKey: Keys.lastAutoFollowDate)
            if autoFollowOnNewDay && !followAllSpaces {
                followAllSpaces = true
            }
        }
    }

    private func countPriorFilledDays(before yesterday: Date, calendar: Calendar) -> Int {
        var count = 0
        var cursor = yesterday
        while count < 3650 {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            let key = Self.dateKey(for: prev, calendar: calendar)
            if load(dateKey: key).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                break
            }
            count += 1
            cursor = prev
        }
        return count
    }

    private func updateStreak() {
        let todayFilled = !todayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let yesterdayFilled = !yesterdayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let consecutiveDays: Int
        if todayFilled {
            consecutiveDays = yesterdayFilled ? (2 + priorFilledDaysBeforeYesterday) : 1
        } else if yesterdayFilled {
            consecutiveDays = 1 + priorFilledDaysBeforeYesterday
        } else {
            consecutiveDays = 0
        }
        let computed = max(0, consecutiveDays - 1)
        if streakDays != computed {
            streakDays = computed
        }
        let completedToday = computed > 0 && todayFilled
        if isStreakCompletedToday != completedToday {
            isStreakCompletedToday = completedToday
        }
    }

    private func load(dateKey: String) -> String {
        let url = directoryURL.appendingPathComponent("\(dateKey).txt")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private func save(_ text: String, dateKey: String) {
        let url = directoryURL.appendingPathComponent("\(dateKey).txt")
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? FileManager.default.removeItem(at: url)
        } else {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.flush()
            }
        }
    }

    private func setupObservers() {
        let nc = NotificationCenter.default
        for name: Notification.Name in [
            .NSCalendarDayChanged,
            NSApplication.didBecomeActiveNotification,
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange
        ] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshIfNeeded()
                    self?.scheduleMidnightTimer()
                }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshIfNeeded()
                self?.scheduleMidnightTimer()
            }
        }
        scheduleMidnightTimer()
    }

    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()
        let cal = Calendar.current
        let now = Date()
        guard let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) else { return }
        let delay = max(1.0, nextMidnight.timeIntervalSince(now) + 0.5)
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.refreshIfNeeded()
                self?.scheduleMidnightTimer()
            }
        }
        timer.tolerance = 1.0
        midnightTimer = timer
    }
}
