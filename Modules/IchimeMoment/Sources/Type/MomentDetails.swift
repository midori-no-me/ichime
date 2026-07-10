import Anime365Kit
import Foundation
import IchimeShow

public struct MomentDetails {
  public let showID: Int
  public let showTitle: ShowName

  public init(
    fromAnime365MomentDetails anime365MomentDetails: Anime365Kit.MomentDetails
  ) {
    self.showID = anime365MomentDetails.seriesID
    self.showTitle = .fromFullName(anime365MomentDetails.seriesTitle)
  }
}
