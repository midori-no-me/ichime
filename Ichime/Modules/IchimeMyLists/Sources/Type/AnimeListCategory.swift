import Anime365Kit

public enum AnimeListCategory: CaseIterable, Identifiable, Sendable {
  case watching
  case completed
  case onHold
  case dropped
  case planned

  public var id: Self { self }

  public var anime365KitType: Anime365Kit.AnimeListCategory {
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

  public var label: String {
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
