import Foundation
//
//  Description.swift
//  Ichime
//
//  Created by Nafranets Nikita on 13.12.2024.
//
import SwiftData

struct DbDescription: Codable {
  let source: String
  let updatedDateTime: String
  let value: String
}

@Model
class DbGenre {
  #Index<DbGenre>([\.id], [\.id, \.title])
  @Attribute(.unique)
  var id: Int
  var title: String
  var url: String

  @Relationship(inverse: \DbAnime.genres)
  var anime: [DbAnime] = []

  init(id: Int, title: String, url: String) {
    self.id = id
    self.title = title
    self.url = url
  }
}

struct DbVideo: Codable {
  let hosting: String
  let id: Int64
  let imageUrl: String
  let kind: String
  let name: String
  let playerUrl: String
  let url: String
}

@Model
class DbStudio {
  #Index<DbStudio>([\.id])
  var filteredName: String
  @Attribute(.unique)
  var id: Int
  var image: String
  var name: String
  var real: Bool

  @Relationship(inverse: \DbAnime.studios)
  var anime: [DbAnime] = []

  init(filteredName: String, id: Int, image: String, name: String, real: Bool) {
    self.filteredName = filteredName
    self.id = id
    self.image = image
    self.name = name
    self.real = real
  }
}

struct DbImage: Codable {
  let original: String
  let preview: String
  let x48: String?
  let x96: String?
}

struct DbPoster: Codable {
  let anime365: DbImage
  let shikimori: DbImage
}

struct DbRoleName: Codable {
  let name: String
  let russian: String
}

struct DbRole: Codable {
  var character: DbCharacter
  var roleNames: [DbRoleName]

  init(character: DbCharacter, roleNames: [DbRoleName]) {
    self.character = character
    self.roleNames = roleNames
  }
}

struct DbCharacter: Codable {
  let id: Int
  let image: DbImage
  let name: String
  let russian: String

  init(id: Int, image: DbImage, name: String, russian: String) {
    self.id = id
    self.image = image
    self.name = name
    self.russian = russian
  }
}

struct DbEpisodeTitles: Codable {
  let en: String
  let ja: String
  let romaji: String
}

struct DbEpisode: Codable {
  let number: Int
  let type: String
  let title: String
  let titles: DbEpisodeTitles?
  let firstUploadedDateTime: String
  let id: Int
  let isActive: Int
  let isFirstUploaded: Int
  let seriesId: Int
  let airDate: String
  let rating: String
}

struct DbTitles: Codable {
  let ru: String
  let en: String
  let ja: String
  let romaji: String
}

struct DbSimilarTitles: Codable {
  let ru: String
  let en: String
}

struct DbSimilar: Codable {
  let myAnimeListId: Int
  let score: Float
  let titles: DbSimilarTitles
  let image: DbImage
}

@Model
class DbAnime: ReflectedStringConvertible {
  #Index<DbAnime>([\.id], [\.id, \.myAnimeListId])
  @Attribute(.unique)
  var id: Int
  var myAnimeListId: Int
  var score: String
  var titles: DbTitles
  var type: String
  var typeTitle: String
  var year: Int
  var season: String
  var numberOfEpisodes: Int
  var duration: Int
  var airedOn: String
  var isAiring: Int
  var releasedOn: String

  var descriptions: [DbDescription] = []
  var studios: [DbStudio] = []
  var poster: DbPoster
  var trailers: [DbVideo] = []
  var genres: [DbGenre] = []
  var roles: [DbRole] = []
  var screenshots: [DbImage] = []
  var episodes: [DbEpisode] = []

  var similar: [DbSimilar] = []

  init(
    id: Int,
    myAnimeListId: Int,
    score: String,
    titles: DbTitles,
    type: String,
    typeTitle: String,
    year: Int,
    season: String,
    numberOfEpisodes: Int,
    duration: Int,
    airedOn: String,
    isAiring: Int,
    releasedOn: String,
    descriptions: [DbDescription],
    studios: [DbStudio],
    poster: DbPoster,
    trailers: [DbVideo],
    genres: [DbGenre],
    roles: [DbRole],
    screenshots: [DbImage],
    episodes: [DbEpisode],
    similar: [DbSimilar] = []
  ) {
    self.id = id
    self.myAnimeListId = myAnimeListId
    self.score = score
    self.titles = titles
    self.type = type
    self.typeTitle = typeTitle
    self.year = year
    self.season = season
    self.numberOfEpisodes = numberOfEpisodes
    self.duration = duration
    self.airedOn = airedOn
    self.isAiring = isAiring
    self.releasedOn = releasedOn
    self.descriptions = descriptions
    self.studios = studios
    self.poster = poster
    self.trailers = trailers
    self.genres = genres
    self.roles = roles
    self.screenshots = screenshots
    self.episodes = episodes
    self.similar = similar
  }
}

public protocol ReflectedStringConvertible: CustomStringConvertible {}

extension ReflectedStringConvertible {
  public var description: String {
    let mirror = Mirror(reflecting: self)

    var str = "\(mirror.subjectType)("
    var first = true
    for (label, value) in mirror.children {
      if let label = label {
        if first {
          first = false
        }
        else {
          str += ", "
        }
        str += label
        str += ": "
        str += "\(value)"
      }
    }
    str += ")"

    return str
  }
}
