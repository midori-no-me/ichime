public struct Anime365ApiTranslation: Decodable {
    public let id: Int
    public let activeDateTime: String
    public let authorsList: [String]
    public let isActive: Int
    public let priority: Int
    public let qualityType: String
    public let typeKind: String
    public let typeLang: String
    public let updatedDateTime: String
    public let title: String
    public let url: String
    public let authorsSummary: String
    public let duration: String
    public let width: Int
    public let height: Int
}
