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
    let episodes: [Anime365ApiEpisodePreview]

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
    }
}

final class Anime365ApiClient {
    private let baseURL: String
    private let userAgent: String
    private let accessToken: String?

    init(
        baseURL: String,
        userAgent: String,
        accessToken: String? = nil // TODO: make mandatory
    ) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.accessToken = accessToken
    }

    public func listSeries(
        chips: [String: String]?
    ) async throws -> Anime365ApiResponse<[Anime365ApiSeries]> {
        var queryItems: [URLQueryItem] = []

        if let chips {
            queryItems.append(URLQueryItem(
                name: "chips",
                value: chips.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
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
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        if let accessToken = accessToken {
            request.addValue("aaaa8ed0da05b797653c4bd51877d861=\(accessToken)", forHTTPHeaderField: "Cookie")
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        if let requestUrl = request.url?.absoluteString {
            print("[Anime365ApiClient] API request: GET \(requestUrl)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw Anime365ApiClientError.invalidData
        }
    }

    private func buildURL(endpoint: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = queryItems
        return components?.url
    }
}
