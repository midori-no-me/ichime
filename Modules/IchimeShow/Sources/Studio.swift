import Foundation
import ShikimoriApiClient

public struct Studio: Identifiable, Hashable {
  // MARK: Properties

  public let id: Int
  public let name: String
  public let image: URL?

  // MARK: Lifecycle

  public init(
    fromShikimoriStudio: ShikimoriApiClient.Studio,
    shikimoriBaseURL: URL
  ) {
    self.id = fromShikimoriStudio.id
    self.name = fromShikimoriStudio.filtered_name.trimmingCharacters(in: .whitespacesAndNewlines)

    if let imagePath = fromShikimoriStudio.image {
      self.image = URL(string: shikimoriBaseURL.absoluteString + imagePath)
    }
    else {
      self.image = nil
    }
  }

  public init?(fromShikimoriGraphQLStudio: ShikimoriApiClient.GetAnimeResponse.Anime.Studio) {
    guard let id = Int(fromShikimoriGraphQLStudio.id) else {
      return nil
    }

    self.id = id
    self.name = fromShikimoriGraphQLStudio.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.image = fromShikimoriGraphQLStudio.imageUrl
  }
}
