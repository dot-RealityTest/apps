import Foundation

/// Extracts concepts and technologies from recent files
struct ConceptExtractor {
    
    // MARK: - Recent Files
    
    /// Get recently accessed files and extract concepts
    static func extractFromRecentFiles(limit: Int = 50) -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        // Get recent files from common locations
        let recentPaths = getRecentFiles(limit: limit)
        
        for path in recentPaths {
            // Extract technology from file extension
            if let tech = detectTechnology(from: path) {
                let node = KnowledgeNode(
                    label: tech,
                    nodeType: .technology,
                    source: .files,
                    lastSeen: Date(),
                    metadata: ["file": path.lastPathComponent]
                )
                nodes.append(node)
            }
            
            // Extract concepts from file content
            if let concepts = extractConcepts(from: path) {
                nodes.append(contentsOf: concepts)
            }
        }
        
        return nodes.removingDuplicates()
    }
    
    // MARK: - Get Recent Files
    
    /// Get recently accessed files
    private static func getRecentFiles(limit: Int) -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default
        
        // Common locations
        let locations = [
            FileManager.default.homeDirectoryForCurrentUser,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"),
        ]
        
        for location in locations {
            guard let enumerator = fileManager.enumerator(
                at: location,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for case let url as URL in enumerator {
                guard let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                      resourceValues.isRegularFile == true else { continue }
                
                files.append(url)
                
                if files.count >= limit { break }
            }
            
            if files.count >= limit { break }
        }
        
        // Sort by modification date
        files.sort { 
            let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        return Array(files.prefix(limit))
    }
    
    // MARK: - Technology Detection
    
    /// Detect technology from file extension
    private static func detectTechnology(from url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        return technologyMapping[ext]
    }
    
    private static let technologyMapping: [String: String] = [
        // Programming languages
        "swift": "Swift",
        "ts": "TypeScript",
        "tsx": "React",
        "js": "JavaScript",
        "jsx": "React",
        "py": "Python",
        "go": "Go",
        "rs": "Rust",
        "kt": "Kotlin",
        "java": "Java",
        "rb": "Ruby",
        "php": "PHP",
        "c": "C",
        "cpp": "C++",
        "cs": "C#",
        "scala": "Scala",
        
        // Frameworks & Tools
        "vue": "Vue.js",
        "svelte": "Svelte",
        "dart": "Dart/Flutter",
        "ex": "Elixir",
        "erl": "Erlang",
        "hs": "Haskell",
        "clj": "Clojure",
        "r": "R",
        "m": "MATLAB/Objective-C",
        "mm": "Objective-C++",
        
        // Data & Config
        "json": "JSON",
        "yaml": "YAML",
        "yml": "YAML",
        "xml": "XML",
        "toml": "TOML",
        "ini": "INI",
        "env": "Environment",
        
        // Web
        "html": "HTML",
        "css": "CSS",
        "scss": "SCSS",
        "sass": "Sass",
        "less": "Less",
        
        // Data
        "sql": "SQL",
        "graphql": "GraphQL",
        "proto": "Protocol Buffers",
        
        // Docs
        "md": "Markdown",
        "rst": "reStructuredText",
        "tex": "LaTeX",
        "adoc": "AsciiDoc",
        
        // Shell
        "sh": "Shell",
        "bash": "Bash",
        "zsh": "Zsh",
        "fish": "Fish",
        "ps1": "PowerShell",
        
        // Build
        "gradle": "Gradle",
        "makefile": "Make",
        "dockerfile": "Docker",
    ]
    
    // MARK: - Concept Extraction
    
    /// Extract concepts from file content
    private static func extractConcepts(from url: URL) -> [KnowledgeNode]? {
        // Only process text files
        let textExtensions = ["md", "txt", "json", "yaml", "yml", "xml"]
        guard textExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        
        var concepts: [KnowledgeNode] = []
        
        // Extract from Markdown headers
        if url.pathExtension.lowercased() == "md" {
            concepts.append(contentsOf: extractFromMarkdown(content: content, source: url))
        }
        
        // Extract known terms
        concepts.append(contentsOf: extractKnownTerms(content: content, source: url))
        
        return concepts
    }
    
    /// Extract concepts from Markdown headers
    private static func extractFromMarkdown(content: String, source: URL) -> [KnowledgeNode] {
        var concepts: [KnowledgeNode] = []
        
        let headerPattern = #"^#+\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: headerPattern, options: .anchorsMatchLines) else {
            return concepts
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, range: range)
        
        for match in matches {
            guard let headerRange = Range(match.range(at: 1), in: content) else { continue }
            let header = String(content[headerRange])
            
            // Skip generic headers
            if ["Introduction", "Overview", "Conclusion", "Summary", "Notes"].contains(header) { continue }
            
            let node = KnowledgeNode(
                label: header,
                nodeType: .concept,
                source: .files,
                lastSeen: Date(),
                metadata: ["file": source.lastPathComponent]
            )
            concepts.append(node)
        }
        
        return concepts
    }
    
    /// Extract known terms from content
    private static func extractKnownTerms(content: String, source: URL) -> [KnowledgeNode] {
        var concepts: [KnowledgeNode] = []
        
        // Known technology terms
        let techTerms = [
            "Swift", "SwiftUI", "UIKit", "AppKit", "CoreData", "CloudKit",
            "TypeScript", "JavaScript", "React", "Vue", "Angular", "Svelte",
            "Python", "Django", "Flask", "FastAPI",
            "Go", "Rust", "Kotlin", "Java",
            "Docker", "Kubernetes", "AWS", "Azure", "GCP",
            "PostgreSQL", "MySQL", "MongoDB", "Redis",
            "GraphQL", "REST", "gRPC",
            "Git", "GitHub", "GitLab",
            "LLM", "GPT", "Claude", "Ollama",
            "macOS", "iOS", "iPadOS", "watchOS",
            "Node.js", "npm", "yarn", "pnpm",
        ]
        
        for term in techTerms {
            if content.contains(term) {
                concepts.append(KnowledgeNode(
                    label: term,
                    nodeType: .technology,
                    source: .files,
                    lastSeen: Date(),
                    metadata: ["file": source.lastPathComponent]
                ))
            }
        }
        
        return concepts
    }
}