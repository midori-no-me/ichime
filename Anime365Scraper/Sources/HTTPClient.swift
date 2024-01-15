//
//  HTTPClient.swift
//
//
//  Created by Nikita Nafranets on 07.01.2024.
//
import Foundation

public extension Anime365Scraper.API {
    /**
     HTTP Клиент для запросо на сайт anime365.ru, специализируется в том, чтоб делать запросы html страницы
     */
    class HTTPClient {
        private enum APIError: Error {
            case emptyResponse
            case invalidResponse
            case requestFailed
            case serverError
        }

        let user: Anime365Scraper.AuthManager.Types.UserAuth
        let session: Anime365Scraper.AuthManager.Types.Session

        public init(userAuth: Anime365Scraper.AuthManager.Types.UserAuth) {
            user = userAuth
            session = .init(cookieStorage: HTTPCookieStorage.shared, domain: Anime365Scraper.domain)
        }

        func requestHTML(method: Methods, parameters: [String: String] = [String: String]()) async throws -> String {
            let url = getUrl(method: method, params: parameters)

            guard let url, let preparedURL = URL(string: url) else {
                throw APIError.invalidResponse
            }

            var request = URLRequest(url: preparedURL)
            request.setValue(Anime365Scraper.userAgent, forHTTPHeaderField: "User-Agent")
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

        func postForm(method: Methods, payload: [String: String]) async throws -> String {
            let url = getUrl(method: method)

            guard let url, let preparedURL = URL(string: url) else {
                throw APIError.invalidResponse
            }

            var request = URLRequest(url: preparedURL)
            request.httpMethod = "POST"
            request.setValue(Anime365Scraper.userAgent, forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // Собираем данные для запроса из словаря
            let postData = payload.map { key, value in
                "\(key)=\(value)"
            }.joined(separator: "&")

            request.httpBody = postData.data(using: .utf8)

            do {
                // Выполняем асинхронный запрос
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse, (200 ..< 300).contains(response.statusCode),
                   let responseString = String(data: data, encoding: .utf8)
                {
                    return responseString
                } else {
                    print(response, data)
                    throw APIError.invalidResponse
                }
            } catch {
                throw error
            }
        }
    }
}

func extractIDs(from url: String) -> (showID: Int, episodeID: Int, translationID: Int?)? {
    let pattern = #/\/catalog\/(?:.*?)-(?<showID>\d+)\/(?:.*?)-(?<episodeID>\d+)(?:\/(?:.*?)-(?<translationID>\d+))?/#

    if let match = url.firstMatch(of: pattern) {
        if let showID = Int(match.output.showID), let episodeID = Int(match.output.episodeID) {
            if let translationIDString = match.output.translationID {
                return (showID, episodeID, Int(translationIDString))
            }
            return (showID, episodeID, nil)
        }
    }

    return nil
}
