import Foundation
import ScraperAPI

extension ScraperAPI.Types.WatchShow.UpdateType {
  var displayName: String {
    let formatedDate: String
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yy"
    formatedDate = formatter.string(from: date)

    switch self {
    case .plan:
      return String(localized: "В планах с \(formatedDate)")
    case .release:
      return String(localized: "Вышло \(formatedDate)")
    case .update:
      return String(localized: "Смотрели \(formatedDate)")
    }
  }
}

struct WatchCardModel: Equatable, Identifiable, Hashable {
  struct WatchData: Hashable {
    let episode: Int
  }

  let id: Int
  let name: ScraperAPI.Types.Name
  let image: URL
  let title: String
  let sideText: String
  let data: WatchData

  init(
    id: Int,
    image: URL,
    name: ScraperAPI.Types.Name,
    title: String,
    sideText: String,
    data watchData: WatchData
  ) {
    self.id = id
    self.name = name
    self.image = image
    self.title = title
    self.sideText = sideText
    self.data = watchData
  }

  init(from show: ScraperAPI.Types.WatchShow) {
    self.init(
      id: show.episode.id,
      image: show.imageURL,
      name: show.name,
      title: show.episode.displayName,
      sideText: show.update.displayName,
      data: .init(episode: show.episode.id)
    )
  }

  init(from notification: ScraperAPI.Types.Notification) {
    self.init(
      id: notification.translation.id,
      image: notification.imageURL,
      name: notification.name,
      title: notification.episode.displayName,
      sideText: notification.translation.type,
      data: .init(
        episode: notification.episode.id
      )
    )
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
