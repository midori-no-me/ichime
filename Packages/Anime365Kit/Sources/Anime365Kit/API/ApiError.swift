public enum ApiError: Error, Sendable {
  case authenticationRequired
  case notFound
  case other(Int, String)
}
