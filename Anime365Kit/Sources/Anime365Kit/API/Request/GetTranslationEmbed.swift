import Foundation

extension ApiClient {
  public func getTranslationEmbed(
    translationId: Int
  ) async throws -> TranslationEmbed {
    try await sendRequest(
      endpoint: "/translations/embed/\(translationId)",
      queryItems: []
    )
  }
}
