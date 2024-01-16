import Foundation

struct Show: Hashable, Identifiable {
    static func createFromApiSeries(
        series: Anime365ApiSeries
    ) -> Show {
        let score = Float(series.myAnimeListScore) ?? 0

        return Show(
            id: series.id,
            title: Show.Title(
                full: series.title,
                translated: Show.Title.TranslatedTitles(
                    russian: series.titles.ru,
                    english: series.titles.en,
                    japanese: series.titles.ja,
                    japaneseRomaji: series.titles.romaji
                )
            ),
            descriptions: (series.descriptions ?? []).map { description in
                Show.Description(
                    text: description.value,
                    source: description.source
                )
            },
            posterUrl: URL(string: series.posterUrl),
            websiteUrl: URL(string: series.url)!,
            score: score <= 0 ? nil : Float(series.myAnimeListScore),
            calendarSeason: series.season,
            numberOfEpisodes: series.numberOfEpisodes <= 0 ? nil : series.numberOfEpisodes,
            typeTitle: series.typeTitle,
            genres: (series.genres ?? []).map { genre in
                genre.title
            },
            isOngoing: series.isAiring == 1,
            episodePreviews: (series.episodes ?? []).map { episode in
                EpisodePreview(
                    id: episode.id,
                    title: episode.episodeTitle.isEmpty ? nil : episode.episodeTitle,
                    typeAndNumber: episode.episodeFull,
                    uploadDate: convertApiDateStringToDate(string: episode.firstUploadedDateTime)!,
                    type: EpisodeType.createFromApiType(apiType: episode.episodeType),
                    episodeNumber: Float(episode.episodeInt)
                )
            }
        )
    }

    static func == (lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: Int
    let title: Title
    let descriptions: [Description]
    let posterUrl: URL?
    let websiteUrl: URL
    let score: Float?
    let calendarSeason: String
    let numberOfEpisodes: Int?
    let typeTitle: String
    let genres: [String]
    let isOngoing: Bool
    let episodePreviews: [EpisodePreview]

    struct Title {
        let full: String
        let translated: TranslatedTitles

        struct TranslatedTitles {
            let russian: String?
            let english: String?
            let japanese: String?
            let japaneseRomaji: String?
        }
    }

    struct Description: Hashable {
        static func == (lhs: Description, rhs: Description) -> Bool {
            return lhs.text == rhs.text
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
        }

        let text: String
        let source: String
    }
}
