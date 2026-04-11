import Foundation
import OSLog

/// Communicates with the local Pieces OS REST API to fetch LTM workstream data
/// and optionally generate text via QGPT.
struct PiecesOSService {
    private let logger = Logger(subsystem: "com.kika.BreakPoint", category: "PiecesOS")
    private let qgptTimeoutSeconds: TimeInterval = 15
    let session: URLSession
    let baseURL: URL

    init(
        session: URLSession = .shared,
        baseURLString: String = "http://localhost:39300"
    ) {
        self.session = session
        self.baseURL = URL(string: baseURLString)!
    }

    // MARK: - Health

    /// Check if Pieces OS is reachable.
    func isAvailable() async -> Bool {
        let url = baseURL.appending(path: "models")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        do {
            let (_, response) = try await session.data(for: request)
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            logger.info("isAvailable: \(ok)")
            return ok
        } catch {
            logger.error("isAvailable error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Workstream Events (LTM)

    /// Fetch recent workstream events (Pieces' screen capture LTM).
    /// Returns up to `limit` events, sorted most-recent first.
    func fetchRecentWorkstreamEvents(limit: Int = 20) async -> [WorkstreamEvent] {
        let url = baseURL.appending(path: "workstream_events")
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        do {
            logger.info("Fetching workstream_events...")
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.info("workstream_events response: HTTP \(statusCode), \(data.count) bytes")
            guard statusCode == 200 else { return [] }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["iterable"] as? [[String: Any]] ?? []
            logger.info("workstream_events: \(items.count) total items, taking \(limit)")

            let events = items.prefix(limit).compactMap { item -> WorkstreamEvent? in
                let title = item["title"] as? String
                let description = item["description"] as? String
                let readable = item["readable"] as? String
                let windowTitle = item["windowTitle"] as? String
                let created = (item["created"] as? [String: Any])?["readable"] as? String

                guard title != nil || description != nil || readable != nil else { return nil }

                return WorkstreamEvent(
                    title: title,
                    description: description,
                    readable: readable.map { String($0.prefix(500)) },
                    windowTitle: windowTitle,
                    createdReadable: created
                )
            }
            logger.info("Parsed \(events.count) events")
            return events
        } catch {
            logger.error("workstream_events error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Workstream Summaries

    /// Fetch recent workstream summaries (higher-level activity summaries).
    func fetchRecentSummaryNames(limit: Int = 10) async -> [String] {
        let url = baseURL.appending(path: "workstream_summaries")
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            logger.info("Fetching workstream_summaries...")
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.info("workstream_summaries response: HTTP \(statusCode), \(data.count) bytes")
            guard statusCode == 200 else { return [] }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["iterable"] as? [[String: Any]] ?? []

            let names = items.prefix(limit).compactMap { item in
                item["name"] as? String
            }
            logger.info("Parsed \(names.count) summary names")
            return names
        } catch {
            logger.error("workstream_summaries error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - QGPT Question (AI Generation)

    /// Ask Pieces OS to generate a response via its QGPT endpoint.
    func askQuestion(prompt: String) async -> Result<String, PiecesOSError> {
        let url = baseURL.appending(path: "qgpt/question")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = qgptTimeoutSeconds

        let body: [String: Any] = [
            "query": prompt,
            "relevant": ["iterable": [] as [Any]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            logger.info("Sending QGPT question (\(prompt.count) chars)...")
            let (data, response) = try await data(for: request, timeoutSeconds: qgptTimeoutSeconds)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("QGPT: no HTTP response")
                return .failure(.invalidResponse)
            }

            logger.info("QGPT response: HTTP \(httpResponse.statusCode), \(data.count) bytes")

            guard httpResponse.statusCode == 200 else {
                return .failure(.unexpectedStatusCode(httpResponse.statusCode))
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let answers = (json?["answers"] as? [String: Any])?["iterable"] as? [[String: Any]] ?? []
            guard let text = answers.first?["text"] as? String,
                  text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                logger.error("QGPT: empty answer")
                return .failure(.emptyResponse)
            }

            logger.info("QGPT returned \(text.count) chars")
            return .success(text)
        } catch {
            logger.error("QGPT error: \(error.localizedDescription)")
            return .failure(.serverUnavailable)
        }
    }

    private func data(for request: URLRequest, timeoutSeconds: TimeInterval) async throws -> (Data, URLResponse) {
        try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            group.addTask {
                try await session.data(for: request)
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeoutSeconds))
                throw URLError(.timedOut)
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Models

struct WorkstreamEvent: Codable, Equatable {
    let title: String?
    let description: String?
    let readable: String?
    let windowTitle: String?
    let createdReadable: String?
}

enum PiecesOSError: Error, Equatable, LocalizedError {
    case serverUnavailable
    case invalidResponse
    case unexpectedStatusCode(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .serverUnavailable:
            return "Could not reach Pieces OS."
        case .invalidResponse:
            return "Pieces OS returned an unreadable response."
        case .unexpectedStatusCode(let code):
            return "Pieces OS returned HTTP \(code)."
        case .emptyResponse:
            return "Pieces OS returned an empty response."
        }
    }
}
