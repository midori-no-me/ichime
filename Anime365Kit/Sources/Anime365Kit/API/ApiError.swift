public enum ApiError: Error {
  case authenticationRequired
  case other(Int, String)
}
