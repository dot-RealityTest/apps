import Foundation

/// Extracts projects from Documents folder and Git repositories
struct ProjectExtractor {
    
    // MARK: - Git Repositories
    
    /// Find all git repositories in common project directories
    static func findGitRepos() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        // Common project locations
        let projectPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Projects"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("_KIKA_MAIN/Projects"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("projects"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".openclaw/workspace"),
        ]
        
        for path in projectPaths {
            let repos = scanForGitRepos(in: path, maxDepth: 3)
            nodes.append(contentsOf: repos)
        }
        
        return nodes.removingDuplicates()
    }
    
    /// Scan directory for git repositories
    private static func scanForGitRepos(in directory: URL, maxDepth: Int) -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return nodes }
        
        var currentDepth = 0
        
        for case let url as URL in enumerator {
            // Check depth
            let depth = url.pathComponents.count - directory.pathComponents.count
            if depth > maxDepth { continue }
            
            // Check if it's a git repo
            if url.lastPathComponent == ".git" {
                let repoURL = url.deletingLastPathComponent()
                if let node = createProjectNode(from: repoURL) {
                    nodes.append(node)
                }
                enumerator.skipDescendants()
            }
        }
        
        return nodes
    }
    
    /// Create KnowledgeNode from git repository
    private static func createProjectNode(from repoURL: URL) -> KnowledgeNode? {
        let projectName = repoURL.lastPathComponent
        
        // Get recent commit date
        let lastCommitDate = getLastCommitDate(in: repoURL)
        
        // Detect languages
        let languages = detectLanguages(in: repoURL)
        
        // Check for common project files
        let projectType = detectProjectType(in: repoURL)
        
        return KnowledgeNode(
            label: projectName,
            nodeType: .project,
            source: .git,
            lastSeen: lastCommitDate,
            metadata: [
                "path": repoURL.path,
                "languages": languages,
                "type": projectType
            ]
        )
    }
    
    /// Get last commit date from git log
    private static func getLastCommitDate(in repoURL: URL) -> Date {
        let task = Process()
        task.currentDirectoryURL = repoURL
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["log", "-1", "--format=%ct"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let timestamp = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let unixTime = Double(timestamp) {
                return Date(timeIntervalSince1970: unixTime)
            }
        } catch {}
        
        return Date()
    }
    
    /// Detect programming languages in repo
    private static func detectLanguages(in repoURL: URL) -> String {
        var languageCounts: [String: Int] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: repoURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return "" }
        
        for case let url as URL in enumerator {
            // Skip common non-source directories
            let path = url.path
            if path.contains("node_modules") ||
               path.contains(".git") ||
               path.contains("build") ||
               path.contains("dist") ||
               path.contains("DerivedData") {
                continue
            }
            
            let ext = url.pathExtension.lowercased()
            if let language = languageMapping[ext] {
                languageCounts[language, default: 0] += 1
            }
        }
        
        // Return top 3 languages
        let sorted = languageCounts.sorted { $0.value > $1.value }
        return sorted.prefix(3).map { $0.key }.joined(separator: ", ")
    }
    
    /// Detect project type from files
    private static func detectProjectType(in repoURL: URL) -> String {
        let fileManager = FileManager.default
        let contents = try? fileManager.contentsOfDirectory(atPath: repoURL.path)
        
        guard let files = contents else { return "unknown" }
        
        // Check for project type indicators
        if files.contains("Package.swift") { return "swift" }
        if files.contains("Package.json") { return "node" }
        if files.contains("Cargo.toml") { return "rust" }
        if files.contains("go.mod") { return "go" }
        if files.contains("requirements.txt") { return "python" }
        if files.contains("pom.xml") { return "java" }
        if files.contains("build.gradle") { return "java" }
        if files.contains("*.xcodeproj") { return "xcode" }
        if files.contains("*.xcworkspace") { return "xcode" }
        
        return "unknown"
    }
    
    // MARK: - Language Mapping
    
    private static let languageMapping: [String: String] = [
        "swift": "Swift",
        "ts": "TypeScript",
        "tsx": "TypeScript",
        "js": "JavaScript",
        "jsx": "JavaScript",
        "py": "Python",
        "go": "Go",
        "rs": "Rust",
        "kt": "Kotlin",
        "java": "Java",
        "rb": "Ruby",
        "php": "PHP",
        "c": "C",
        "cpp": "C++",
        "h": "C",
        "hpp": "C++",
        "cs": "C#",
        "scala": "Scala",
        "sh": "Shell",
        "zsh": "Shell",
        "bash": "Shell",
        "md": "Markdown",
        "yaml": "YAML",
        "yml": "YAML",
        "json": "JSON",
        "xml": "XML",
        "sql": "SQL",
        "html": "HTML",
        "css": "CSS",
        "scss": "SCSS"
    ]
    
    // MARK: - Active Projects
    
    /// Get projects sorted by recent activity
    static func getActiveProjects(limit: Int = 10) -> [KnowledgeNode] {
        let repos = findGitRepos()
        
        // Sort by lastSeen (most recent first)
        let sorted = repos.sorted { $0.lastSeen > $1.lastSeen }
        
        return Array(sorted.prefix(limit))
    }
}