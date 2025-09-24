import Foundation

extension ApiClient {
  public func getTranslationEmbed(
    translationId: Int
  ) async throws(ApiClientError) -> TranslationEmbed {
    try await sendRequest(
      endpoint: "/translations/embed/\(translationId)",
      queryItems: []
    )
  }
}
