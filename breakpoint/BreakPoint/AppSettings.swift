import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private enum Keys {
        static let exportDirectoryPath = "exportDirectoryPath"
        static let exportPreset = "exportPreset"
        static let ollamaBaseURLString = "ollamaBaseURLString"
        static let ollamaModel = "ollamaModel"
        static let piecesBaseURLString = "piecesBaseURLString"
        static let userTagsString = "userTagsString"
        static let usePiecesForGeneration = "usePiecesForGeneration"
        static let generationMode = "generationMode"
    }

    var exportDirectoryPath: String {
        didSet {
            userDefaults.set(exportDirectoryPath, forKey: Keys.exportDirectoryPath)
        }
    }

    var exportPreset: ExportPreset {
        didSet {
            userDefaults.set(exportPreset.rawValue, forKey: Keys.exportPreset)
        }
    }

    var ollamaBaseURLString: String {
        didSet {
            userDefaults.set(ollamaBaseURLString, forKey: Keys.ollamaBaseURLString)
        }
    }

    var ollamaModel: String {
        didSet {
            userDefaults.set(ollamaModel, forKey: Keys.ollamaModel)
        }
    }

    var piecesBaseURLString: String {
        didSet {
            userDefaults.set(piecesBaseURLString, forKey: Keys.piecesBaseURLString)
        }
    }

    var userTagsString: String {
        didSet {
            userDefaults.set(userTagsString, forKey: Keys.userTagsString)
        }
    }

    var usePiecesForGeneration: Bool {
        didSet {
            userDefaults.set(usePiecesForGeneration, forKey: Keys.usePiecesForGeneration)
        }
    }

    var generationMode: GenerationMode {
        didSet {
            userDefaults.set(generationMode.rawValue, forKey: Keys.generationMode)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.exportDirectoryPath = userDefaults.string(forKey: Keys.exportDirectoryPath)
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("BreakPointSnapshots", isDirectory: true)
                .path
        self.exportPreset = userDefaults.string(forKey: Keys.exportPreset)
            .flatMap { ExportPreset(rawValue: $0) } ?? .fileAndNotes
        self.ollamaBaseURLString = userDefaults.string(forKey: Keys.ollamaBaseURLString)
            ?? "http://127.0.0.1:11434"
        self.ollamaModel = userDefaults.string(forKey: Keys.ollamaModel)
            ?? "llama3.2"
        self.piecesBaseURLString = userDefaults.string(forKey: Keys.piecesBaseURLString)
            ?? "http://localhost:39300"
        self.userTagsString = userDefaults.string(forKey: Keys.userTagsString) ?? ""
        // Default to true if never set
        if userDefaults.object(forKey: Keys.usePiecesForGeneration) != nil {
            self.usePiecesForGeneration = userDefaults.bool(forKey: Keys.usePiecesForGeneration)
        } else {
            self.usePiecesForGeneration = true
        }
        self.generationMode = userDefaults.string(forKey: Keys.generationMode)
            .flatMap { GenerationMode(rawValue: $0) } ?? .normal
    }

    var exportDirectoryURL: URL {
        let trimmedPath = exportDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPath.isEmpty == false else {
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("BreakPointSnapshots", isDirectory: true)
        }

        let expandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: expandedPath, isDirectory: true).standardizedFileURL
    }
}
