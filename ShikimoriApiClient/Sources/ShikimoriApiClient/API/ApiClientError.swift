import Foundation

public enum ApiClientError: Error, Sendable {
  case canNotDecodeResponseJson
  case canNotEncodeRequestJson
  case requestFailed
}
