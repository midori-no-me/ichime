import Foundation

public enum ApiClientError: Error {
  case canNotDecodeResponseJson
  case apiError(ApiError)
  case requestFailed
}
