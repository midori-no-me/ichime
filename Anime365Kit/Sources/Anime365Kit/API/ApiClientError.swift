import Foundation

public enum ApiClientError: Error, Sendable {
  case canNotDecodeResponseJson
  case apiError(ApiError)
  case requestFailed
}
