import Foundation
import ShikimoriApiClient

struct RelatedShow: Identifiable, Hashable {
  let relationKind: ShowRelationKind
  let preview: ShowPreviewShikimori

  var id: Int {
    self.preview.id
  }

  init?(
    fromShikimoriRelation: ShikimoriApiClient.GetRelatedResponse.AnimeFields.Relation,
  ) {
    guard let anime = fromShikimoriRelation.anime else {
      return nil
    }

    if let preview = ShowPreviewShikimori(graphqlAnimePreview: anime) {
      self.preview = preview
    }
    else {
      return nil
    }

    self.relationKind = .create(fromShikimoriRelation.relationKind)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
