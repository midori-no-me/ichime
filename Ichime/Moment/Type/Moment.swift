import Anime365Kit
import Foundation

struct Moment: Identifiable, Hashable {
  let id: Int
  let title: String
  let thumbnailUrl: URL
  let showTitle: String

  init(
    fromAnime365Moment: Anime365Kit.MomentPreview
  ) {
    self.id = fromAnime365Moment.momentId
    self.title = fromAnime365Moment.momentTitle
    self.thumbnailUrl = fromAnime365Moment.coverURL
    self.showTitle = fromAnime365Moment.sourceDescription
  }
}
