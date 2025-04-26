import Foundation
import ScraperAPI

struct EpisodeFromCurrentlyWatchingList: Hashable, Identifiable {
  let showName: ShowName
  let episodeTitle: String
  let updateNote: String
  let showId: Int
  let episodeId: Int
  let coverUrl: URL?

  var id: Int {
    self.episodeId
  }

  init(fromScraperWatchShow: ScraperAPI.Types.WatchShow) {
    self.showName = .parsed(
      fromScraperWatchShow.showName.romaji,
      fromScraperWatchShow.showName.ru
    )

    self.episodeTitle = fromScraperWatchShow.episodeTitle
    self.updateNote = fromScraperWatchShow.updateType
    self.showId = fromScraperWatchShow.showId
    self.episodeId = fromScraperWatchShow.episodeId
    self.coverUrl = fromScraperWatchShow.imageURL
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.episodeId == rhs.episodeId
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.episodeId)
  }
}
