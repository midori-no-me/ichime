import OrderedCollections

public struct GroupedRelatedShows: Identifiable, Hashable {
  // MARK: Properties

  public let relationKind: ShowRelationKind
  public let relatedShows: OrderedSet<RelatedShow>

  // MARK: Computed Properties

  public var id: ShowRelationKind {
    self.relationKind
  }

  // MARK: Static Functions

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
