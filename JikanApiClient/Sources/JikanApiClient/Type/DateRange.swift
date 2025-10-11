public struct DateRange: Sendable, Decodable {
  public struct DateRangeParsed: Sendable, Decodable {
    public struct DateRangeParsedProperties: Sendable, Decodable {
      public let year: Int?
    }

    public let from: DateRangeParsedProperties
  }

  public let prop: DateRangeParsed
}
