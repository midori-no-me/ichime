import Foundation

public enum ApiClientError: Error {
  case canNotDecodeResponseJson
  case requestFailed
}
