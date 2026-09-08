import Foundation

/// Notion REST API v1 client. Public API only — requires the user to share a database
/// with the integration via Notion's UI.
public final class NotionClient: @unchecked Sendable {
    private let baseURL = URL(string: "https://api.notion.com/v1")!
    private let version = "2022-06-28"
    private let lock = NSLock()

    private var _token: String?
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
        self._token = KeychainStore.string(service: .notionOAuth, account: "access_token")
    }

    public func setToken(_ value: String?) {
        if let value { KeychainStore.setString(value, service: .notionOAuth, account: "access_token") }
        else { KeychainStore.remove(service: .notionOAuth, account: "access_token") }
        lock.lock(); defer { lock.unlock() }
        _token = value
    }

    public func hasToken() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return _token != nil
    }

    private var token: String? {
        lock.lock(); defer { lock.unlock() }
        return _token
    }

    // MARK: - Endpoints

    public func listDatabases() async throws -> [NotionDatabase] {
        let resp: NotionListResponse<NotionDatabase> = try await post(path: "search", body: [
            "filter": ["value": "database", "property": "object"],
            "sort":   ["direction": "descending", "timestamp": "last_edited_time"]
        ])
        return resp.results
    }

    public func queryDatabase(id: String, startCursor: String? = nil) async throws -> NotionQueryResponse {
        var body: [String: Any] = [
            "page_size": 100,
            "filter": ["property": "Status", "checkbox": ["equals": false]]
        ]
        if let startCursor { body["start_cursor"] = startCursor }
        return try await post(path: "databases/\(id)/query", body: body)
    }

    public func createPage(in database: String, title: String, status: String = "open", due: Date? = nil) async throws -> NotionPage {
        var properties: [String: Any] = [
            "Name": ["title": [["text": ["content": title]]]],
            "Status": ["status": ["name": status]]
        ]
        if let due {
            properties["Due"] = ["date": ["start": ISO8601DateFormatter().string(from: due)]]
        }
        let body: [String: Any] = [
            "parent": ["database_id": database],
            "properties": properties
        ]
        return try await post(path: "pages", body: body)
    }

    public func setPageDone(_ pageID: String, done: Bool) async throws -> NotionPage {
        let body: [String: Any] = [
            "properties": [
                "Status": ["status": ["name": done ? "Done" : "Open"]]
            ]
        ]
        return try await patch(path: "pages/\(pageID)", body: body)
    }

    // MARK: - HTTP helpers

    private func makeRequest(path: String, method: String, body: Any? = nil) throws -> URLRequest {
        guard let token else { throw NotionError.notAuthorized }
        let url = baseURL.appending(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue(version,    forHTTPHeaderField: "Notion-Version")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        return req
    }

    private func post<T: Decodable>(path: String, body: Any? = nil) async throws -> T {
        let req = try makeRequest(path: path, method: "POST", body: body)
        return try await execute(req)
    }

    private func patch<T: Decodable>(path: String, body: Any? = nil) async throws -> T {
        let req = try makeRequest(path: path, method: "PATCH", body: body)
        return try await execute(req)
    }

    private func execute<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw NotionError.transport }
        if http.statusCode == 401 { throw NotionError.notAuthorized }
        if !(200..<300).contains(http.statusCode) {
            TKLog.notion.error("Notion \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
            throw NotionError.http(http.statusCode, data)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - DTOs

public struct NotionDatabase: Codable, Identifiable, Sendable {
    public let id: String
    public let title: [NotionRichText]
    public let lastEditedTime: Date?

    public var displayTitle: String {
        title.first?.plainText ?? "Untitled"
    }

    enum CodingKeys: String, CodingKey {
        case id, title
        case lastEditedTime = "last_edited_time"
    }
}

public struct NotionListResponse<T: Codable & Sendable>: Codable, Sendable {
    public let results: [T]
    public let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
    }
}

public struct NotionPage: Codable, Sendable {
    public let id: String
    public let lastEditedTime: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case lastEditedTime = "last_edited_time"
    }
}

public struct NotionRichText: Codable, Sendable {
    public let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

public struct NotionQueryResponse: Codable, Sendable {
    public let results: [NotionPage]
    public let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
    }
}

public enum NotionError: Error, LocalizedError {
    case notAuthorized
    case transport
    case http(Int, Data)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:        return "Notion token missing or invalid"
        case .transport:            return "Network failure talking to Notion"
        case .http(let code, _):    return "Notion returned HTTP \(code)"
        }
    }
}
