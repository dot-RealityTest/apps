import AppKit
import CoreGraphics
import Foundation
import Vision

struct ContextCapture {
    func capture(at date: Date = Date()) -> Snapshot {
        let frontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        let runningApps = Self.normalizeRunningApplicationNames(
            NSWorkspace.shared.runningApplications.map(\.localizedName)
        )
        let visibleWindows = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
        let windows = Self.normalizeWindows(from: visibleWindows)
        let clipboard = NSPasteboard.general.string(forType: .string)
        let screenshotText = captureScreenshotText()

        return Snapshot(
            time: Self.displayTimestampFormatter.string(from: date),
            frontmostApp: frontmostApp,
            runningApps: runningApps,
            windows: windows,
            clipboard: clipboard,
            screenshotText: screenshotText,
            aiSummary: nil,
            workflow: nil
        )
    }

    func captureScreenshotText() -> String? {
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
            let recognizedText = (request.results ?? [])
                .compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return recognizedText.isEmpty ? nil : recognizedText
        } catch {
            return nil
        }
    }

    static func normalizeRunningApplicationNames(_ names: [String?]) -> [String] {
        let cleanedNames = names.compactMap { rawName -> String? in
            guard let rawName else { return nil }
            let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty ? nil : trimmedName
        }

        return Array(Set(cleanedNames)).sorted()
    }

    static func normalizeWindows(from rawWindows: [[String: Any]]) -> [WindowInfo] {
        rawWindows.compactMap { window in
            guard
                let ownerName = window[kCGWindowOwnerName as String] as? String
            else {
                return nil
            }

            let appName = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard appName.isEmpty == false else {
                return nil
            }

            let windowTitle = (window[kCGWindowName as String] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return WindowInfo(app: appName, title: windowTitle)
        }
    }

    private static let displayTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()
}
