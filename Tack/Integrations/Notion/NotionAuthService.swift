import Foundation
import CryptoKit

/// Notion OAuth 2.0 service. PKCE flow.
///
/// Setup steps (one-time):
///  1. Register an OAuth integration at notion.so/profile/integrations.
///  2. Set `clientID` and `redirectURI` constants below.
///  3. Add `tack://oauth/notion` as a redirect URI; also register it in Info.plist.
///  4. Add `CFBundleURLTypes` already in project.yml — confirm.
public actor NotionAuthService {

    public static let clientID    = "REPLACE_WITH_YOUR_NOTION_CLIENT_ID"
    public static let redirectURI = "tack://oauth/notion"
    public static let authURL     = "https://api.notion.com/v1/oauth/authorize"
    public static let tokenURL    = "https://api.notion.com/v1/oauth/token"

    /// In-memory PKCE verifier; keychain store is overkill for this transient value
    /// (10 min lifetime max).
    private var verifier: String?

    public init() {}

    public struct Authorization {
        public let url: URL
        public let state: String
    }

    public func makeAuthorizationURL() -> Authorization {
        let verifier  = Self.makeCodeVerifier()
        let challenge = Self.codeChallenge(for: verifier)
        self.verifier = verifier

        let state = UUID().uuidString
        var comps = URLComponents(string: Self.authURL)!
        comps.queryItems = [
            .init(name: "client_id",             value: Self.clientID),
            .init(name: "response_type",         value: "code"),
            .init(name: "owner",                 value: "user"),
            .init(name: "redirect_uri",          value: Self.redirectURI),
            .init(name: "code_challenge",        value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state",                 value: state)
        ]
        return Authorization(url: comps.url!, state: state)
    }

    /// Handles the OAuth callback URL. Returns true on successful token exchange.
    @discardableResult
    public func handleCallback(_ url: URL) async throws -> Bool {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = comps.queryItems?.first(where: { $0.name == "code" })?.value,
              let verifier = verifier
        else { return false }

        var req = URLRequest(url: URL(string: Self.tokenURL)!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Basic " + base64("\(Self.clientID):"), forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  Self.redirectURI,
            "code_verifier": verifier
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return false
        }
        struct Token: Decodable { let access_token: String }
        let token = try JSONDecoder().decode(Token.self, from: data)
        KeychainStore.setString(token.access_token, service: .notionOAuth, account: "access_token")
        return true
    }

    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }

    private func base64(_ s: String) -> String {
        Data(s.utf8).base64EncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
