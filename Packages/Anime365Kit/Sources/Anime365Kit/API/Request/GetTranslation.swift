import Foundation

extension ApiClient {
  public func getTranslation(
    translationID: Int
  ) async throws(ApiClientError) -> TranslationFull {
    try await sendRequest(
      endpoint: "/translations/\(translationID)",
      queryItems: []
    )
  }
}
