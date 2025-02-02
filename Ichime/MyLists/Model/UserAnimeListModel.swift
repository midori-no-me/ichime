//
//  UserAnimeListModel.swift
//  Ichime
//
//  Created by Nafranets Nikita on 15.12.2024.
//
import ScraperAPI
import SwiftData

@Model
class UserAnimeListModel {
  #Index<UserAnimeListModel>([\.id])
  @Attribute(.unique) var id: Int
  var name: UserAnimeListName
  var statusRaw: String
  var score: Int
  var progress: UserAnimeProgress

  init(id: Int, name: UserAnimeListName, status: AnimeWatchStatus, score: Int, progress: UserAnimeProgress) {
    self.id = id
    self.name = name
    self.statusRaw = status.rawValue
    self.score = score
    self.progress = progress
  }
}

enum AnimeWatchStatus: String, Codable, CaseIterable {
  case watching = "watching"
  case completed = "completed"
  case onHold = "onHold"
  case dropped = "dropped"
  case planned = "planned"

  var title: String {
    switch self {
    case .watching: return "Смотрю"
    case .completed: return "Просмотрено"
    case .onHold: return "Отложено"
    case .dropped: return "Брошено"
    case .planned: return "Запланировано"
    }
  }

  var imageInToolbarNotFilled: String {
    switch self {
    case .planned: return "hourglass.circle"
    case .watching: return "eye.circle"
    case .completed: return "checkmark.circle"
    case .onHold: return "pause.circle"
    case .dropped: return "archivebox.circle"
    }
  }

  init(from category: ScraperAPI.Types.ListCategoryType) {
    switch category {
    case .watching: self = .watching
    case .completed: self = .completed
    case .onHold: self = .onHold
    case .dropped: self = .dropped
    case .planned: self = .planned
    }
  }
}

struct UserAnimeProgress: Codable {
  let watched: Int
  let total: Int?
}

struct UserAnimeListName: Codable {
  let ru: String
  let romaji: String
}
