//
//  Anime365.swift
//  ani365
//
//  Created by p.flaks on 02.01.2024.
//

import Foundation

func convertApiDateStringToDate(string: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = format

    let date = dateFormatter.date(from: string)

    return date
}

class Anime365Client {
    private let apiClient: Anime365ApiClient

    init(
        apiClient: Anime365ApiClient
    ) {
        self.apiClient = apiClient
    }

    public func getShow(seriesId: Int) async throws -> Show {
        let apiResponse = try await apiClient.getSeries(seriesId: seriesId)

        return Show.createFromApiSeries(series: apiResponse.data)
    }

    public func getOngoings(
        offset: Int,
        limit: Int
    ) async throws -> [Show] {
        let apiResponse = try await apiClient.listSeries(
            limit: limit,
            offset: offset,
            chips: [
                "isAiring": "1",
                "yearseason": "winter_2023-winter_2024"
            ]
        )

        return apiResponse.data.map { series in
            Show.createFromApiSeries(series: series)
        }
    }

    public func getEpisodeTranslations(
        episodeId: Int
    ) async throws -> [Translation] {
        let apiResponse = try await apiClient.listTranslations(
            episodeId: episodeId,
            limit: 1000,
            offset: 0
        )

        return apiResponse.data.map { translation in
            Translation.createFromApiSeries(translation: translation)
        }
    }

    public func searchShows(
        searchQuery: String,
        offset: Int,
        limit: Int
    ) async throws -> [Show] {
        let apiResponse = try await apiClient.listSeries(
            query: searchQuery,
            limit: limit,
            offset: offset
        )

        return apiResponse.data.map { series in
            Show.createFromApiSeries(series: series)
        }
    }
}
