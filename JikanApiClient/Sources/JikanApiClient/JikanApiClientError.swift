import Foundation

public enum JikanApiClientError: Error {
  case canNotDecodeResponseJson
  case requestFailed
}
