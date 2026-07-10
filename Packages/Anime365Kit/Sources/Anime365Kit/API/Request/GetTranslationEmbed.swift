import Foundation

extension ApiClient {
  public func getTranslationEmbed(
    translationID: Int
  ) async throws(ApiClientError) -> TranslationEmbed {
    try await sendRequest(
      endpoint: "/translations/embed/\(translationID)",
      queryItems: []
    )
  }
}
