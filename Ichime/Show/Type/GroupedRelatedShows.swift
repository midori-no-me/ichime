import OrderedCollections

struct GroupedRelatedShows: Identifiable, Hashable {
  let relationKind: ShowRelationKind
  let relatedShows: OrderedSet<RelatedShow>

  var id: ShowRelationKind {
    self.relationKind
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
