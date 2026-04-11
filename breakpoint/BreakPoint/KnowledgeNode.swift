import Foundation

/// A node in the knowledge graph
struct KnowledgeNode: Codable, Hashable {
    let id: String
    let label: String
    let nodeType: NodeType
    let source: Source
    let lastSeen: Date
    let metadata: [String: String]?
    
    enum NodeType: String, Codable {
        case project = "project"
        case concept = "concept"
        case organization = "organization"
        case technology = "technology"
        case event = "event"
    }
    
    enum Source: String, Codable {
        case documents = "documents"
        case git = "git"
        case files = "files"
        case memory = "memory"
    }
    
    /// Convenience initializer for lightweight label/type node creation
    init(label: String, nodeType: NodeType, source: Source, lastSeen: Date = Date(), metadata: [String: String]? = nil) {
        self.id = "\(source.rawValue)-\(label)-\(UUID().uuidString.prefix(8))"
        self.label = label
        self.nodeType = nodeType
        self.source = source
        self.lastSeen = lastSeen
        self.metadata = metadata
    }
    
    // Hashable conformance - hash by id since it's unique
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: KnowledgeNode, rhs: KnowledgeNode) -> Bool {
        lhs.id == rhs.id
    }
}

/// A relationship between two nodes
struct KnowledgeEdge: Codable {
    let sourceId: String
    let targetId: String
    let relationship: String
    let strength: Double
    let lastSeen: Date
}

/// The complete knowledge graph
struct KnowledgeGraph: Codable {
    var nodes: [KnowledgeNode]
    var edges: [KnowledgeEdge]
    
    /// Format knowledge graph for AI prompt
    func toContext() -> String {
        var lines: [String] = []
        
        lines.append("## Knowledge Graph")
        lines.append("")
        
        // Group by type
        let projects = nodes.filter { $0.nodeType == .project }.prefix(10)
        let technologies = nodes.filter { $0.nodeType == .technology }.prefix(10)
        let organizations = nodes.filter { $0.nodeType == .organization }.prefix(5)
        let concepts = nodes.filter { $0.nodeType == .concept }.prefix(10)

        if !projects.isEmpty {
            lines.append("### Projects")
            for project in projects {
                var line = "- \(project.label)"
                if let tech = project.metadata?["languages"], !tech.isEmpty {
                    line += " [\(tech)]"
                }
                lines.append(line)
            }
            lines.append("")
        }
        
        if !technologies.isEmpty {
            lines.append("### Technologies")
            lines.append(technologies.map { "- \($0.label)" }.joined(separator: "\n"))
            lines.append("")
        }
        
        if !organizations.isEmpty {
            lines.append("### Organizations")
            lines.append(organizations.map { "- \($0.label)" }.joined(separator: "\n"))
            lines.append("")
        }
        
        if !concepts.isEmpty {
            lines.append("### Concepts")
            lines.append(concepts.map { "- \($0.label)" }.joined(separator: "\n"))
            lines.append("")
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Get summary for logging
    var summary: String {
        let byType = Dictionary(grouping: nodes, by: { $0.nodeType })
        return """
        Knowledge Graph Summary:
        - Projects: \(byType[.project]?.count ?? 0)
        - Technologies: \(byType[.technology]?.count ?? 0)
        - Organizations: \(byType[.organization]?.count ?? 0)
        - Concepts: \(byType[.concept]?.count ?? 0)
        - Edges: \(edges.count)
        """
    }
}
