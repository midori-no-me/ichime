import Foundation
import ScraperAPI

struct Moment: Identifiable, Hashable {
  let id: Int
  let title: String
  let thumbnailUrl: URL
  let showTitle: String

  init(
    fromAnime365Moment: ScraperAPI.Types.Moment
  ) {
    self.id = fromAnime365Moment.id
    self.title = fromAnime365Moment.title
    self.thumbnailUrl = fromAnime365Moment.preview
    self.showTitle = fromAnime365Moment.fromAnime
  }
}
