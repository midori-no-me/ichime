import Foundation

public struct GetTranslationEmbed: Anime365ApiRequest {
    public typealias ResponseType = Anime365TranslationEmbed

    private let translationId: Int

    public init(
        translationId: Int
    ) {
        self.translationId = translationId
    }

    public func getEndpoint() -> String {
        return "/translations/embed/\(self.translationId)"
    }

    public func getQueryItems() -> [URLQueryItem] {
        return []
    }
}
