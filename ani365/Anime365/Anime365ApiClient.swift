//
//  ApiClient.swift
//  ani365
//
//  Created by p.flaks on 02.01.2024.
//

import Foundation

enum Anime365ApiClientError: Error {
    case invalidData
    case invalidURL
    case requestFailed
}

struct Anime365ApiResponse<T: Decodable>: Decodable {
    let data: T
}

struct Anime365ApiSeries: Decodable {
    let id: Int
    let title: String
    let posterUrl: String
    let posterUrlSmall: String
    let myAnimeListScore: String
    let url: String
    let isAiring: Int
    let numberOfEpisodes: Int
    let season: String
    let year: Int
    let type: String
    let typeTitle: String
    let titles: Anime365ApiSeriesTitles
    let genres: [Anime365ApiSeriesGenre]?
    let descriptions: [Anime365ApiSeriesDescription]?
    let episodes: [Anime365ApiEpisodePreview]?

    struct Anime365ApiSeriesTitles: Decodable {
        let ru: String?
        let romaji: String?
        let ja: String?
        let en: String?
    }

    struct Anime365ApiSeriesGenre: Decodable {
        let id: Int
        let title: String
        let url: String
    }

    struct Anime365ApiSeriesDescription: Decodable {
        let source: String
        let value: String
        let updatedDateTime: String
    }

    struct Anime365ApiEpisodePreview: Decodable {
        let id: Int
        let episodeFull: String
        let episodeInt: String
        let episodeTitle: String
        let episodeType: String
        let firstUploadedDateTime: String
        let isActive: Int
        let isFirstUploaded: Int
    }
}

struct Anime365ApiTranslation: Decodable {
    let id: Int
    let activeDateTime: String
    let authorsList: [String]
    let isActive: Int
    let priority: Int
    let qualityType: String
    let typeKind: String
    let typeLang: String
    let updatedDateTime: String
    let title: String
    let url: String
    let authorsSummary: String
    let duration: String
    let width: Int
    let height: Int
}

struct Anime365Embed: Decodable {
    let embedUrl: String
    let download: [Download]
    let stream: [Stream]
    let subtitlesUrl: String?
    let subtitlesVttUrl: String?

    struct Download: Decodable {
        let height: Int
        let url: String
    }

    struct Stream: Decodable {
        let height: Int
        let urls: [String]
    }
}

final class Anime365ApiClient {
    private let baseURL: String
    private let userAgent: String

    init(
        baseURL: String,
        userAgent: String
    ) {
        self.baseURL = baseURL
        self.userAgent = userAgent
    }

    public func listSeries(
        query: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        chips: [String: String]? = nil
    ) async throws -> Anime365ApiResponse<[Anime365ApiSeries]> {
        var queryItems: [URLQueryItem] = []

        if let chips {
            queryItems.append(URLQueryItem(
                name: "chips",
                value: chips
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: ";")
            ))
        }

        if let query {
            queryItems.append(URLQueryItem(
                name: "query",
                value: query
            ))
        }

        if let limit {
            queryItems.append(URLQueryItem(
                name: "limit",
                value: String(limit)
            ))
        }

        if let offset {
            queryItems.append(URLQueryItem(
                name: "offset",
                value: String(offset)
            ))
        }

        return try await performRequest(
            endpoint: "/series",
            queryItems: queryItems,
            responseType: Anime365ApiResponse<[Anime365ApiSeries]>.self
        )
    }

    public func getSeries(
        seriesId: Int
    ) async throws -> Anime365ApiResponse<Anime365ApiSeries> {
        return try await performRequest(
            endpoint: "/series/\(seriesId)",
            responseType: Anime365ApiResponse<Anime365ApiSeries>.self
        )
    }

    public func listTranslations(
        episodeId: Int? = nil,
        seriesId: Int? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> Anime365ApiResponse<[Anime365ApiTranslation]> {
        var queryItems: [URLQueryItem] = []

        if let episodeId {
            queryItems.append(URLQueryItem(
                name: "episodeId",
                value: String(episodeId)
            ))
        }

        if let seriesId {
            queryItems.append(URLQueryItem(
                name: "seriesId",
                value: String(seriesId)
            ))
        }

        if let limit {
            queryItems.append(URLQueryItem(
                name: "limit",
                value: String(limit)
            ))
        }

        if let offset {
            queryItems.append(URLQueryItem(
                name: "offset",
                value: String(offset)
            ))
        }

        return try await performRequest(
            endpoint: "/translations",
            queryItems: queryItems,
            responseType: Anime365ApiResponse<[Anime365ApiTranslation]>.self
        )
    }

    public func getEmbed(
        translationId: Int
    ) async throws -> Anime365ApiResponse<Anime365Embed> {
        return try await performRequest(
            endpoint: "/translations/embed/\(translationId)",
            responseType: Anime365ApiResponse<Anime365Embed>.self
        )
    }

    private func performRequest<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem] = [],
        responseType: T.Type
    ) async throws -> T {
        guard let url = buildURL(endpoint: endpoint, queryItems: queryItems) else {
            throw Anime365ApiClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let requestUrl = request.url?.absoluteString, let httpResponse = httpResponse as? HTTPURLResponse {
            print("[Anime365ApiClient] API request: GET \(requestUrl) [\(httpResponse.statusCode)]")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[Anime365ApiClient] Decoding JSON error: \(error.localizedDescription)")
            print("[Anime365ApiClient] JSON Decoder detailed error:")
            print(error)
            print("[Anime365ApiClient] API response:")

            if let responseBodyString = String(data: data, encoding: .utf8) {
                print(responseBodyString)
            } else {
                print("[Anime365ApiClient] Unable to convert response body to string")
            }

            throw Anime365ApiClientError.invalidData
        }
    }

    private func buildURL(endpoint: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: baseURL + "/api" + endpoint)

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        return components?.url
    }
}
