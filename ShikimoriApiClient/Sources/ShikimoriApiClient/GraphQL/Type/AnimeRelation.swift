import Foundation

public struct GraphQLAnimeWithRelations: Sendable, Decodable {
  public struct Relation: Sendable, Decodable {
    public let relationKind: RelationKind
    public let anime: GraphQLAnimePreview?
  }

  public let related: [Relation]
}
