import Foundation
import ShikimoriApiClient

public struct RelatedShow: Identifiable, Hashable {
  // MARK: Properties

  public let relationKind: ShowRelationKind
  public let preview: ShowPreviewShikimori

  // MARK: Computed Properties

  public var id: Int {
    self.preview.id
  }

  // MARK: Lifecycle

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

  // MARK: Static Functions

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
