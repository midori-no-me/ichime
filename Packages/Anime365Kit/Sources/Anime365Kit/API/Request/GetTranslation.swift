import Foundation

extension ApiClient {
  public func getTranslation(
    translationId: Int
  ) async throws(ApiClientError) -> TranslationFull {
    try await sendRequest(
      endpoint: "/translations/\(translationId)",
      queryItems: []
    )
  }
}
