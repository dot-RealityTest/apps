import AppKit
import CoreGraphics

struct WindowInfo: Codable {
    let app: String
    let title: String
}

struct ContextSnapshot: Codable {
    let time: String
    let frontmostApp: String
    let runningApps: [String]
    let windows: [WindowInfo]
    let clipboard: String
}

class ContextCapture {
    static func capture() -> ContextSnapshot {
        let workspace = NSWorkspace.shared
        
        // 1. Frontmost App
        let frontmost = workspace.frontmostApplication?.localizedName ?? "Unknown"
        
        // 2. Running Apps (filtering out background daemons)
        let runningApps = workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { $0.localizedName }
        
        // 3. Visible Windows via CoreGraphics
        var windowsList: [WindowInfo] = []
        let options = CGWindowListOption.optionOnScreenOnly
        if let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for info in windowInfoList {
                if let appName = info[kCGWindowOwnerName as String] as? String,
                   let windowTitle = info[kCGWindowName as String] as? String,
                   !windowTitle.isEmpty {
                    windowsList.append(WindowInfo(app: appName, title: windowTitle))
                }
            }
        }
        
        // 4. Clipboard Data
        let clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
        
        // Formatted Timestamp
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        
        return ContextSnapshot(
            time: timestamp,
            frontmostApp: frontmost,
            runningApps: runningApps,
            windows: windowsList,
            clipboard: clipboardText
        )
    }
}
