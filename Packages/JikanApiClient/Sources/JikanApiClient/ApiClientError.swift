import Foundation

enum ApiClientError: Error, Sendable {
  case canNotDecodeResponseJson
}
