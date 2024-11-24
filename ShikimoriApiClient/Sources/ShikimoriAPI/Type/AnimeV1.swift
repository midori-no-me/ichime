import Foundation

public struct AnimeV1: Decodable {
    public let id: Int
    public let name: String
    public let russian: String
    public let image: Image
    public let url: String
    public let kind: String
    public let score: String
    public let status: String
    public let episodes: Int
    public let episodes_aired: Int
    public let aired_on: String
    public let released_on: String?

    public struct Image: Decodable {
        public let original: String
        public let preview: String
        public let x96: String
        public let x48: String
    }
}
