import Foundation
import ShikimoriApiClient

struct Studio: Identifiable, Hashable {
  let id: Int
  let name: String
  let image: URL?

  init(
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
