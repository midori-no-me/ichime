import Foundation
import ShikimoriApiClient

struct ShowPreviewShikimori: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let kind: ShowKind?

  init(
    anime: ShikimoriApiClient.AnimePreview,
    shikimoriBaseUrl: URL
  ) {
    self.id = anime.id
    self.title = .parsed(anime.name, anime.russian != "" ? anime.russian : nil)

    if let image = anime.image {
      self.posterUrl = URL(string: shikimoriBaseUrl.absoluteString + image.original)
    }
    else {
      self.posterUrl = nil
    }

    if let scoreString = anime.score, let score = Float(scoreString), score > 0 {
      self.score = score
    }
    else {
      self.score = nil
    }

    let dateWithoutTimeFormatter = ShikimoriApiClient.ApiDateDecoder.getDateWithoutTimeFormatter()

    if let airedOnString = anime.aired_on, let airedAt = dateWithoutTimeFormatter.date(from: airedOnString) {
      self.airingSeason = .init(fromDate: airedAt)
    }
    else {
      self.airingSeason = nil
    }

    if let kind = anime.kind {
      self.kind = .create(kind)
    }
    else {
      self.kind = nil
    }
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
