import Foundation
import ShikimoriApiClient

public struct RelatedShow: Identifiable, Hashable {
  public let relationKind: ShowRelationKind
  public let preview: ShowPreviewShikimori

  public var id: Int {
    self.preview.id
  }

  public init?(
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

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
