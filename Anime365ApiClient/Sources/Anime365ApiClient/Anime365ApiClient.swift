import Foundation
import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.midorinome.ichime",
    category: "Anime365ApiClient"
)


public struct Anime365ApiResponse<T: Decodable>: Decodable {
    let data: T
}

public protocol Anime365ApiRequest {
    associatedtype ResponseType: Decodable

    func getEndpoint() -> String
    func getQueryItems() -> [URLQueryItem]
}

public enum Anime365ApiClientError: Error {
    case invalidData
    case requestFailed
}

public final class Anime365ApiClient {
    private let baseURL: URL
    private let userAgent: String

    public init(
        baseURL: URL,
        userAgent: String
    ) {
        self.baseURL = baseURL
        self.userAgent = userAgent
    }

    public func sendApiRequest<T: Anime365ApiRequest>(_ apiRequest: T) async throws -> T.ResponseType {
        var fullURL = baseURL.appendingPathComponent("/api" + apiRequest.getEndpoint())

        let queryItems = apiRequest.getQueryItems()

        if !queryItems.isEmpty {
            fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
        }

        var httpRequest = URLRequest(url: fullURL)

        httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        httpRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        httpRequest.timeoutInterval = 3

        let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

        if let requestUrl = httpRequest.url?.absoluteString, let httpResponse = httpResponse as? HTTPURLResponse {
            logger.notice("[Anime365ApiClient] API request: GET \(requestUrl) [\(httpResponse.statusCode)]")
        }

        do {
            let apiResponse = try JSONDecoder()
                .decode(Anime365ApiResponse<T.ResponseType>.self, from: data)

            return apiResponse.data
        } catch {
            logger.error("[Anime365ApiClient] Decoding JSON error: \(error.localizedDescription, privacy: .public)")
            logger.error("[Anime365ApiClient] JSON Decoder detailed error:")
            logger.error("\(error, privacy: .public)")
            logger.error("[Anime365ApiClient] API response:")

            if let responseBodyString = String(data: data, encoding: .utf8) {
                logger.error("\(responseBodyString, privacy: .public)")
            } else {
                logger.error("[Anime365ApiClient] Unable to convert response body to a string")
            }

            throw Anime365ApiClientError.invalidData
        }
    }
}
