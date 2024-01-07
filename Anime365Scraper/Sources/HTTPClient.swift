//
//  HTTPClient.swift
//
//
//  Created by Nikita Nafranets on 07.01.2024.
//
import Alamofire
import Foundation

extension Anime365Scraper.API {
    class HTTPClient {
        private enum APIError: Error {
            case emptyResponse
            case invalidResponse
            case requestFailed
            case serverError
        }

        private let headers: [String: String]

        init(_ accessCookie: String) {
            headers = [
                "User-Agent": "Anime365 IOS root@dimensi.dev",
                "Cookie": accessCookie,
            ]
        }

        let baseURL = "https://anime365.ru"

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

            let (data, response) = try await URLSession.shared.data(from: request)

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
