public enum ApiError: Error {
  case authenticationRequired
  case notFound
  case other(Int, String)
}
