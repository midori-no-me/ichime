enum WebClientError: Error {
  case couldNotConvertResponseToHttpResponse
  case couldNotConvertResponseDataToString
  case badStatusCode
  case unknownError(Error)
}
