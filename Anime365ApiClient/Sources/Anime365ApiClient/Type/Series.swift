public struct Anime365ApiSeries: Decodable {
    public let id: Int
    public let title: String
    public let posterUrl: String
    public let posterUrlSmall: String
    public let myAnimeListScore: String
    public let url: String
    public let isAiring: Int
    public let numberOfEpisodes: Int
    public let season: String
    public let year: Int
    public let type: String
    public let typeTitle: String
    public let titles: Titles
    public let genres: [Genre]?
    public let descriptions: [Description]?
    public let episodes: [EpisodePreview]?

    public struct Titles: Decodable {
        public let ru: String?
        public let romaji: String?
        public let ja: String?
        public let en: String?
    }

    public struct Genre: Decodable {
        public let id: Int
        public let title: String
        public let url: String
    }

    public struct Description: Decodable {
        public let source: String
        public let value: String
        public let updatedDateTime: String
    }

    public struct EpisodePreview: Decodable {
        public let id: Int
        public let episodeFull: String
        public let episodeInt: String
        public let episodeTitle: String
        public let episodeType: String
        public let firstUploadedDateTime: String
        public let isActive: Int
        public let isFirstUploaded: Int
    }
}
