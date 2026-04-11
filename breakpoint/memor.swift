import Foundation

class SnapshotManager {
    static let saveDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("BreakPointSnapshots")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()
    
    static func save(snapshot: ContextSnapshot, aiCard: AIResumeCard?, note: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filePrefix = formatter.string(from: Date())
        
        // 1. Save JSON
        if let jsonData = try? JSONEncoder().encode(snapshot) {
            let jsonURL = saveDirectory.appendingPathComponent("\(filePrefix).json")
            try? jsonData.write(to: jsonURL)
        }
        
        // 2. Save Markdown
        var markdown = """
        # BreakPoint Snapshot
        **Time:** \(snapshot.time)
        **User Note:** \(note)
        
        ### AI Summary
        **Status:** \(aiCard?.summary ?? "N/A")
        **Next Step:** \(aiCard?.nextStep ?? "N/A")
        **Improvement:** \(aiCard?.improvement ?? "N/A")
        
        ---
        **Frontmost App:** \(snapshot.frontmostApp)
        
        **Open Windows:**
        """
        
        for window in snapshot.windows {
            markdown += "\n- [\(window.app)] \(window.title)"
        }
        
        markdown += "\n\n**Clipboard Content:**\n```\n\(snapshot.clipboard)\n```\n"
        
        let mdURL = saveDirectory.appendingPathComponent("\(filePrefix).md")
        try? markdown.write(to: mdURL, atomically: true, encoding: .utf8)
    }
}
