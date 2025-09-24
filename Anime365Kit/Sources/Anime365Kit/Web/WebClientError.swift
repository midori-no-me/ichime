public enum WebClientError: Error {
  case couldNotConvertResponseToHttpResponse
  case couldNotConvertResponseDataToString
  case badStatusCode
  case authenticationRequired
  case couldNotParseHtml
  case unknownError(Error)
}
