import Foundation
import ScraperAPI

struct EpisodeFromCurrentlyWatchingList {
  let showName: ShowName
  let episodeTitle: String
  let updateNote: String
  let showId: Int
  let episodeId: Int
  let coverUrl: URL?

  init(fromScraperWatchShow: ScraperAPI.Types.WatchShow) {
    self.showName = ParsedShowName(
      russian: fromScraperWatchShow.showName.ru,
      romaji: fromScraperWatchShow.showName.romaji
    )

    self.episodeTitle = fromScraperWatchShow.episodeTitle
    self.updateNote = fromScraperWatchShow.updateType
    self.showId = fromScraperWatchShow.showId
    self.episodeId = fromScraperWatchShow.episodeId
    self.coverUrl = fromScraperWatchShow.imageURL
  }
}
