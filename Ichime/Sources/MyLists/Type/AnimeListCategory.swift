import Anime365Kit

enum AnimeListCategory: CaseIterable, Identifiable {
  case watching
  case completed
  case onHold
  case dropped
  case planned

  var id: Self { self }

  var anime365KitType: Anime365Kit.AnimeListCategory {
    switch self {
    case .watching:
      .watching
    case .completed:
      .completed
    case .onHold:
      .onHold
    case .dropped:
      .dropped
    case .planned:
      .planned
    }
  }

  var label: String {
    switch self {
    case .watching:
      "Смотрю"
    case .completed:
      "Просмотрено"
    case .onHold:
      "Отложено"
    case .dropped:
      "Брошено"
    case .planned:
      "Запланировано"
    }
  }
}
