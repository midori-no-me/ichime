import Anime365Kit
import Foundation
import IchimeShow

public struct MomentDetails {
  // MARK: Properties

  public let showID: Int
  public let showTitle: ShowName

  // MARK: Lifecycle

  public init(
    fromAnime365MomentDetails anime365MomentDetails: Anime365Kit.MomentDetails
  ) {
    self.showID = anime365MomentDetails.seriesID
    self.showTitle = .fromFullName(anime365MomentDetails.seriesTitle)
  }
}
