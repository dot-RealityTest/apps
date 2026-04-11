import Foundation
import OSLog

/// Orchestrates the "Doom's Moment" feature:
/// 1. Captures current screen context (via ContextCapture)
/// 2. Builds knowledge graph from local sources
/// 3. Pulls LTM workstream events from Pieces OS
/// 4. Sends everything to Pieces OS QGPT (or Ollama fallback) for generation
/// 5. Saves the result to disk and optionally sends notifications
struct DoomsMomentService {
    private let logger = Logger(subsystem: "com.kika.BreakPoint", category: "DoomsMoment")
    private let contextCapture: ContextCapture
    private let ollamaService: OllamaService
    private let fileManager: FileManager
    // Notification configuration
    var discordWebhook: String?
    var telegramBotToken: String?
    var telegramChatId: String?
    var pushoverUserKey: String?
    var pushoverApiToken: String?
    var emailRecipient: String?

    init(
        contextCapture: ContextCapture = ContextCapture(),
        ollamaService: OllamaService = OllamaService(),
        fileManager: FileManager = .default
    ) {
        self.contextCapture = contextCapture
        self.ollamaService = ollamaService
        self.fileManager = fileManager
    }

    /// Check if Pieces OS is available
    func isPiecesAvailable(baseURLString: String) async -> Bool {
        return await makePiecesService(baseURLString: baseURLString).isAvailable()
    }

    /// Gather all context from screen + Local Knowledge Graph + Pieces LTM.
    /// REQUIRES: Pieces OS to be running (localhost:39300)
    func gatherContext(at date: Date = Date(), piecesBaseURLString: String) async throws -> DoomsMomentData {
        logger.info("Gathering context...")
        let piecesService = makePiecesService(baseURLString: piecesBaseURLString)
        
        // 1. Check Pieces OS availability (REQUIRED)
        let piecesAvailable = await piecesService.isAvailable()
        guard piecesAvailable else {
            logger.error("Pieces OS not available - this is required for BreakPoint")
            throw DoomsMomentError.piecesNotAvailable
        }
        logger.info("Pieces OS: available ✓")
        
        // 2. Screen capture
        let snapshot = contextCapture.capture(at: date)
        logger.info("Screen captured: frontmost=\(snapshot.frontmostApp), windows=\(snapshot.windows.count)")

        // 3. Build knowledge graph from local sources
        let localGraph = await LocalKnowledgeGraph.build()
        let knowledgeNodes = localGraph.nodes
        logger.info("LocalKG: \(localGraph.nodes.count) nodes, \(localGraph.edges.count) edges")
        
        // Extract user profile from knowledge graph
        let userProfile = extractUserProfile(from: localGraph)

        // 4. Pull LTM from Pieces OS (REQUIRED)
        let piecesEvents = await piecesService.fetchRecentWorkstreamEvents(limit: 30)
        let piecesSummaries = await piecesService.fetchRecentSummaryNames(limit: 15)
        logger.info("Pieces LTM: events=\(piecesEvents.count), summaries=\(piecesSummaries.count)")

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        return DoomsMomentData(
            time: formatter.string(from: date),
            snapshot: snapshot,
            recentChats: [],
            userProfile: userProfile,
            knowledgeNodes: knowledgeNodes,
            piecesEvents: piecesEvents,
            piecesSummaries: piecesSummaries
        )
    }
    
    /// Extract user profile from knowledge graph
    private func extractUserProfile(from graph: KnowledgeGraph) -> String? {
        let projects = graph.nodes.filter { $0.nodeType == .project }
        let technologies = graph.nodes.filter { $0.nodeType == .technology }
        
        var profile = "Active projects: " + projects.prefix(5).map { $0.label }.joined(separator: ", ")
        if !technologies.isEmpty {
            profile += "\nTechnologies: " + technologies.prefix(10).map { $0.label }.joined(separator: ", ")
        }
        return profile
    }

    /// Generate the Doom's Moment markdown.
    /// Tries Pieces OS QGPT first, falls back to Ollama if Pieces is unavailable.
    func generate(
        data: DoomsMomentData,
        usePieces: Bool,
        piecesBaseURL: String,
        ollamaBaseURL: String,
        ollamaModel: String,
        mode: GenerationMode = .normal,
        userTagsString: String = ""
    ) async -> Result<String, DoomsMomentError> {
        let prompt = Self.buildPrompt(from: data, mode: mode)
        logger.info("Prompt built (\(prompt.count) chars). usePieces=\(usePieces)")
        let piecesService = makePiecesService(baseURLString: piecesBaseURL)

        if usePieces {
            logger.info("Checking Pieces OS availability...")
            let piecesAvailable = await piecesService.isAvailable()
            logger.info("Pieces OS available: \(piecesAvailable)")

            if piecesAvailable {
                logger.info("Sending prompt to Pieces QGPT...")
                let result = await piecesService.askQuestion(prompt: prompt)
                switch result {
                case .success(let text):
                    // Check if Pieces refused to answer
                    let lower = text.lowercased()
                    if lower.contains("i'm sorry") || lower.contains("i can't answer") || lower.contains("i cannot") {
                        logger.warning("Pieces QGPT refused the prompt, falling back to Ollama")
                    } else {
                        logger.info("Pieces QGPT returned \(text.count) chars")
                        return .success(
                            Self.ensureStructuredMarkdown(
                                from: text,
                                time: data.time,
                                mode: mode,
                                userTagsString: userTagsString
                            )
                        )
                    }
                case .failure(let error):
                    logger.error("Pieces QGPT failed: \(error.localizedDescription)")
                }
            }
        }

        // Ollama fallback (or primary if Pieces disabled)
        logger.info("Using Ollama: \(ollamaBaseURL) model=\(ollamaModel)")
        let ollamaResult = await ollamaService.generateText(
            baseURLString: ollamaBaseURL,
            model: ollamaModel,
            prompt: prompt
        )

        switch ollamaResult {
        case .success(let text):
            logger.info("Ollama returned \(text.count) chars")
            return .success(
                Self.ensureStructuredMarkdown(
                    from: text,
                    time: data.time,
                    mode: mode,
                    userTagsString: userTagsString
                )
            )
        case .failure(let error):
            logger.error("Ollama failed: \(error.localizedDescription)")
            return .failure(.generationFailed(error.localizedDescription))
        }
    }

    /// Save the generated Doom's Moment to a markdown file.
    func save(markdown: String, to baseDirectory: URL, fileDate: Date = Date()) throws -> URL {
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let filename = "DoomsMoment_\(formatter.string(from: fileDate)).md"
        let fileURL = baseDirectory.appendingPathComponent(filename)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
        logger.info("Saved to \(fileURL.path)")
        return fileURL
    }
    
    /// Send notification to configured channels
    func sendNotifications(title: String, message: String, attachments: [URL]? = nil) async {
        // Discord
        if let webhook = discordWebhook, !webhook.isEmpty {
            do {
                try await NotificationService.sendDiscord(webhookUrl: webhook, message: "**\(title)**\n\n\(message)")
                logger.info("Sent Discord notification")
            } catch {
                logger.error("Discord notification failed: \(error.localizedDescription)")
            }
        }
        
        // Telegram
        if let botToken = telegramBotToken, let chatId = telegramChatId, !botToken.isEmpty, !chatId.isEmpty {
            do {
                try await NotificationService.sendTelegram(botToken: botToken, chatId: chatId, message: "\(title)\n\n\(message)")
                logger.info("Sent Telegram notification")
            } catch {
                logger.error("Telegram notification failed: \(error.localizedDescription)")
            }
        }
        
        // Pushover
        if let userKey = pushoverUserKey, let apiToken = pushoverApiToken, !userKey.isEmpty, !apiToken.isEmpty {
            do {
                try await NotificationService.sendPushover(userKey: userKey, apiToken: apiToken, message: message, title: title)
                logger.info("Sent Pushover notification")
            } catch {
                logger.error("Pushover notification failed: \(error.localizedDescription)")
            }
        }
        
        // System notification (always available)
        NotificationService.sendSystemNotification(title: title, body: String(message.prefix(200)))
    }

    private func makePiecesService(baseURLString: String) -> PiecesOSService {
        PiecesOSService(baseURLString: baseURLString)
    }

    // MARK: - Prompt

    static func buildPrompt(from data: DoomsMomentData, mode: GenerationMode = .normal) -> String {
        // Screen context
        let frontApp = data.snapshot.frontmostApp
        let windows = data.snapshot.windows.isEmpty
            ? "(none)"
            : data.snapshot.windows.map { w in
                w.title.isEmpty ? "\(w.app): (untitled)" : "\(w.app): \(w.title)"
            }.joined(separator: "\n")
        let clipboard = data.snapshot.clipboard?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? data.snapshot.clipboard!
            : "(empty)"
        let ocrText = data.snapshot.screenshotText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? data.snapshot.screenshotText!
            : "(not available)"

        // Knowledge graph context
        let knowledgeBlock: String
        if data.knowledgeNodes.isEmpty {
            knowledgeBlock = "(none)"
        } else {
            // Group by type for better readability
            let projects = data.knowledgeNodes.filter { $0.nodeType == .project }.prefix(10)
            let technologies = data.knowledgeNodes.filter { $0.nodeType == .technology }.prefix(10)
            let concepts = data.knowledgeNodes.filter { $0.nodeType == .concept }.prefix(10)
            
            var blocks: [String] = []
            if !projects.isEmpty {
                blocks.append("Projects: " + projects.map { $0.label }.joined(separator: ", "))
            }
            if !technologies.isEmpty {
                blocks.append("Technologies: " + technologies.map { $0.label }.joined(separator: ", "))
            }
            if !concepts.isEmpty {
                blocks.append("Concepts: " + concepts.map { $0.label }.joined(separator: ", "))
            }
            knowledgeBlock = blocks.isEmpty ? "(none)" : blocks.joined(separator: "\n")
        }

        // User profile from knowledge graph
        let profileBlock = data.userProfile ?? "(no profile available)"

        // Pieces LTM context
        let piecesEventsBlock: String
        if data.piecesEvents.isEmpty {
            piecesEventsBlock = "(Pieces OS not available)"
        } else {
            piecesEventsBlock = data.piecesEvents.compactMap { event in
                var parts: [String] = []
                if let time = event.createdReadable { parts.append("[\(time)]") }
                if let title = event.title { parts.append(title) }
                if let win = event.windowTitle { parts.append("(\(win))") }
                if let desc = event.description { parts.append("— \(desc)") }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }.joined(separator: "\n")
        }

        let piecesSummariesBlock: String
        if data.piecesSummaries.isEmpty {
            piecesSummariesBlock = "(none)"
        } else {
            piecesSummariesBlock = data.piecesSummaries.map { "- \($0)" }.joined(separator: "\n")
        }

        let contextBlock = """
        ---

        CONTEXT DATA:

        Time: \(data.time)
        Frontmost app: \(frontApp)

        Open windows:
        \(windows)

        Clipboard content:
        \(clipboard)

        Screen text (OCR):
        \(ocrText)

        Knowledge Graph (from Contacts, Calendar, Git, Documents):
        \(knowledgeBlock)

        User profile:
        \(profileBlock)

        Pieces OS Long-Term Memory (recent screen captures):
        \(piecesEventsBlock)

        Active workstreams (from Pieces):
        \(piecesSummariesBlock)
        """

        let modePrompt: String
        switch mode {
        case .normal:
            modePrompt = Self.normalPrompt(time: data.time)
        case .adhd:
            modePrompt = Self.adhdPrompt(time: data.time)
        case .codeMode:
            modePrompt = Self.codeModePrompt(time: data.time)
        case .extra:
            modePrompt = Self.extraPrompt(time: data.time)
        }

        return modePrompt + "\n\n" + contextBlock
    }

    // MARK: - Output Formatting

    private static func ensureStructuredMarkdown(
        from rawText: String,
        time: String,
        mode: GenerationMode,
        userTagsString: String
    ) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let generatedTags = buildHashtags(from: trimmed, mode: mode)
        let hashtagsSection = "\n\n## Hashtags\n\(mergeUserTags(into: generatedTags, userTagsString: userTagsString))"

        if looksStructuredMarkdown(trimmed) {
            if trimmed.contains("\n## Hashtags\n") {
                return mergeHashtagsSection(in: trimmed, userTagsString: userTagsString)
            }
            return trimmed + hashtagsSection
        }

        let lines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        if mode == .extra {
            return structuredExtraMarkdown(from: lines, time: time, userTagsString: userTagsString)
        }

        let summary = lines.prefix(3).joined(separator: " ")
        let tasks = lines.prefix(12).map { line in
            line.hasPrefix("-") ? line : "- \(line)"
        }.joined(separator: "\n")
        let notes = lines.map { "- \($0)" }.joined(separator: "\n")

        return """
        # Doom's Moment — \(time)

        ## Mode
        \(mode.displayName)

        ## Summary
        \(summary.isEmpty ? "No summary generated." : summary)

        ## Action Items
        \(tasks.isEmpty ? "- No action items extracted." : tasks)

        ## Notes
        \(notes.isEmpty ? "- No additional notes." : notes)

        ## Hashtags
        \(mergeUserTags(into: generatedTags, userTagsString: userTagsString))
        """
    }

    private static func looksStructuredMarkdown(_ text: String) -> Bool {
        let hasMainHeader = text.contains("# Doom's Moment")
        let hasSectionHeaders = text.contains("\n## ")
        return hasMainHeader && hasSectionHeaders
    }

    private static func structuredExtraMarkdown(from lines: [String], time: String, userTagsString: String) -> String {
        let summaryParagraphs = paragraphize(lines: Array(lines.prefix(6)), sentenceCount: 3)
        let doingBullets = bulletize(Array(lines.prefix(10)), fallback: "Continue the active work exactly where it was left.")
        let projectSections = projectSectionMarkdown(from: lines)
        let prioritySections = prioritySectionMarkdown(from: lines)
        let decisionSections = decisionsRiskOpenLoopsMarkdown(from: lines)
        let phoneBullets = bulletize(Array(lines.dropFirst(2).prefix(8)), fallback: "Send the most important follow-up message from your phone.")
        let contextBullets = bulletize(Array(lines.dropFirst(1).prefix(6)), fallback: "The current task had momentum and should be resumed before switching context.")
        let resumeSteps = numbered(Array(lines.prefix(4)), fallback: "Re-open the latest generated file and resume the top priority item.")
        let learnBullets = bulletize(Array(lines.dropFirst(5).prefix(5)), fallback: "Research the highest-priority topic connected to the active work.")

        return """
        # Doom's Moment — \(time) [EXTRA]

        ## Mode
        Extra

        ## Executive Summary
        \(summaryParagraphs)

        ## What I Was Doing
        \(doingBullets)

        ## Active Projects
        \(projectSections)

        ## Priority Stack
        \(prioritySections)

        ## Decisions, Risks, and Open Loops
        \(decisionSections)

        ## Phone-Ready Tasks
        \(phoneBullets)

        ## Context Worth Preserving
        \(contextBullets)

        ## Resume Plan
        \(resumeSteps)

        ## Learn & Explore
        \(learnBullets)

        ## Hashtags
        \(mergeUserTags(into: buildHashtags(from: lines.joined(separator: " "), mode: .extra), userTagsString: userTagsString))
        """
    }

    private static func bulletize(_ lines: [String], fallback: String) -> String {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .map { line in
                if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    return line.hasPrefix("- ") ? line : "- " + String(line.dropFirst(2))
                }
                if line.hasPrefix("- [") {
                    return line
                }
                return "- \(line)"
            }

        if cleaned.isEmpty {
            return "- \(fallback)"
        }

        return cleaned.joined(separator: "\n")
    }

    private static func projectSectionMarkdown(from lines: [String]) -> String {
        let candidates = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let projectNames = extractProjectNames(from: candidates)
        if projectNames.isEmpty {
            return """
            ### Main Workstream
            The primary workstream should be resumed first.

            Current status: context was active and should be re-opened carefully.

            Next step: verify the latest changes and continue from the highest-priority item.
            """
        }

        return projectNames.map { name in
            let relatedLines = candidates.filter { line in
                line.localizedCaseInsensitiveContains(name) || relatedProjectKeyword(in: line)
            }

            let status = relatedLines.first ?? "This project was active during the latest session."
            let detail = relatedLines.dropFirst().first ?? "Momentum was already established and worth preserving."
            let nextStep = relatedLines.dropFirst(2).first ?? "Resume by reviewing the latest visible context and continuing the top task."

            return """
            ### \(name)
            Current status: \(status)

            Detail: \(detail)

            Next step: \(nextStep)
            """
        }
        .joined(separator: "\n\n")
    }

    private static func prioritySectionMarkdown(from lines: [String]) -> String {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let high = bulletize(Array(cleaned.prefix(3)), fallback: "Re-open the main workstream and re-establish context.")
        let medium = bulletize(Array(cleaned.dropFirst(3).prefix(4)), fallback: "Handle the next important follow-up after the main task is stable.")
        let low = bulletize(Array(cleaned.dropFirst(7).prefix(4)), fallback: "Capture optional follow-ups once the critical path is clear.")

        return """
        ### High
        \(high)

        ### Medium
        \(medium)

        ### Low
        \(low)
        """
    }

    private static func decisionsRiskOpenLoopsMarkdown(from lines: [String]) -> String {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let decisions = bulletize(
            Array(cleaned.prefix(2)),
            fallback: "Capture the key decision that should be confirmed before continuing."
        )
        let risks = bulletize(
            Array(cleaned.dropFirst(2).prefix(2)),
            fallback: "There is at least one risk worth reviewing before resuming momentum."
        )
        let openLoops = bulletize(
            Array(cleaned.dropFirst(4).prefix(3)),
            fallback: "At least one thread remains open and should be closed deliberately."
        )

        return """
        ### Decisions
        \(decisions)

        ### Risks
        \(risks)

        ### Open Loops
        \(openLoops)
        """
    }

    private static func extractProjectNames(from lines: [String]) -> [String] {
        let stopWords: Set<String> = [
            "The", "This", "That", "There", "When", "Then", "With", "From", "Into", "After",
            "Before", "Current", "Next", "Detail", "High", "Medium", "Low", "Extra", "Mode",
            "Resume", "Phone", "Tasks", "Context", "Executive", "Summary"
        ]

        var names: [String] = []

        for line in lines {
            if let projectMatch = line.range(of: #"(?i)\bproject[s]?:\s*([A-Za-z0-9][A-Za-z0-9 ._\-/]{1,40})"#, options: .regularExpression) {
                let raw = String(line[projectMatch])
                let value = raw.replacingOccurrences(of: #"(?i)\bproject[s]?:\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty == false {
                    names.append(value)
                }
            }

            let words = line
                .replacingOccurrences(of: "[^A-Za-z0-9 ._/-]", with: " ", options: .regularExpression)
                .split(separator: " ")
                .map(String.init)

            if let first = words.first,
               first.count > 2,
               first.first?.isUppercase == true,
               stopWords.contains(first) == false {
                let phrase = words.prefix(3).joined(separator: " ").trimmingCharacters(in: .whitespaces)
                if phrase.isEmpty == false {
                    names.append(phrase)
                }
            }
        }

        let cleaned = names
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-• ").union(.whitespacesAndNewlines)) }
            .filter { $0.isEmpty == false }

        return Array(NSOrderedSet(array: cleaned)).compactMap { $0 as? String }.prefix(3).map { $0 }
    }

    private static func relatedProjectKeyword(in line: String) -> Bool {
        let keywords = ["project", "workstream", "feature", "task", "client", "app", "build", "design"]
        let lower = line.lowercased()
        return keywords.contains { lower.contains($0) }
    }

    private static func numbered(_ lines: [String], fallback: String) -> String {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        if cleaned.isEmpty {
            return "1. \(fallback)"
        }

        return cleaned.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
    }

    private static func paragraphize(lines: [String], sentenceCount: Int) -> String {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        if cleaned.isEmpty {
            return "No detailed summary was generated."
        }

        return stride(from: 0, to: cleaned.count, by: sentenceCount)
            .map { start in
                cleaned[start..<min(start + sentenceCount, cleaned.count)].joined(separator: " ")
            }
            .joined(separator: "\n\n")
    }

    private static func buildHashtags(from text: String, mode: GenerationMode) -> String {
        var tags = ["#doomsmoment", "#breakpoint"]

        switch mode {
        case .normal:
            tags.append("#normalmode")
        case .adhd:
            tags.append("#adhdmode")
        case .codeMode:
            tags.append("#codemode")
        case .extra:
            tags.append("#extra")
        }

        let lowercased = text.lowercased()
        let keywordTags: [(String, String)] = [
            ("swift", "#swift"),
            ("xcode", "#xcode"),
            ("macos", "#macos"),
            ("apple notes", "#applenotes"),
            ("ollama", "#ollama"),
            ("pieces", "#pieces"),
            ("debug", "#debugging"),
            ("bug", "#bugfix"),
            ("refactor", "#refactor"),
            ("api", "#api"),
            ("ui", "#ui"),
            ("ux", "#ux"),
            ("design", "#design"),
            ("research", "#research"),
            ("meeting", "#meeting"),
            ("docs", "#documentation"),
            ("test", "#testing"),
            ("deploy", "#deployment"),
            ("git", "#git"),
            ("prompt", "#prompting")
        ]

        for (keyword, tag) in keywordTags where lowercased.contains(keyword) {
            tags.append(tag)
        }

        return Array(NSOrderedSet(array: tags))
            .compactMap { $0 as? String }
            .joined(separator: " ")
    }

    private static func mergeHashtagsSection(in markdown: String, userTagsString: String) -> String {
        let pattern = #"(?s)(\n## Hashtags\n)(.*?)(\n## |\z)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return markdown
        }

        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        guard let match = regex.firstMatch(in: markdown, options: [], range: range),
              let tagsRange = Range(match.range(at: 2), in: markdown) else {
            return markdown
        }

        let existingTags = markdown[tagsRange].trimmingCharacters(in: .whitespacesAndNewlines)
        let mergedTags = mergeUserTags(into: existingTags, userTagsString: userTagsString)
        return markdown.replacingCharacters(in: tagsRange, with: mergedTags)
    }

    private static func mergeUserTags(into existingTags: String, userTagsString: String) -> String {
        let merged = Array(NSOrderedSet(array: extractHashtagTokens(from: existingTags) + parseUserTags(from: userTagsString)))
            .compactMap { $0 as? String }
        return merged.joined(separator: " ")
    }

    private static func extractHashtagTokens(from text: String) -> [String] {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("#") && $0.count > 1 }
    }

    private static func parseUserTags(from userTagsString: String) -> [String] {
        userTagsString
            .components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .compactMap(sanitizeTag)
    }

    private static func sanitizeTag(_ rawTag: String) -> String? {
        let withoutHash = rawTag.replacingOccurrences(of: "#", with: "")
        let collapsed = withoutHash
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-z0-9\-_]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))

        guard collapsed.isEmpty == false else { return nil }
        return "#\(collapsed)"
    }

    // MARK: - Mode Prompts

    private static func normalPrompt(time: String) -> String {
        """
        You are BreakPoint's "Doom's Moment" generator.
        The user just hit the emergency button — they're about to step away from their computer.
        Your job: produce a DETAILED, COMPREHENSIVE markdown document they can read on their phone.
        Be thorough — extract EVERY actionable item and piece of context you can find.

        OUTPUT FORMAT (Markdown only, no extra commentary):

        # Doom's Moment — \(time)

        ## What I Was Doing
        <6-10 bullets summarizing what the user was actively working on, based on ALL the data below>
        <Be specific — mention app names, file names, project names, URLs, and error messages>
        <Group by project/topic if multiple workstreams are active>

        ## Active Projects
        <List each project/workstream detected with a 1-2 sentence status summary>
        <Include what's working, what's broken, what's next for each>

        ## Todo List
        <10-15 prioritized action items extracted from context>
        <Include immediate tasks, in-progress work, mentioned goals, and follow-ups>
        <Mark urgency: 🔴 urgent (blocking or time-sensitive), 🟡 soon (do today/tomorrow), 🟢 whenever (nice to have)>
        <Be specific — not "fix bug" but "fix the SwiftUI button rendering issue in PopoverView.swift">

        ## Phone Tasks
        <8-12 things they can do RIGHT NOW from their phone while away>
        <Be creative and specific — based on what the user was actually doing>
        <Categories: messages, docs to read, research, emails, calls, apps to check, notes to jot down>

        ## Learn & Level Up
        <5-8 learning tasks based on what the user was working on>
        <Suggest actual topics, docs, tutorials, or concepts to look up>
        <Include search terms they can Google from their phone>

        ---
        Rules:
        - Ground everything in the data above. Do not invent tasks or context.
        - Pieces LTM events are the richest source — prioritize them.
        - Extract EVERY task, todo, goal, and action item you can find.
        - Phone Tasks should be MANY and SPECIFIC.
        - Do NOT include code snippets. Focus on ACTIONABLE tasks only.
        - Keep it scannable — phone screen reading.
        - Use bullet points and short paragraphs. No walls of text.
        - Target 1000-1500 words.
        """
    }

    private static func adhdPrompt(time: String) -> String {
        """
        You are an ADHD-friendly task generator. The user needs to step away from their computer NOW.
        Make the output SHORT, PUNCHY, and SCANNABLE. Zero fluff. Zero walls of text.
        Every item must be ONE short line. No paragraphs. No decorative emojis.
        Use color-coded priority tags to make scanning easy.

        IMPORTANT: Do NOT use emojis anywhere. Use these text color tags instead:
        - [RED] = urgent / do now / blocking
        - [ORANGE] = important / do today
        - [GREEN] = easy win / whenever
        - [BLUE] = research / learning

        OUTPUT FORMAT (Markdown only, no extra commentary):

        # Doom's Moment — \(time)

        ## Brain Dump
        <5-8 SHORT bullets, max 10 words each>
        <What was the user doing? Be specific.>
        <Example: "- Debugging the popover auto-close in MenuBarController">

        ## Quick Wins
        <5-7 tasks that take under 5 minutes each>
        <Start each with an action verb>
        <Tag each with [GREEN]>
        <Example: "- [GREEN] Reply to Mike's Slack about the API">
        <Example: "- [GREEN] Save the open file and commit">

        ## Todo
        <8-12 items, SHORT — max 15 words each>
        <Tag priority: [RED] now, [ORANGE] today, [GREEN] whenever>
        <No explanations, just the task>
        <Example: "- [RED] Fix the SwiftUI button rendering in PopoverView.swift">
        <Example: "- [ORANGE] Add error handling to PiecesOSService timeout">

        ## Phone Tasks
        <8-12 things to do from phone RIGHT NOW>
        <Keep each one SUPER short and actionable>
        <Mix: texts, reads, googles, emails, app checks>
        <Example: "- [ORANGE] Email Sarah re: meeting time">
        <Example: "- [BLUE] Google 'SwiftUI popover sizing best practices'">

        ## Level Up
        <4-6 things to read/watch/learn>
        <Tag all with [BLUE]>
        <Include actual search terms>
        <Example: "- [BLUE] Read Apple docs: NSPopover.behavior options">

        ## Thoughts
        <3-5 observations, ideas, or connections spotted in the context>
        <Things the user might forget if they don't write them down>

        ---
        Rules:
        - ADHD MODE: short lines, color tags, zero fluff, ZERO emojis.
        - Do NOT use any emojis. Use [RED], [ORANGE], [GREEN], [BLUE] tags only.
        - Every bullet = one line. MAX 15 words per bullet.
        - No paragraphs. No sub-explanations. Just tasks.
        - Color tags help ADHD brains prioritize at a glance.
        - Quick Wins section is KEY — easy dopamine hits first.
        - Ground everything in the context data. Do not invent.
        - Target 600-900 words. Dense but scannable.
        """
    }

    private static func codeModePrompt(time: String) -> String {
        """
        You are a senior developer's context-capture tool. The user is stepping away mid-session.
        Generate a TECHNICAL document focused on code, debugging, and development workflow.
        Include actual commands, file paths, error messages, and code snippets.
        Think of this as a dev handoff note — another developer (or future you) should be able to pick up exactly where you left off.

        OUTPUT FORMAT (Markdown only, no extra commentary):

        # Doom's Moment — \(time) [DEV MODE]

        ## Current State
        <What files/projects are open, what branch, what the user was actively editing>
        <Include specific file names, line numbers if visible, and app states>

        ## Active Debug / Problem
        <What problem or feature the user is working on>
        <Include error messages, stack traces, or symptoms visible in context>
        <What has been tried, what hasn't>

        ## Code Tasks
        <10-15 specific development tasks extracted from context>
        <Mark priority: 🔴 blocking, 🟡 important, 🟢 nice-to-have>
        <Be VERY specific — include file names, function names, variable names>
        <Example: "🔴 Fix `handleStatusChange()` in MenuBarController.swift — popover not auto-closing">
        <Example: "🟡 Add error handling to `PiecesOSService.askQuestion()` for timeout case">

        ## Commands to Run
        <5-10 terminal commands the user should run when they get back>
        <Format as code blocks>
        <Include: build commands, test commands, git commands, debug commands>
        <Example: `xcodebuild -scheme BreakPoint -configuration Debug build`>
        <Example: `git diff HEAD~3 --stat`>
        <Example: `curl -s localhost:39300/health | jq .`>

        ## Architecture Notes
        <Key architectural decisions or patterns observed in the current work>
        <Dependencies between components, data flow, state management>
        <Any tech debt or refactoring opportunities spotted>

        ## Research & Docs
        <5-8 specific documentation pages, APIs, or Stack Overflow topics to look up>
        <Include exact URLs or search queries>
        <Focus on the specific technologies and frameworks in use>
        <Example: "Apple docs: NSPopover.behavior — transient vs semitransient">
        <Example: "GitHub: Pieces OS REST API — workstream_events endpoint schema">

        ## Git Status
        <What should be committed, what's staged, what's modified>
        <Suggested commit message based on the work in progress>
        <Branch management suggestions>

        ---
        Rules:
        - DEVELOPER MODE: be technical, specific, and precise.
        - Include actual file paths, function names, class names, and variable names from the context.
        - Code blocks for any commands, snippets, or terminal output.
        - Architecture observations are valuable — note patterns, anti-patterns, and dependencies.
        - Commands to Run is critical — give the user copy-paste-ready commands.
        - Do NOT water down with generic advice. Every item must be grounded in the context.
        - Assume the reader is a senior developer who knows the stack.
        - Target 1200-1800 words. Be thorough and technical.
        """
    }

    private static func extraPrompt(time: String) -> String {
        """
        You are BreakPoint's long-form handoff writer. The user is stepping away and needs a deeply detailed, highly readable record of what matters.
        Generate a rich, organized markdown document that captures priorities, context, momentum, blockers, and next steps.
        This mode must be MORE detailed than Normal mode, but it must NOT include code snippets, terminal commands, stack traces, or developer-only notation.
        Think: executive-quality project handoff for the same person to resume later from their phone.
        Follow the markdown structure exactly and always include every section listed below, even if some sections are brief.

        OUTPUT FORMAT (Markdown only, no extra commentary):

        # Doom's Moment — \(time) [EXTRA]

        ## Mode
        Extra

        ## Executive Summary
        <2-4 short paragraphs explaining the big picture of what was happening>
        <Name the main workstreams, what mattered most, and where the momentum currently is>

        ## What I Was Doing
        <8-12 detailed bullets>
        <Be concrete about apps, documents, projects, conversations, and visible focus shifts>
        <Explain not just the task, but why it seemed important>

        ## Active Projects
        ### <Project / Workstream Name>
        <current status in 1-2 sentences>
        <important detail or context that explains why it matters>
        <next step in 1 sentence>

        ### <Project / Workstream Name>
        <current status in 1-2 sentences>
        <important detail or context that explains why it matters>
        <next step in 1 sentence>

        ## Priority Stack
        ### High
        - <top priority action item with context>
        - <top priority action item with context>

        ### Medium
        - <important follow-up item with context>
        - <important follow-up item with context>

        ### Low
        - <nice-to-have or later item>
        - <nice-to-have or later item>

        ## Decisions, Risks, and Open Loops
        ### Decisions
        - <decision that needs confirmation>
        - <decision that affects what happens next>

        ### Risks
        - <fragile area or possible blocker>
        - <something that could derail progress>

        ### Open Loops
        - <unresolved thread>
        - <follow-up still hanging>

        ## Phone-Ready Tasks
        <8-12 things that can be done away from the desk>
        <Include messages to send, notes to write, docs to read, questions to clarify, research to do, and reminders to set>

        ## Context Worth Preserving
        <5-8 bullets covering subtle but important context>
        <Examples: why a task matters, what changed recently, what thread ties multiple tasks together, what future-you should remember>

        ## Resume Plan
        <A clear re-entry plan for when the user returns>
        <What to look at first, what to verify next, and what order to resume things in>

        ## Learn & Explore
        <5-8 non-code learning/research prompts related to the work>
        <Use plain-language topics and search ideas, not terminal commands or implementation snippets>

        ## Hashtags
        <space-separated hashtags, always include #doomsmoment #breakpoint #extra>

        ---
        Rules:
        - EXTRA MODE: be comprehensive, calm, and high-signal.
        - More detailed than Normal mode, but absolutely no code snippets, terminal commands, or implementation blocks.
        - Do not use developer handoff formatting like command sections or stack traces.
        - Ground every claim in the provided context. Do not invent fake projects or tasks.
        - Prioritize clarity, continuity, and memory preservation over brevity.
        - This should read well on a phone: structured sections, short paragraphs, and strong bullets.
        - Always emit valid Markdown headings exactly as shown above.
        - In Active Projects, always use `###` subsections for each project or workstream.
        - In Priority Stack, always use grouped `### High`, `### Medium`, and `### Low` subsections.
        - In Decisions, Risks, and Open Loops, always use grouped `### Decisions`, `### Risks`, and `### Open Loops` subsections.
        - Target 1400-2000 words.
        """
    }
}

// MARK: - Error

enum DoomsMomentError: Error, Equatable, LocalizedError {
    case generationFailed(String)
    case piecesNotAvailable

    var errorDescription: String? {
        switch self {
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        case .piecesNotAvailable:
            return "Pieces OS is not running. BreakPoint requires Pieces OS (https://pieces.ai) for long-term memory and AI generation. Please install and start Pieces OS, then try again."
        }
    }
}
