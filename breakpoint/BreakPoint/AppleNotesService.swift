import Foundation
import OSLog

/// Sends generated Doom's Moment markdown to Apple Notes via AppleScript.
struct AppleNotesService {
    private static let logger = Logger(subsystem: "com.kika.Doom", category: "AppleNotes")

    enum NotesError: LocalizedError {
        case tempFileWriteFailed(String)
        case tempScriptWriteFailed(String)
        case scriptExecutionFailed(String)
        case processLaunchFailed(String)

        var errorDescription: String? {
            switch self {
            case .tempFileWriteFailed(let message),
                 .tempScriptWriteFailed(let message),
                 .scriptExecutionFailed(let message),
                 .processLaunchFailed(let message):
                return message
            }
        }
    }

    /// The folder name in Apple Notes where Doom's Moments are stored.
    static let folderName = "Doom Moments"

    /// Sections whose bullet items become native checklists.
    private static let checklistSections: Set<String> = [
        "todo list",
        "phone tasks",
        "learn & level up",
    ]

    /// Creates a new note in Apple Notes from a markdown string.
    /// Todo/Phone/Learn sections get native Apple Notes checklists.
    static func createNote(markdown: String, title: String) async throws {
        let htmlBody = markdownToHTML(markdown)

        // Write HTML to a temp file to avoid AppleScript string escaping issues
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("doom_note_\(UUID().uuidString).html")

        do {
            try htmlBody.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to write temp HTML: \(error.localizedDescription)")
            throw NotesError.tempFileWriteFailed("Notes export failed: \(error.localizedDescription)")
        }

        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Step 1: Create the note with HTML body
        // Step 2: Show the note, select all, apply Checklist format via Format menu
        let script = """
        set bodyFile to POSIX file "\(tempURL.path)"
        set htmlContent to read bodyFile as «class utf8»

        tell application "Notes"
            set targetAccount to first account whose name is "On My Mac"
            set folderFound to false
            repeat with f in folders of targetAccount
                if name of f is "\(folderName)" then
                    set folderFound to true
                    set targetFolder to f
                    exit repeat
                end if
            end repeat

            if not folderFound then
                make new folder at targetAccount with properties {name:"\(folderName)"}
                delay 0.5
                repeat with f in folders of targetAccount
                    if name of f is "\(folderName)" then
                        set targetFolder to f
                        exit repeat
                    end if
                end repeat
            end if

            set newNote to make new note at targetFolder with properties {name:"\(escapeForAppleScript(title))", body:htmlContent}
            show newNote
        end tell

        delay 0.8

        tell application "Notes" to activate
        delay 0.5

        tell application "System Events"
            tell process "Notes"
                keystroke "a" using command down
                delay 0.3
                click menu item "Checklist" of menu 1 of menu bar item "Format" of menu bar 1
                delay 0.3
                -- Click somewhere to deselect
                key code 125 -- down arrow
                delay 0.1
            end tell
        end tell
        """

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("doom_note_script_\(UUID().uuidString).scpt")

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to write temp script: \(error.localizedDescription)")
            throw NotesError.tempScriptWriteFailed("Notes export failed: \(error.localizedDescription)")
        }

        defer { try? FileManager.default.removeItem(at: scriptURL) }

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = [scriptURL.path]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                logger.info("Note created in Apple Notes with checklists: \(title)")
            } else {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown error"
                logger.error("AppleScript failed (\(process.terminationStatus)): \(errorString)")
                throw NotesError.scriptExecutionFailed("Notes export failed: \(errorString)")
            }
        } catch {
            logger.error("Failed to run AppleScript: \(error.localizedDescription)")
            throw NotesError.processLaunchFailed("Notes export failed: \(error.localizedDescription)")
        }
    }

    /// Opens Apple Notes and tries to focus the Doom Moments folder.
    /// Falls back to simply activating Notes if folder lookup fails.
    static func openDoomMoments() {
        let script = """
        tell application "Notes"
            activate
            try
                set targetAccount to first account whose name is "On My Mac"
                repeat with f in folders of targetAccount
                    if name of f is "\(folderName)" then
                        show f
                        exit repeat
                    end if
                end repeat
            end try
        end tell
        """

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try process.run()
        } catch {
            logger.error("Failed to open Apple Notes: \(error.localizedDescription)")
        }
    }

    private static func escapeForAppleScript(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Convert markdown to Apple Notes HTML.
    /// Uses <div> for each line (Apple Notes' native format).
    private static func markdownToHTML(_ md: String) -> String {
        let lines = md.components(separatedBy: "\n")
        var html: [String] = []

        for line in lines {
            var processed = line

            // Headings — use Apple Notes native heading spans
            if processed.hasPrefix("### ") {
                let text = String(processed.dropFirst(4))
                html.append("<div><b>\(text)</b></div>")
                continue
            } else if processed.hasPrefix("## ") {
                let text = String(processed.dropFirst(3))
                html.append("<div><b><span style=\"font-size: 18px\">\(text)</span></b></div>")
                continue
            } else if processed.hasPrefix("# ") {
                let text = String(processed.dropFirst(2))
                html.append("<div><b><span style=\"font-size: 24px\">\(text)</span></b></div>")
                continue
            }

            // Horizontal rule — skip, not needed in checklist note
            if processed.trimmingCharacters(in: .whitespaces) == "---" {
                continue
            }

            // Bold **text**
            processed = processed.replacingOccurrences(
                of: "\\*\\*(.+?)\\*\\*",
                with: "<b>$1</b>",
                options: .regularExpression
            )

            // Color tags [RED], [ORANGE], [GREEN], [BLUE]
            processed = processed
                .replacingOccurrences(of: "[RED]", with: "<span style=\"color: #E53935\"><b>RED</b></span>")
                .replacingOccurrences(of: "[ORANGE]", with: "<span style=\"color: #FB8C00\"><b>ORANGE</b></span>")
                .replacingOccurrences(of: "[GREEN]", with: "<span style=\"color: #43A047\"><b>GREEN</b></span>")
                .replacingOccurrences(of: "[BLUE]", with: "<span style=\"color: #1E88E5\"><b>BLUE</b></span>")

            // Bullet points — strip the dash/asterisk prefix
            if processed.hasPrefix("- ") || processed.hasPrefix("* ") {
                let text = String(processed.dropFirst(2))
                html.append("<div>\(text)</div>")
                continue
            }

            // Empty lines
            if processed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                html.append("<div><br></div>")
                continue
            }

            html.append("<div>\(processed)</div>")
        }

        return html.joined(separator: "\n")
    }
}
