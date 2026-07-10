import Foundation
import ShikimoriApiClient

public struct Studio: Identifiable, Hashable {
  public let id: Int
  public let name: String
  public let image: URL?

  public init(
    fromShikimoriStudio: ShikimoriApiClient.Studio,
    shikimoriBaseUrl: URL
  ) {
    self.id = fromShikimoriStudio.id
    self.name = fromShikimoriStudio.filtered_name.trimmingCharacters(in: .whitespacesAndNewlines)

    if let imagePath = fromShikimoriStudio.image {
      self.image = URL(string: shikimoriBaseUrl.absoluteString + imagePath)
    }
    else {
      self.image = nil
    }
  }
}
