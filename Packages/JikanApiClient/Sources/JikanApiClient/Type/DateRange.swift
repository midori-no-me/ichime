public struct DateRange: Sendable, Decodable {
  // MARK: Nested Types

  public struct DateRangeParsed: Sendable, Decodable {
    // MARK: Nested Types

    public struct DateRangeParsedProperties: Sendable, Decodable {
      public let year: Int?
    }

    // MARK: Properties

    public let from: DateRangeParsedProperties
  }

  // MARK: Properties

  public let prop: DateRangeParsed
}
