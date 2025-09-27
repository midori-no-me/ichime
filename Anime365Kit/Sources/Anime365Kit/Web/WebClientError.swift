public enum WebClientError: Error, Sendable {
  case couldNotConvertResponseToHttpResponse
  case couldNotConvertResponseDataToString
  case badStatusCode
  case authenticationRequired
  case couldNotParseHtml
  case unknownError(Error)
}
