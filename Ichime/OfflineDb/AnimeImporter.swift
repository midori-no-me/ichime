import Foundation
import SwiftData

@ModelActor
actor AnimeImporter {
  private var progressStream: AsyncStream<String>?
  private var progressContinuation: AsyncStream<String>.Continuation?

  var currentProgress: AsyncStream<String> {
    if let stream = progressStream {
      return stream
    }

    var continuation: AsyncStream<String>.Continuation!
    let stream = AsyncStream<String> { cont in
      continuation = cont
    }

    self.progressStream = stream
    self.progressContinuation = continuation

    return stream
  }

  private var genresMap: [Int: DbGenre] = [:]
  private var studioMap: [Int: DbStudio] = [:]
  private var charactersMap: [Int: DbCharacter] = [:]
  private let batchSize = 250

  func importDatabase(from url: String) async throws {
    self.progressContinuation?.yield("Загрузка базы данных...")

    guard let url = URL(string: url) else {
      print("Invalid URL")
      return
    }

    let (fileUrl, _) = try await URLSession.shared.download(from: url)

    guard let reader = StreamReader(path: fileUrl.path) else {
      print("Invalid file")
      return
    }

    defer {
      reader.close()
      try? FileManager.default.removeItem(at: fileUrl)
      progressContinuation?.finish()
      genresMap = [:]
      studioMap = [:]
      if modelContext.hasChanges {
        try? modelContext.save()
      }
    }

    modelContext.autosaveEnabled = false
    let startTime = Date()

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    var models: [DbAnime] = []
    let startParseTime = Date()

    self.progressContinuation?.yield("Парсим данные из источника")

    let cachedDb = try modelContext.fetch(FetchDescriptor<DbAnime>()).map { $0.id }

    // Читаем файл построчно
    while let line = reader.nextLine() {
      guard !line.isEmpty else {
        fatalError("Empty line")
      }

      do {
        guard let data = line.data(using: .utf8) else { continue }
        let jsonAnime = try decoder.decode(JsonAnime.self, from: data)
        if cachedDb.contains(jsonAnime.id) {
          continue
        }
        let model = try createAnimeModel(from: jsonAnime)
        models.append(model)
      }
      catch {
        print("Error importing anime: \(error)")
      }
    }

    print("Parsed \(models.count) in \(Date().timeIntervalSince(startParseTime)) seconds")

    self.progressContinuation?.yield("Сохраняем данные в нашей базе")
    let startSaveTime = Date()
    models.forEach {
      modelContext.insert($0)
    }

    try modelContext.save()

    print("Saved \(models.count) in \(Date().timeIntervalSince(startSaveTime)) seconds")

    self.progressContinuation?.yield("Заканчиваем... обработали \(models.count) аниме")
    try modelContext.save()

    print(
      "Imported \(models.count) models in \(Date().timeIntervalSince(startTime) / 60) minutes"
    )
  }

  private func createAnimeModel(from rawAnime: JsonAnime) throws -> DbAnime {
    // Создание Description
    let descriptions = rawAnime.descriptions.map { rawDesc in
      DbDescription(
        source: rawDesc.source,
        updatedDateTime: rawDesc.updatedDateTime,
        value: rawDesc.value
      )
    }

    // Проверка и создание жанров
    let genres = rawAnime.genres.map { rawGenre in
      if let existingGenre = genresMap[rawGenre.id] {
        return existingGenre
      }
      let genre = DbGenre(id: rawGenre.id, title: rawGenre.title, url: rawGenre.url)
      self.genresMap[rawGenre.id] = genre
      return genre
    }

    // Проверка и cоздание студий
    let studios = rawAnime.studios.map { rawStudio in
      if let existingStudio = studioMap[rawStudio.id] {
        return existingStudio
      }

      let studio = DbStudio(
        filteredName: rawStudio.filteredName,
        id: rawStudio.id,
        image: rawStudio.image,
        name: rawStudio.name,
        real: rawStudio.real
      )
      self.studioMap[rawStudio.id] = studio
      return studio
    }

    // Создание Poster
    let poster = self.createPosterModel(from: rawAnime.poster)

    // Создание Trailers
    let trailers = rawAnime.trailers.map { rawTrailer in
      DbVideo(
        hosting: rawTrailer.hosting,
        id: rawTrailer.id,
        imageUrl: rawTrailer.imageUrl,
        kind: rawTrailer.kind,
        name: rawTrailer.name,
        playerUrl: rawTrailer.playerUrl,
        url: rawTrailer.url
      )
    }

    // Создание Roles
    let roles = rawAnime.roles.map { rawRole in
      DbRole(
        character: self.createCharacterModel(from: rawRole.character),
        roleNames: rawRole.roleNames.map { roleName in
          DbRoleName(
            name: roleName.name,
            russian: roleName.russian
          )
        }
      )
    }

    // Создание Screenshots
    let screenshots = rawAnime.screenshots.map { rawScreenshot in
      DbImage(
        original: rawScreenshot.original,
        preview: rawScreenshot.preview,
        x48: nil,
        x96: nil
      )
    }

    // Создание Episodes
    let episodes = rawAnime.episodes.map { rawEpisode in
      var titles: DbEpisodeTitles?
      if let rawTitles = rawEpisode.titles {
        titles = DbEpisodeTitles(
          en: rawTitles["en"] ?? "",
          ja: rawTitles["ja"] ?? "",
          romaji: rawTitles["romaji"] ?? ""
        )
      }
      return DbEpisode(
        number: rawEpisode.number,
        type: rawEpisode.type,
        title: rawEpisode.title,
        titles: titles,
        firstUploadedDateTime: rawEpisode.firstUploadedDateTime,
        id: rawEpisode.id,
        isActive: rawEpisode.isActive,
        isFirstUploaded: rawEpisode.isFirstUploaded,
        seriesId: rawEpisode.seriesId,
        airDate: rawEpisode.airDate,
        rating: rawEpisode.rating
      )
    }

    let similar = rawAnime.similar.map { rawSimilar in
      DbSimilar(
        myAnimeListId: rawSimilar.myAnimeListId,
        score: Float(rawSimilar.score) ?? 0.0,
        titles: .init(ru: rawSimilar.titles.ru, en: rawSimilar.titles.en),
        image: .init(
          original: rawSimilar.image.original,
          preview: rawSimilar.image.preview,
          x48: rawSimilar.image.x48,
          x96: rawSimilar.image.x96
        )
      )
    }
    // Создание основной модели Anime
    let anime = DbAnime(
      id: rawAnime.id,
      myAnimeListId: rawAnime.myAnimeListId,
      score: rawAnime.score,
      titles: .init(
        ru: rawAnime.titles["ru"] ?? "",
        en: rawAnime.titles["en"] ?? "",
        ja: rawAnime.titles["ja"] ?? "",
        romaji: rawAnime.titles["romaji"] ?? ""
      ),
      type: rawAnime.type,
      typeTitle: rawAnime.typeTitle,
      year: rawAnime.year,
      season: rawAnime.season,
      numberOfEpisodes: rawAnime.numberOfEpisodes,
      duration: rawAnime.duration,
      airedOn: rawAnime.airedOn,
      isAiring: rawAnime.isAiring,
      releasedOn: rawAnime.releasedOn,
      descriptions: descriptions,
      studios: studios,
      poster: poster,
      trailers: trailers,
      genres: genres,
      roles: roles,
      screenshots: screenshots,
      episodes: episodes,
      similar: similar
    )

    return anime
  }

  private func createPosterModel(from rawPoster: JsonPoster) -> DbPoster {
    let anime365Image = DbImage(
      original: rawPoster.anime365.original,
      preview: rawPoster.anime365.preview,
      x48: rawPoster.anime365.x48,
      x96: rawPoster.anime365.x96
    )

    let shikimoriImage = DbImage(
      original: rawPoster.shikimori.original,
      preview: rawPoster.shikimori.preview,
      x48: rawPoster.shikimori.x48,
      x96: rawPoster.shikimori.x96
    )

    return DbPoster(anime365: anime365Image, shikimori: shikimoriImage)
  }

  private func createCharacterModel(from rawCharacter: JsonCharacter) -> DbCharacter {
    let characterImage = DbImage(
      original: rawCharacter.image.original,
      preview: rawCharacter.image.preview,
      x48: rawCharacter.image.x48,
      x96: rawCharacter.image.x96
    )

    return DbCharacter(
      id: rawCharacter.id,
      image: characterImage,
      name: rawCharacter.name,
      russian: rawCharacter.russian
    )
  }
}

// Define models conforming to Codable
struct JsonDescription: Codable {
  let source: String
  let updatedDateTime: String
  let value: String
}

struct JsonGenre: Codable {
  let id: Int
  let title: String
  let url: String
}

struct JsonVideo: Codable {
  let hosting: String
  let id: Int64
  let imageUrl: String
  let kind: String
  let name: String
  let playerUrl: String
  let url: String
}

struct JsonStudio: Codable {
  let filteredName: String
  let id: Int
  let image: String
  let name: String
  let real: Bool
}

struct JsonImage: Codable {
  let original: String
  let preview: String
  let x48: String?
  let x96: String?
}

struct JsonPoster: Codable {
  let anime365: JsonImage
  let shikimori: JsonImage
}

struct JsonRoleName: Codable {
  let name: String
  let russian: String
}

struct JsonRole: Codable {
  let character: JsonCharacter
  let roleNames: [JsonRoleName]
}

struct JsonCharacter: Codable {
  let id: Int
  let image: JsonImage
  let name: String
  let russian: String
}

struct JsonEpisode: Codable {
  let number: Int
  let type: String
  let firstUploadedDateTime: String
  let isFirstUploaded: Int
  let id: Int
  let isActive: Int
  let seriesId: Int
  let airDate: String
  let title: String
  let titles: [String: String]?
  let rating: String
}

struct JsonSimilarTitles: Codable {
  let ru: String
  let en: String
}

struct JsonSimilar: Codable {
  let image: JsonImage
  let myAnimeListId: Int
  let score: String
  let titles: JsonSimilarTitles
}

struct JsonAnime: Codable {
  let id: Int
  let myAnimeListId: Int
  let score: String
  let titles: [String: String]
  let type: String
  let typeTitle: String
  let year: Int
  let season: String
  let numberOfEpisodes: Int
  let duration: Int
  let airedOn: String
  let isAiring: Int
  let releasedOn: String
  let descriptions: [JsonDescription]
  let studios: [JsonStudio]
  let poster: JsonPoster
  let trailers: [JsonVideo]
  let genres: [JsonGenre]
  let roles: [JsonRole]
  let screenshots: [JsonImage]
  let episodes: [JsonEpisode]
  let similar: [JsonSimilar]
}
