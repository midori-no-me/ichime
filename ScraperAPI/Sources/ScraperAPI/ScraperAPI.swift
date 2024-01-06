// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

public enum ScraperAPI {}

public protocol ScraperHTMLRequest {
    associatedtype ResponseType

    func getEndpoint() -> String
    func getQueryItems() -> [URLQueryItem]
    func getFormData() -> [URLQueryItem]

    func parseResponse(html: String, baseURL: URL) throws -> ResponseType
}

public extension ScraperAPI {
    enum APIClientError: Error {
        // empty request but 200...299
        case emptyResponse
        // 400...499, wrong data
        case invalidResponse
        // 500 ... 599
        case serverError
        // something unexpected
        case requestFailed
        // when cannot parse html, unexpected response
        case parseError
        // when invalid credentials, login or password
        case invalidCredentials
    }

    final class APIClient {
        private let baseURL: URL
        private let userAgent: String
        public let session: ScraperAPI.Session

        public init(baseURL: URL, userAgent: String, session: ScraperAPI.Session) {
            self.baseURL = baseURL
            self.userAgent = userAgent
            self.session = session
        }

        public func sendAPIRequest<T: ScraperHTMLRequest>(_ request: T) async throws -> T.ResponseType {
            let csrf: String
            if let cookie = session.get(name: .csrf) {
                csrf = cookie.value
            } else {
                csrf = UUID().uuidString
                session.set(name: .csrf, value: csrf)
            }

            var fullURL = baseURL.appendingPathComponent(request.getEndpoint())

            let queryItems = request.getQueryItems()

            if !queryItems.isEmpty {
                fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
            }

            var httpRequest = URLRequest(url: fullURL)

            httpRequest.timeoutInterval = 10
            httpRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            var formData = request.getFormData()
            if !formData.isEmpty {
                if let index = formData.firstIndex(where: { $0.name == Session.Cookie.csrf.rawValue }) {
                    formData[index].value = csrf
                } else {
                    formData.append(.init(name: Session.Cookie.csrf.rawValue, value: csrf))
                }

                var data = URLComponents()
                data.queryItems = formData
                guard let queryString = data.query else {
                    logger.error("HTML request: cannot create queryString")
                    throw APIClientError.invalidResponse
                }
                httpRequest.httpMethod = "POST"
                httpRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

                httpRequest.httpBody = queryString.data(using: .utf8)

                logger
                    .debug(
                        "HTML request: Append form data to request, change type request to post \(queryString, privacy: .sensitive)"
                    )
            }

            do {
                let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

                guard let httpResponse = httpResponse as? HTTPURLResponse,
                      let requestUrl = httpRequest.url?.absoluteString
                else {
                    logger.error("HTML request: failed with emptyResponse, failed to get httpResponse")
                    throw APIClientError.emptyResponse
                }

                logger
                    .info("HTML request: \(httpRequest.httpMethod ?? "GET") \(requestUrl) [\(httpResponse.statusCode)]")

                switch httpResponse.statusCode {
                case 200 ... 299:
                    let htmlString = String(data: data, encoding: .utf8) ?? ""
                    return try request.parseResponse(html: htmlString, baseURL: baseURL)
                case 400 ... 499:
                    throw APIClientError.invalidResponse
                case 500 ... 599:
                    throw APIClientError.serverError
                default:
                    logger.error("HTML response got something unexpected: \(httpRequest.debugDescription)")
                    throw APIClientError.requestFailed
                }
            }
        }
    }
}
