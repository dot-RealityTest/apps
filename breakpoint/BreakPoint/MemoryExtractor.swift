import Foundation

/// Extracts knowledge from OpenClaw memory files
struct MemoryExtractor {
    
    // MARK: - Memory Paths
    
    private static let workspacePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".openclaw/workspace")
    
    private static let memoryPath = workspacePath.appendingPathComponent("memory")
    
    // MARK: - Extract from Memory
    
    /// Extract knowledge from OpenClaw memory files
    static func extractFromMemory() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        // Check if memory directory exists
        guard FileManager.default.fileExists(atPath: memoryPath.path) else {
            return nodes
        }
        
        // Read MEMORY.md
        let memoryFile = workspacePath.appendingPathComponent("MEMORY.md")
        if FileManager.default.fileExists(atPath: memoryFile.path) {
            if let content = try? String(contentsOf: memoryFile, encoding: .utf8) {
                nodes.append(contentsOf: parseMemoryFile(content, filename: "MEMORY.md"))
            }
        }
        
        // Read today's daily note
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let dailyFile = memoryPath.appendingPathComponent("\(today).md")
        if FileManager.default.fileExists(atPath: dailyFile.path) {
            if let content = try? String(contentsOf: dailyFile, encoding: .utf8) {
                nodes.append(contentsOf: parseMemoryFile(content, filename: "\(today).md"))
            }
        }
        
        // Read yesterday's daily note
        let yesterday = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)).prefix(10)
        let yesterdayFile = memoryPath.appendingPathComponent("\(yesterday).md")
        if FileManager.default.fileExists(atPath: yesterdayFile.path) {
            if let content = try? String(contentsOf: yesterdayFile, encoding: .utf8) {
                nodes.append(contentsOf: parseMemoryFile(content, filename: "\(yesterday).md"))
            }
        }
        
        return nodes.removingDuplicates()
    }
    
    // MARK: - Parse Memory File
    
    /// Parse memory file for entities
    private static func parseMemoryFile(_ content: String, filename: String) -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        // Extract from headers (## Sections)
        nodes.append(contentsOf: extractHeaders(from: content, filename: filename))
        
        // Extract projects
        nodes.append(contentsOf: extractProjects(from: content, filename: filename))
        
        // Extract technologies
        nodes.append(contentsOf: extractTechnologies(from: content, filename: filename))
        
        // Extract organizations
        nodes.append(contentsOf: extractOrganizations(from: content, filename: filename))
        
        return nodes
    }
    
    // MARK: - Extract Headers
    
    /// Extract headers as concepts
    private static func extractHeaders(from content: String, filename: String) -> [KnowledgeNode] {
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
            let genericHeaders = [
                "Introduction", "Overview", "Conclusion", "Summary", "Notes",
                "TODO", "Notes", "Links", "References", "About", "Contact"
            ]
            if genericHeaders.contains(header) { continue }
            
            concepts.append(KnowledgeNode(
                label: header,
                nodeType: .concept,
                source: .memory,
                lastSeen: Date(),
                metadata: ["file": filename]
            ))
        }
        
        return concepts
    }
    
    // MARK: - Extract Projects
    
    /// Extract project names
    private static func extractProjects(from content: String, filename: String) -> [KnowledgeNode] {
        var projects: [KnowledgeNode] = []
        
        // Common project patterns
        let projectPatterns = [
            // "Project: Name" or "- Project: Name"
            #"Project:\s*([A-Za-z0-9_\-\s]+)"#,
            // "Working on X" or "Building X"
            #"Working on:\s*([A-Za-z0-9_\-\s]+)"#,
            // GitHub repos
            #"github\.com/[a-zA-Z0-9_-]+/([a-zA-Z0-9_-]+)"#,
            // Project names in backticks or quotes
            #"`([A-Za-z][A-Za-z0-9_-]{2,})`"#,
        ]
        
        for pattern in projectPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, range: range)
            
            for match in matches {
                guard let projectRange = Range(match.range(at: 1), in: content) else { continue }
                let project = String(content[projectRange]).trimmingCharacters(in: .whitespaces)
                
                // Skip common words
                let skipWords = ["the", "a", "an", "to", "from", "in", "on", "at"]
                if skipWords.contains(project.lowercased()) { continue }
                
                projects.append(KnowledgeNode(
                    label: project,
                    nodeType: .project,
                    source: .memory,
                    lastSeen: Date(),
                    metadata: ["file": filename]
                ))
            }
        }
        
        return projects
    }
    
    // MARK: - Extract Technologies
    
    /// Extract technologies
    private static func extractTechnologies(from content: String, filename: String) -> [KnowledgeNode] {
        var technologies: [KnowledgeNode] = []
        
        // Known technologies
        let knownTech = [
            "Swift", "SwiftUI", "UIKit", "AppKit", "CoreData", "CloudKit",
            "TypeScript", "JavaScript", "React", "Vue", "Angular", "Svelte", "Node.js",
            "Python", "Django", "Flask", "FastAPI",
            "Go", "Rust", "Kotlin", "Java",
            "Docker", "Kubernetes", "AWS", "Azure", "GCP", "Vercel",
            "PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite",
            "GraphQL", "REST", "gRPC", "WebSocket",
            "Git", "GitHub", "GitLab",
            "LLM", "GPT", "Claude", "Ollama", "qwen", "llama",
            "macOS", "iOS", "iPadOS", "watchOS", "tvOS",
            "npm", "yarn", "pnpm", "pip", "cargo", "brew",
            "Markdown", "YAML", "JSON", "XML", "TOML",
            "OpenClaw", "Nanoclaw", "Hermes", "Leon", "DISCO", "OHLAMMA", "Gamba",
        ]
        
        for tech in knownTech {
            if content.contains(tech) {
                technologies.append(KnowledgeNode(
                    label: tech,
                    nodeType: .technology,
                    source: .memory,
                    lastSeen: Date(),
                    metadata: ["file": filename]
                ))
            }
        }
        
        return technologies
    }
    
    // MARK: - Extract Organizations
    
    /// Extract organizations
    private static func extractOrganizations(from content: String, filename: String) -> [KnowledgeNode] {
        var organizations: [KnowledgeNode] = []
        
        // Known organizations
        let knownOrgs = [
            "Apple", "Google", "Microsoft", "Amazon", "Meta", "OpenAI", "Anthropic",
            "GitHub", "Vercel", "Cloudflare", "Netlify",
            "Nous Research", "Pieces",
        ]
        
        for org in knownOrgs {
            if content.contains(org) {
                organizations.append(KnowledgeNode(
                    label: org,
                    nodeType: .organization,
                    source: .memory,
                    lastSeen: Date(),
                    metadata: ["file": filename]
                ))
            }
        }
        
        return organizations
    }
}
