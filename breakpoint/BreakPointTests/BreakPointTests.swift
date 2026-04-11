import XCTest
@testable import BreakPoint

final class BreakPointTests: XCTestCase {
    @MainActor
    func testAppSettingsDefaultsToBreakPointSnapshotsDirectory() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)

        XCTAssertTrue(settings.exportDirectoryPath.hasSuffix("/BreakPointSnapshots"))
        XCTAssertEqual(settings.ollamaBaseURLString, "http://127.0.0.1:11434")
        XCTAssertEqual(settings.ollamaModel, "llama3.2")
    }

    @MainActor
    func testAppSettingsPersistsUpdatedValues() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        settings.exportDirectoryPath = "/tmp/Exports"
        settings.ollamaBaseURLString = "http://localhost:11434"
        settings.ollamaModel = "mistral"

        let reloaded = AppSettings(userDefaults: defaults)

        XCTAssertEqual(reloaded.exportDirectoryPath, "/tmp/Exports")
        XCTAssertEqual(reloaded.ollamaBaseURLString, "http://localhost:11434")
        XCTAssertEqual(reloaded.ollamaModel, "mistral")
    }

    @MainActor
    func testExportDirectoryURLExpandsTildePath() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        settings.exportDirectoryPath = "~/BreakPointSnapshots"

        XCTAssertEqual(
            settings.exportDirectoryURL.path,
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("BreakPointSnapshots", isDirectory: true)
                .path
        )
    }

    @MainActor
    func testExportDirectoryURLFallsBackWhenPathIsBlank() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        settings.exportDirectoryPath = "   "

        XCTAssertTrue(settings.exportDirectoryURL.path.hasSuffix("/BreakPointSnapshots"))
    }

    func testSnapshotEncodesExpectedJSONSchema() throws {
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode", "Safari", "Terminal"],
            windows: [
                WindowInfo(app: "Xcode", title: "ContentView.swift"),
                WindowInfo(app: "Safari", title: "SwiftUI documentation")
            ],
            clipboard: "current clipboard text",
            screenshotText: "Build Succeeded\nDeploy Next",
            aiSummary: "- You were editing SwiftUI code.\n- Reopen Xcode and Safari first.",
            workflow: "## Goal\nShip the build"
        )

        let data = try SnapshotManager().jsonData(for: snapshot)
        let jsonObject = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(jsonObject["time"] as? String, "2026-03-11T15:20")
        XCTAssertEqual(jsonObject["frontmostApp"] as? String, "Xcode")
        XCTAssertEqual(jsonObject["runningApps"] as? [String], ["Xcode", "Safari", "Terminal"])

        let windows = try XCTUnwrap(jsonObject["windows"] as? [[String: String]])
        XCTAssertEqual(windows[0]["app"], "Xcode")
        XCTAssertEqual(windows[0]["title"], "ContentView.swift")
        XCTAssertEqual(jsonObject["clipboard"] as? String, "current clipboard text")
        XCTAssertEqual(jsonObject["screenshotText"] as? String, "Build Succeeded\nDeploy Next")
        XCTAssertEqual(jsonObject["aiSummary"] as? String, "- You were editing SwiftUI code.\n- Reopen Xcode and Safari first.")
        XCTAssertEqual(jsonObject["workflow"] as? String, "## Goal\nShip the build")
    }

    func testContextMarkdownGenerationIncludesCapturedSections() {
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode", "Safari", "Terminal"],
            windows: [
                WindowInfo(app: "Xcode", title: "ContentView.swift"),
                WindowInfo(app: "Safari", title: "SwiftUI documentation")
            ],
            clipboard: "clipboard body",
            screenshotText: "Task Board\nRelease Checklist",
            aiSummary: "- Resume in Xcode.\n- Safari has docs open.",
            workflow: "## Goal\nFinish release"
        )

        let markdown = SnapshotManager().contextMarkdown(for: snapshot)

        XCTAssertTrue(markdown.contains("# BreakPoint Context"))
        XCTAssertTrue(markdown.contains("Time: 2026-03-11T15:20"))
        XCTAssertTrue(markdown.contains("Frontmost App:\nXcode"))
        XCTAssertTrue(markdown.contains("Running Apps:\nXcode\nSafari\nTerminal"))
        XCTAssertTrue(markdown.contains("Open Windows:\nXcode: ContentView.swift\nSafari: SwiftUI documentation"))
        XCTAssertTrue(markdown.contains("Clipboard:\nclipboard body"))
        XCTAssertTrue(markdown.contains("Screenshot Text:\nTask Board\nRelease Checklist"))
        XCTAssertFalse(markdown.contains("AI Summary"))
    }

    func testSummaryMarkdownGenerationIncludesOnlyAiSummary() {
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode", "Safari", "Terminal"],
            windows: [
                WindowInfo(app: "Xcode", title: "ContentView.swift"),
                WindowInfo(app: "Safari", title: "SwiftUI documentation")
            ],
            clipboard: "clipboard body",
            screenshotText: "Task Board\nRelease Checklist",
            aiSummary: "- Resume in Xcode.\n- Safari has docs open.",
            workflow: "## Goal\nFinish release"
        )

        let markdown = SnapshotManager().summaryMarkdown(for: snapshot)

        XCTAssertTrue(markdown.contains("# BreakPoint AI Summary"))
        XCTAssertTrue(markdown.contains("Time: 2026-03-11T15:20"))
        XCTAssertTrue(markdown.contains("- Resume in Xcode.\n- Safari has docs open."))
        XCTAssertFalse(markdown.contains("Running Apps"))
    }

    func testWorkflowMarkdownGenerationIncludesWorkflowOnly() {
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode", "Safari", "Terminal"],
            windows: [
                WindowInfo(app: "Xcode", title: "ContentView.swift"),
                WindowInfo(app: "Safari", title: "SwiftUI documentation")
            ],
            clipboard: "clipboard body",
            screenshotText: "Task Board\nRelease Checklist",
            aiSummary: "- Resume in Xcode.\n- Safari has docs open.",
            workflow: "## Goal\nFinish release\n\n## Next Actions\nShip beta"
        )

        let markdown = SnapshotManager().workflowMarkdown(for: snapshot)

        XCTAssertTrue(markdown.contains("# BreakPoint Workflow"))
        XCTAssertTrue(markdown.contains("Time: 2026-03-11T15:20"))
        XCTAssertTrue(markdown.contains("## Goal\nFinish release"))
        XCTAssertTrue(markdown.contains("## Next Actions\nShip beta"))
        XCTAssertFalse(markdown.contains("Running Apps"))
    }

    func testSaveSnapshotCreatesJSONAndSeparateMarkdownFiles() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode"],
            windows: [WindowInfo(app: "Xcode", title: "ContentView.swift")],
            clipboard: nil,
            screenshotText: nil,
            aiSummary: nil,
            workflow: nil
        )
        let manager = SnapshotManager(baseDirectory: temporaryDirectory)

        let result = try manager.save(snapshot: snapshot, fileDate: Self.fixedDate)

        XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryDirectory.path))
        XCTAssertEqual(result.jsonURL.deletingPathExtension().lastPathComponent, "2026-03-11_15-20-00")
        XCTAssertEqual(result.contextMarkdownURL.deletingPathExtension().lastPathComponent, "2026-03-11_15-20-00_context")
        XCTAssertEqual(result.summaryMarkdownURL.deletingPathExtension().lastPathComponent, "2026-03-11_15-20-00_summary")
        XCTAssertEqual(result.workflowMarkdownURL.deletingPathExtension().lastPathComponent, "2026-03-11_15-20-00_workflow")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.jsonURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.contextMarkdownURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.summaryMarkdownURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.workflowMarkdownURL.path))
    }

    func testNormalizeRunningApplicationNamesDropsMissingAndDuplicates() {
        let names = ContextCapture.normalizeRunningApplicationNames([
            "Xcode",
            nil,
            "Safari",
            "Xcode",
            "  "
        ])

        XCTAssertEqual(names, ["Safari", "Xcode"])
    }

    func testNormalizeWindowsIgnoresMissingOwnerAndKeepsEmptyTitles() {
        let rawWindows: [[String: Any]] = [
            [
                kCGWindowOwnerName as String: "Xcode",
                kCGWindowName as String: "ContentView.swift"
            ],
            [
                kCGWindowOwnerName as String: "Safari"
            ],
            [
                kCGWindowName as String: "Orphaned Window"
            ]
        ]

        let windows = ContextCapture.normalizeWindows(from: rawWindows)

        XCTAssertEqual(windows, [
            WindowInfo(app: "Xcode", title: "ContentView.swift"),
            WindowInfo(app: "Safari", title: "")
        ])
    }

    @MainActor
    func testContextMenuIncludesPropertiesAndCloseAppActions() {
        let menu = MenuBarController.makeContextMenu(target: nil)
        let itemTitles = menu.items.map { $0.title }

        XCTAssertEqual(itemTitles, ["Capture", "Properties", "Close App"])
    }

    func testOllamaServiceReportsMatchingModel() async throws {
        let session = try makeSession(statusCode: 200, body: """
        {"models":[{"name":"llama3.2:latest"},{"name":"mistral:latest"}]}
        """)
        let service = OllamaService(session: session)

        let result = await service.testConnection(baseURLString: "http://localhost:11434", model: "llama3.2")

        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Connected"))
            XCTAssertTrue(message.contains("llama3.2"))
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testOllamaServiceReportsMissingModel() async throws {
        let session = try makeSession(statusCode: 200, body: """
        {"models":[{"name":"mistral:latest"}]}
        """)
        let service = OllamaService(session: session)

        let result = await service.testConnection(baseURLString: "http://localhost:11434", model: "llama3.2")

        switch result {
        case .success(let message):
            XCTFail("Expected failure, got \(message)")
        case .failure(let error):
            XCTAssertEqual(error, .missingModel("llama3.2"))
        }
    }

    func testOllamaServiceRejectsInvalidURL() async {
        let service = OllamaService(session: .shared)
        let result = await service.testConnection(baseURLString: "not-a-url", model: "llama3.2")

        switch result {
        case .success(let message):
            XCTFail("Expected failure, got \(message)")
        case .failure(let error):
            XCTAssertEqual(error, .invalidBaseURL)
        }
    }

    func testOllamaServiceGeneratesSummary() async throws {
        let session = try makeSession(statusCode: 200, body: """
        {"response":"- You were coding in Xcode.\\n- Reopen Safari docs next."}
        """)
        let service = OllamaService(session: session)
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: ["Xcode", "Safari"],
            windows: [WindowInfo(app: "Xcode", title: "PopoverView.swift")],
            clipboard: "let value = 1",
            screenshotText: "Pipeline Status\nDeploy Pending",
            aiSummary: nil,
            workflow: nil
        )

        let result = await service.generateSummary(
            baseURLString: "http://localhost:11434",
            model: "llama3.2",
            snapshot: snapshot
        )

        switch result {
        case .success(let summary):
            XCTAssertTrue(summary.contains("You were coding in Xcode"))
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testOllamaServiceRejectsBlankModelForSummaryGeneration() async {
        let service = OllamaService(session: .shared)
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Xcode",
            runningApps: [],
            windows: [],
            clipboard: nil,
            screenshotText: nil,
            aiSummary: nil,
            workflow: nil
        )

        let result = await service.generateSummary(
            baseURLString: "http://localhost:11434",
            model: "   ",
            snapshot: snapshot
        )

        switch result {
        case .success(let summary):
            XCTFail("Expected failure, got \(summary)")
        case .failure(let error):
            XCTAssertEqual(error, .missingModel)
        }
    }

    func testOllamaServiceGeneratesWorkflowFromScreenshotText() async throws {
        let session = try makeSession(statusCode: 200, body: """
        {"response":"## Goal\\nShip the release\\n\\n## Next Actions\\nOpen the deploy checklist"}
        """)
        let service = OllamaService(session: session)
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Safari",
            runningApps: ["Safari"],
            windows: [WindowInfo(app: "Safari", title: "Release Dashboard")],
            clipboard: nil,
            screenshotText: "Release Dashboard\nDeploy Checklist\nPending",
            aiSummary: nil,
            workflow: nil
        )

        let result = await service.generateWorkflow(
            baseURLString: "http://localhost:11434",
            model: "llama3.2",
            snapshot: snapshot
        )

        switch result {
        case .success(let workflow):
            XCTAssertTrue(workflow.contains("## Goal"))
            XCTAssertTrue(workflow.contains("deploy checklist"))
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testOllamaServiceReportsMissingScreenshotTextForWorkflowGeneration() async {
        let service = OllamaService(session: .shared)
        let snapshot = Snapshot(
            time: "2026-03-11T15:20",
            frontmostApp: "Safari",
            runningApps: [],
            windows: [],
            clipboard: nil,
            screenshotText: nil,
            aiSummary: nil,
            workflow: nil
        )

        let result = await service.generateWorkflow(
            baseURLString: "http://localhost:11434",
            model: "llama3.2",
            snapshot: snapshot
        )

        switch result {
        case .success(let workflow):
            XCTFail("Expected failure, got \(workflow)")
        case .failure(let error):
            XCTAssertEqual(error, .missingSourceText)
        }
    }

    private static let fixedDate = Date(timeIntervalSince1970: 1_773_235_200)

    private func makeSession(statusCode: Int, body: String) throws -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }
        return URLSession(configuration: configuration)
    }

}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
