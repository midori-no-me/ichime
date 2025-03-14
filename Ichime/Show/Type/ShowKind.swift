import Anime365ApiClient
import ShikimoriApiClient

enum ShowKind {
  case tv
  case movie
  case ova
  case ona
  case special
  case tvSpecial
  case music
  case promotionalVideo
  case commercial

  var title: String {
    switch self {
    case .tv:
      "ТВ сериал"
    case .movie:
      "Фильм"
    case .ova:
      "OVA"
    case .ona:
      "ONA"
    case .special:
      "Спешл"
    case .tvSpecial:
      "ТВ спешл"
    case .music:
      "Клип"
    case .promotionalVideo:
      "Проморолик"
    case .commercial:
      "Реклама"
    }
  }

  static func create(_ fromShikimoriApiEnum: ShikimoriApiClient.AnimeKind) -> Self {
    switch fromShikimoriApiEnum {
    case .tv:
      .tv
    case .movie:
      .movie
    case .ova:
      .ova
    case .ona:
      .ona
    case .special:
      .special
    case .tv_special:
      .tvSpecial
    case .music:
      .music
    case .pv:
      .promotionalVideo
    case .cm:
      .commercial
    }
  }

  static func create(_ fromAnime365ApiEnum: Anime365ApiClient.SeriesType) -> Self {
    switch fromAnime365ApiEnum {
    case .tv:
      .tv
    case .movie:
      .movie
    case .ova:
      .ova
    case .ona:
      .ona
    case .special:
      .special
    case .tv_special:
      .tvSpecial
    case .music:
      .music
    case .pv:
      .promotionalVideo
    case .cm:
      .commercial
    }
  }
}
