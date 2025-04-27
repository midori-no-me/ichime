struct GroupedRelatedShows: Identifiable {
  let relationKind: ShowRelationKind
  let relatedShows: [RelatedShow]

  var id: ShowRelationKind {
    self.relationKind
  }
}
