import OrderedCollections

public struct GroupedRelatedShows: Identifiable, Hashable {
  public let relationKind: ShowRelationKind
  public let relatedShows: OrderedSet<RelatedShow>

  public var id: ShowRelationKind {
    self.relationKind
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
