import Foundation
import ScraperAPI

struct Moment: Identifiable {
  let id: Int
  let title: String
  let thumbnailUrl: URL

  static func create(
    anime365Moment: ScraperAPI.Types.Moment
  ) -> Self {
    .init(
      id: anime365Moment.id,
      title: anime365Moment.title,
      thumbnailUrl: anime365Moment.preview
    )
  }
}
