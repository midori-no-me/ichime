import Foundation

public enum ApiClientError: Error {
  case canNotDecodeResponseJson
  case canNotEncodeRequestJson
  case requestFailed
}
