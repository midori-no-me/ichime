//
//  HTTPClient.swift
//
//
//  Created by Nikita Nafranets on 07.01.2024.
//
import Foundation

public extension Anime365Scraper.API {
    class HTTPClient {
        private enum APIError: Error {
            case emptyResponse
            case invalidResponse
            case requestFailed
            case serverError
        }

        private let headers: [String: String]

        let baseURL: String
        let userID: PHPUserID

        public init(accessCookie: String, baseURL: String = "https://anime365.ru") {
            headers = [
                "User-Agent": "Anime365 IOS root@dimensi.dev",
                "Cookie": accessCookie,
            ]

            userID = .init(phpToken: accessCookie)
            self.baseURL = baseURL
        }

        func appendURL(_ path: String) -> String {
            baseURL + path
        }

        func requestHTML(url: String, parameters: [String: Any]?) async throws -> String {
            let fullURL = URL(string: url)!

            // Подготовка параметров запроса
            var urlComponents = URLComponents(url: fullURL, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = parameters?.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

            guard let preparedURL = urlComponents?.url else {
                throw APIError.invalidResponse
            }

            var request = URLRequest(url: preparedURL)
            request.allHTTPHeaderFields = headers
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.emptyResponse
            }

            switch httpResponse.statusCode {
            case 200 ... 299:
                guard let htmlString = String(data: data, encoding: .utf8) else {
                    throw APIError.emptyResponse
                }
                return htmlString
            case 400 ... 499:
                throw APIError.invalidResponse
            case 500 ... 599:
                throw APIError.serverError
            default:
                throw APIError.requestFailed
            }
        }
    }
}

struct PHPUserID {
    // UserID пользователя достанный из куки
    public let value: Int

    init(phpToken: String) {
        if let decodedString = phpToken.removingPercentEncoding {
            value = Self.getValue(phpToken: decodedString)
        } else {
            value = 0
        }
    }

    // Размер токена авторизации в строке авторизации
    private static let tokenSize = 40
    private static let pattern = "i:0;i:(\\d+)"
    private static func getValue(phpToken: String) -> Int {
        let cookieValue = phpToken.components(separatedBy: "=").last
        guard let cookieValue else { return 0 }
        let onlyUserDataString = String(cookieValue.dropFirst(tokenSize))

        if let range = onlyUserDataString.range(of: pattern, options: .regularExpression) {
            let match = onlyUserDataString[range]
            let components = match.components(separatedBy: ";")
            if let idPart = components.last {
                let parts = idPart.components(separatedBy: ":")
                if let id = parts.last, let number = Int(id) {
                    return number
                }
            }
        }

        return 0
    }
}
