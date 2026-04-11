import Foundation

enum OllamaConnectionError: Error, Equatable, LocalizedError {
    case invalidBaseURL
    case serverUnavailable
    case unexpectedStatusCode(Int)
    case missingModel(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Enter a valid Ollama base URL."
        case .serverUnavailable:
            return "Could not reach Ollama."
        case .unexpectedStatusCode(let statusCode):
            return "Ollama returned HTTP \(statusCode)."
        case .missingModel(let model):
            return "Model '\(model)' is not available."
        case .invalidResponse:
            return "Ollama returned an unreadable response."
        }
    }
}

enum OllamaGenerationError: Error, Equatable, LocalizedError {
    case invalidBaseURL
    case missingModel
    case missingSourceText
    case serverUnavailable
    case unexpectedStatusCode(Int)
    case invalidResponse
    case emptySummary

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Enter a valid Ollama base URL."
        case .missingModel:
            return "Enter an Ollama model before generating summaries."
        case .missingSourceText:
            return "No screenshot text was available."
        case .serverUnavailable:
            return "Could not reach Ollama."
        case .unexpectedStatusCode(let statusCode):
            return "Ollama returned HTTP \(statusCode)."
        case .invalidResponse:
            return "Ollama returned an unreadable response."
        case .emptySummary:
            return "Ollama returned an empty summary."
        }
    }
}

struct OllamaService {
    private let generationTimeoutSeconds: TimeInterval = 180

    private struct TagsResponse: Decodable {
        let models: [Model]
    }

    private struct GenerateRequest: Encodable {
        let model: String
        let prompt: String
        let stream: Bool
        let think: Bool
    }

    private struct GenerateResponse: Decodable {
        let response: String
    }

    private struct Model: Decodable {
        let name: String
    }

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchAvailableModels(baseURLString: String) async -> Result<[String], OllamaConnectionError> {
        guard let baseURL = validatedBaseURL(from: baseURLString) else {
            return .failure(.invalidBaseURL)
        }

        let tagsURL = baseURL.appending(path: "api/tags")

        do {
            let (data, response) = try await session.data(from: tagsURL)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard httpResponse.statusCode == 200 else {
                return .failure(.unexpectedStatusCode(httpResponse.statusCode))
            }

            let tags = try JSONDecoder().decode(TagsResponse.self, from: data)
            let names = tags.models.map(\.name).sorted()
            return .success(names)
        } catch let error as DecodingError {
            _ = error
            return .failure(.invalidResponse)
        } catch {
            return .failure(.serverUnavailable)
        }
    }

    func testConnection(baseURLString: String, model: String) async -> Result<String, OllamaConnectionError> {
        guard let baseURL = validatedBaseURL(from: baseURLString) else {
            return .failure(.invalidBaseURL)
        }

        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagsURL = baseURL.appending(path: "api/tags")

        do {
            let (data, response) = try await session.data(from: tagsURL)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard httpResponse.statusCode == 200 else {
                return .failure(.unexpectedStatusCode(httpResponse.statusCode))
            }

            let tags = try JSONDecoder().decode(TagsResponse.self, from: data)

            guard trimmedModel.isEmpty == false else {
                return .success("Connected to Ollama.")
            }

            let matchedModel = tags.models.first { listedModel in
                listedModel.name == trimmedModel || listedModel.name.hasPrefix("\(trimmedModel):")
            }

            guard let matchedModel else {
                return .failure(.missingModel(trimmedModel))
            }

            return .success("Connected to Ollama. Model available: \(matchedModel.name)")
        } catch let error as DecodingError {
            _ = error
            return .failure(.invalidResponse)
        } catch {
            return .failure(.serverUnavailable)
        }
    }

    func generateSummary(baseURLString: String, model: String, snapshot: Snapshot) async -> Result<String, OllamaGenerationError> {
        let prompt = Self.summaryPrompt(for: snapshot)
        return await generateText(baseURLString: baseURLString, model: model, prompt: prompt)
    }

    func generateWorkflow(baseURLString: String, model: String, snapshot: Snapshot) async -> Result<String, OllamaGenerationError> {
        guard snapshot.screenshotText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return .failure(.missingSourceText)
        }

        let prompt = Self.workflowPrompt(for: snapshot)
        return await generateText(baseURLString: baseURLString, model: model, prompt: prompt)
    }

    func generateText(baseURLString: String, model: String, prompt: String) async -> Result<String, OllamaGenerationError> {
        guard let baseURL = validatedBaseURL(from: baseURLString) else {
            return .failure(.invalidBaseURL)
        }

        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedModel.isEmpty == false else {
            return .failure(.missingModel)
        }
        let generateURL = baseURL.appending(path: "api/generate")
        var request = URLRequest(url: generateURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Cloud and reasoning models can take longer than URLSession's default request timeout.
        request.timeoutInterval = generationTimeoutSeconds

        do {
            request.httpBody = try JSONEncoder().encode(
                GenerateRequest(
                    model: trimmedModel,
                    prompt: prompt,
                    stream: false,
                    think: false
                )
            )
        } catch {
            return .failure(.invalidResponse)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard httpResponse.statusCode == 200 else {
                return .failure(.unexpectedStatusCode(httpResponse.statusCode))
            }

            let decodedResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
            let summary = decodedResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
            guard summary.isEmpty == false else {
                return .failure(.emptySummary)
            }

            return .success(summary)
        } catch let error as DecodingError {
            _ = error
            return .failure(.invalidResponse)
        } catch {
            return .failure(.serverUnavailable)
        }
    }

    private func validatedBaseURL(from baseURLString: String) -> URL? {
        guard
            let baseURL = URL(string: baseURLString),
            let scheme = baseURL.scheme,
            let host = baseURL.host,
            ["http", "https"].contains(scheme),
            host.isEmpty == false
        else {
            return nil
        }

        return baseURL
    }

    static func summaryPrompt(for snapshot: Snapshot) -> String {
        let runningApps = snapshot.runningApps.isEmpty
            ? "(none)"
            : snapshot.runningApps.joined(separator: ", ")
        let windows = snapshot.windows.isEmpty
            ? "(none)"
            : snapshot.windows.map { window in
                let title = window.title.isEmpty ? "(untitled)" : window.title
                return "\(window.app): \(title)"
            }.joined(separator: "\n")
        let clipboard = snapshot.clipboard?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? snapshot.clipboard!
            : "(empty)"

        return """
        You are BreakPoint's "resume assistant" for macOS snapshots.
        Task: produce a concise resume summary grounded only in snapshot data.
        Output rules:
        - Return plain Markdown only.
        - Exactly 3 bullet points.
        - Max 16 words per bullet.
        - No intro, no conclusion, no speculation beyond provided context.
        - Mention app/window names explicitly when relevant.
        - If data is missing, say "unknown" instead of inventing details.

        Time: \(snapshot.time)
        Frontmost app: \(snapshot.frontmostApp)
        Running apps: \(runningApps)
        Visible windows:
        \(windows)
        Clipboard:
        \(clipboard)
        """
    }

    static func workflowPrompt(for snapshot: Snapshot) -> String {
        let screenshotText = snapshot.screenshotText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(none)"

        return """
        You are BreakPoint's workflow extractor.
        Task: convert screenshot OCR text into a resumable workflow.
        Grounding rules:
        - Use only the OCR text and metadata below.
        - Do not invent tools, tasks, or decisions not present in the input.
        - If OCR is ambiguous, label it "unclear".
        Output format (Markdown only, no extra text):
        ## Goal
        <1 short sentence>

        ## Current Steps
        - <up to 4 bullets>

        ## Next Actions
        - <up to 4 prioritized bullets>
        Length limit: under 180 words.

        Time: \(snapshot.time)
        Frontmost app: \(snapshot.frontmostApp)
        Screenshot OCR text:
        \(screenshotText)
        """
    }
}
