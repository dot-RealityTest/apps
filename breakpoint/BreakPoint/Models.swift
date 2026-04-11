import Foundation

struct WindowInfo: Codable, Equatable {
    let app: String
    let title: String
}

struct Snapshot: Codable, Equatable {
    let time: String
    let frontmostApp: String
    let runningApps: [String]
    let windows: [WindowInfo]
    let clipboard: String?
    let screenshotText: String?
    let aiSummary: String?
    let workflow: String?
}

enum SnapshotStatus: Equatable {
    case idle
    case saving
    case success(message: String)
    case error(message: String)

    var message: String {
        switch self {
        case .idle:
            return "Capture your current context before stepping away."
        case .saving:
            return "Saving snapshot..."
        case .success(let message), .error(let message):
            return message
        }
    }
}

struct SnapshotSaveResult: Equatable {
    let directoryURL: URL
    let jsonURL: URL
    let contextMarkdownURL: URL
    let summaryMarkdownURL: URL
    let workflowMarkdownURL: URL
}

// MARK: - Generation Mode

enum GenerationMode: String, CaseIterable, Equatable {
    case normal = "normal"
    case adhd = "adhd"
    case codeMode = "codeMode"
    case extra = "extra"

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .adhd: return "ADHD"
        case .codeMode: return "Code Mode"
        case .extra: return "Extra"
        }
    }

    var description: String {
        switch self {
        case .normal: return "Balanced output with todos, phone tasks & learning"
        case .adhd: return "Short bullets, emojis, dopamine-friendly, no walls of text"
        case .codeMode: return "Technical output with code snippets, commands & debug steps"
        case .extra: return "Extra-detailed handoff with rich context, priorities & next steps, but no code"
        }
    }
}

enum ExportPreset: String, CaseIterable, Equatable {
    case file = "file"
    case notes = "notes"
    case fileAndNotes = "fileAndNotes"

    var displayName: String {
        switch self {
        case .file:
            return "File"
        case .notes:
            return "Notes"
        case .fileAndNotes:
            return "File + Notes"
        }
    }

    var description: String {
        switch self {
        case .file:
            return "Save structured markdown to the export folder."
        case .notes:
            return "Send the generated Doom's Moment to Apple Notes only."
        case .fileAndNotes:
            return "Save a markdown file and create a matching Apple Note."
        }
    }

    var includesFileExport: Bool {
        switch self {
        case .file, .fileAndNotes:
            return true
        case .notes:
            return false
        }
    }

    var includesNotesExport: Bool {
        switch self {
        case .notes, .fileAndNotes:
            return true
        case .file:
            return false
        }
    }
}

// MARK: - Doom's Moment

struct DoomsMomentData: Codable, Equatable {
    let time: String
    let snapshot: Snapshot
    let recentChats: [ChatEntry]
    let userProfile: String?
    let knowledgeNodes: [KnowledgeNode]
    let piecesEvents: [WorkstreamEvent]
    let piecesSummaries: [String]
}

struct ChatEntry: Codable, Equatable {
    let sender: String
    let text: String
    let createdAt: String
}

enum DoomsMomentStatus: Equatable {
    case idle
    case generating
    case success(message: String)
    case error(message: String)

    var message: String {
        switch self {
        case .idle:
            return "Generate a full context dump with todos & phone tasks."
        case .generating:
            return "Building your Doom's Moment..."
        case .success(let message), .error(let message):
            return message
        }
    }
}
