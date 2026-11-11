import Foundation
import ServiceManagement

@MainActor
enum LoginItemManager {
    private static let label = "local.memo.today-yesterday"

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
            || FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        if enabled {
            if (try? SMAppService.mainApp.register()) != nil,
               SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                return true
            }
            return writeLaunchAgent()
        } else {
            try? SMAppService.mainApp.unregister()
            try? FileManager.default.removeItem(at: launchAgentURL)
            return true
        }
    }

    private static func writeLaunchAgent() -> Bool {
        let dir = launchAgentURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", "-a", Bundle.main.bundlePath],
            "RunAtLoad": true
        ]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else {
            return false
        }
        return (try? data.write(to: launchAgentURL, options: .atomic)) != nil
    }
}
