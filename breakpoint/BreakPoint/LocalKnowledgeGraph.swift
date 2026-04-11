import Foundation

/// Builds a knowledge graph from local data sources
struct LocalKnowledgeGraph {
    
    // MARK: - Build Knowledge Graph
    
    /// Build complete knowledge graph from all sources
    static func build() async -> KnowledgeGraph {
        var allNodes: [KnowledgeNode] = []
        
        // Extract from Documents/Git
        let projects = ProjectExtractor.findGitRepos()
        allNodes.append(contentsOf: projects)
        print("[LocalKG] Git: \(projects.count) projects")
        
        // Extract from recent files
        let concepts = ConceptExtractor.extractFromRecentFiles()
        allNodes.append(contentsOf: concepts)
        print("[LocalKG] Files: \(concepts.count) concepts")
        
        // Extract from OpenClaw memory
        let memoryNodes = MemoryExtractor.extractFromMemory()
        allNodes.append(contentsOf: memoryNodes)
        print("[LocalKG] Memory: \(memoryNodes.count) nodes")
        
        // Build edges (relationships)
        let edges = buildEdges(from: allNodes)
        
        let graph = KnowledgeGraph(nodes: allNodes.removingDuplicates(), edges: edges)
        print("[LocalKG] Total: \(allNodes.count) nodes, \(edges.count) edges")
        
        return graph
    }
    
    /// Build knowledge graph with only non-permission sources
    static func buildWithoutPermissions() -> KnowledgeGraph {
        var allNodes: [KnowledgeNode] = []
        
        // Git projects
        let projects = ProjectExtractor.findGitRepos()
        allNodes.append(contentsOf: projects)
        
        // Recent files
        let concepts = ConceptExtractor.extractFromRecentFiles()
        allNodes.append(contentsOf: concepts)
        
        // OpenClaw memory
        let memoryNodes = MemoryExtractor.extractFromMemory()
        allNodes.append(contentsOf: memoryNodes)
        
        let edges = buildEdges(from: allNodes)
        
        return KnowledgeGraph(nodes: allNodes.removingDuplicates(), edges: edges)
    }
    
    // MARK: - Build Edges
    
    /// Build relationships between nodes
    private static func buildEdges(from nodes: [KnowledgeNode]) -> [KnowledgeEdge] {
        var edges: [KnowledgeEdge] = []
        
        // Projects → Technologies
        let projects = nodes.filter { $0.nodeType == .project }
        let technologies = nodes.filter { $0.nodeType == .technology }
        
        for project in projects {
            if let langs = project.metadata?["languages"] {
                let projectTechs = langs.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                for tech in projectTechs {
                    if let techNode = technologies.first(where: { $0.label == tech }) {
                        edges.append(KnowledgeEdge(
                            sourceId: project.id,
                            targetId: techNode.id,
                            relationship: "uses",
                            strength: 0.8,
                            lastSeen: Date()
                        ))
                    }
                }
            }
        }
        
        // Projects → Concepts (if mentioned in same memory)
        let concepts = nodes.filter { $0.nodeType == .concept }
        
        for project in projects {
            for concept in concepts {
                if let conceptFile = concept.metadata?["file"],
                   let projectFile = project.metadata?["file"],
                   conceptFile == projectFile {
                    edges.append(KnowledgeEdge(
                        sourceId: project.id,
                        targetId: concept.id,
                        relationship: "related_to",
                        strength: 0.5,
                        lastSeen: Date()
                    ))
                }
            }
        }
        
        return edges
    }
    
    // MARK: - Format for Prompt
    
    /// Format knowledge graph for AI prompt
    static func formatForPrompt(_ graph: KnowledgeGraph) -> String {
        return graph.toContext()
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
