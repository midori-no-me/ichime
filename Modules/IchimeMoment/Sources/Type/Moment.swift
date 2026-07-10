import Anime365Kit
import Foundation

public struct Moment: Identifiable, Hashable {
  public let id: Int
  public let title: String
  public let thumbnailURL: URL
  public let showTitle: String
  public let duration: Duration

  public init(
    fromAnime365Moment: Anime365Kit.MomentPreview
  ) {
    self.id = fromAnime365Moment.momentID
    self.title = fromAnime365Moment.momentTitle
    self.thumbnailURL = fromAnime365Moment.coverURL
    self.showTitle = fromAnime365Moment.sourceDescription
    self.duration = fromAnime365Moment.duration
  }
}
