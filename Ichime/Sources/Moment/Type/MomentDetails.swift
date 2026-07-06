import Anime365Kit
import Foundation

struct MomentDetails {
  let showId: Int
  let showTitle: ShowName

  init(
    fromAnime365MomentDetails anime365MomentDetails: Anime365Kit.MomentDetails
  ) {
    self.showId = anime365MomentDetails.seriesID
    self.showTitle = .fromFullName(anime365MomentDetails.seriesTitle)
  }
}
