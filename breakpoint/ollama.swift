import Foundation

struct AIResumeCard: Codable {
    let summary: String
    let nextStep: String
    let improvement: String
}

class OllamaService {
    let endpoint = URL(string: "http://127.0.0.1:11434/api/chat")!
    let modelName = "qwen3:8b" // Configured for local structured reasoning
    
    func generateResumeCard(from note: String, context: ContextSnapshot) async throws -> AIResumeCard? {
        let systemPrompt = "You are a productivity assistant inside a macOS interruption recovery app. Convert the user's note and system context into a short resume card."
        let userPrompt = "App: \(context.frontmostApp)\nWindows: \(context.windows.map { $0.title }.joined(separator: ", "))\nClipboard: \(context.clipboard)\nUser note: \(note)"
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "stream": false,
            "format": [ // Enforcing strict JSON schema output
                "type": "object",
                "properties": [
                    "summary": ["type": "string"],
                    "nextStep": ["type": "string"],
                    "improvement": ["type": "string"]
                ],
                "required": ["summary", "nextStep", "improvement"]
            ],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Ollama returns the generated text inside message.content
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? [String: Any],
           let contentStr = message["content"] as? String,
           let contentData = contentStr.data(using: .utf8) {
            
            let card = try JSONDecoder().decode(AIResumeCard.self, from: contentData)
            return card
        }
        return nil
    }
}
