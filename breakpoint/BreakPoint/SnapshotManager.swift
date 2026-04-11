import Foundation

struct SnapshotManager {
    private let baseDirectoryProvider: () -> URL
    private let fileManager: FileManager

    init(
        baseDirectory: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("BreakPointSnapshots", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.baseDirectoryProvider = { baseDirectory }
        self.fileManager = fileManager
    }

    init(
        baseDirectoryProvider: @escaping () -> URL,
        fileManager: FileManager = .default
    ) {
        self.baseDirectoryProvider = baseDirectoryProvider
        self.fileManager = fileManager
    }

    func jsonData(for snapshot: Snapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    func contextMarkdown(for snapshot: Snapshot) -> String {
        let runningApps = snapshot.runningApps.isEmpty ? "(none)" : snapshot.runningApps.joined(separator: "\n")
        let windows = snapshot.windows.isEmpty
            ? "(none)"
            : snapshot.windows.map { window in
                window.title.isEmpty ? "\(window.app): (untitled)" : "\(window.app): \(window.title)"
            }.joined(separator: "\n")
        let clipboard = snapshot.clipboard?.isEmpty == false ? snapshot.clipboard! : "(empty)"
        let screenshotText = snapshot.screenshotText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? snapshot.screenshotText!
            : "(not extracted)"

        return """
        # BreakPoint Context

        Time: \(snapshot.time)

        Frontmost App:
        \(snapshot.frontmostApp)

        Running Apps:
        \(runningApps)

        Open Windows:
        \(windows)

        Clipboard:
        \(clipboard)

        Screenshot Text:
        \(screenshotText)
        """
    }

    func summaryMarkdown(for snapshot: Snapshot) -> String {
        let aiSummary = snapshot.aiSummary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? snapshot.aiSummary!
            : "(not generated)"

        return """
        # BreakPoint AI Summary

        Time: \(snapshot.time)

        \(aiSummary)
        """
    }

    func workflowMarkdown(for snapshot: Snapshot) -> String {
        let workflow = snapshot.workflow?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? snapshot.workflow!
            : "(not generated)"

        return """
        # BreakPoint Workflow

        Time: \(snapshot.time)

        \(workflow)
        """
    }

    func save(snapshot: Snapshot, fileDate: Date = Date()) throws -> SnapshotSaveResult {
        let baseDirectory = baseDirectoryProvider()
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        let filename = Self.filenameFormatter.string(from: fileDate)
        let jsonURL = baseDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        let contextMarkdownURL = baseDirectory
            .appendingPathComponent("\(filename)_context")
            .appendingPathExtension("md")
        let summaryMarkdownURL = baseDirectory
            .appendingPathComponent("\(filename)_summary")
            .appendingPathExtension("md")
        let workflowMarkdownURL = baseDirectory
            .appendingPathComponent("\(filename)_workflow")
            .appendingPathExtension("md")

        try jsonData(for: snapshot).write(to: jsonURL, options: .atomic)
        try contextMarkdown(for: snapshot).write(to: contextMarkdownURL, atomically: true, encoding: .utf8)
        try summaryMarkdown(for: snapshot).write(to: summaryMarkdownURL, atomically: true, encoding: .utf8)
        try workflowMarkdown(for: snapshot).write(to: workflowMarkdownURL, atomically: true, encoding: .utf8)

        return SnapshotSaveResult(
            directoryURL: baseDirectory,
            jsonURL: jsonURL,
            contextMarkdownURL: contextMarkdownURL,
            summaryMarkdownURL: summaryMarkdownURL,
            workflowMarkdownURL: workflowMarkdownURL
        )
    }

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
