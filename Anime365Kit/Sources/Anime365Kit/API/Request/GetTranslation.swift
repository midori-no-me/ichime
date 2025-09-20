import Foundation

extension ApiClient {
  public func getTranslation(
    translationId: Int
  ) async throws -> TranslationFull {
    try await sendRequest(
      endpoint: "/translations/\(translationId)",
      queryItems: []
    )
  }
}
