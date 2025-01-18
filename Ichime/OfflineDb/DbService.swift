import Foundation
import SwiftData

/**
`DbService` is a class that provides methods to interact with the database.
```swift
let dbService = DbService(modelContainer: container)

// Получить аниме по ID
let anime = try await dbService.getAnime(id: 1)

// Получить список аниме с фильтрами
let animeList = try await dbService.getAnimeList(
    type: "TV",
    year: 2023,
    season: "WINTER",
    genres: [1, 2],
    sortBy: DbService.AnimeSort.score.descriptor,
    limit: 20
)
```
*/
@ModelActor
actor DbService {
  // MARK: - Helper Extensions

  enum AnimeSort {
    case title
    case score
    case year
    case episodes

    var descriptor: SortDescriptor<DbAnime> {
      switch self {
      case .title:
        return SortDescriptor(\DbAnime.titles.ru)
      case .score:
        return SortDescriptor(\DbAnime.score, order: .reverse)
      case .year:
        return SortDescriptor(\DbAnime.year, order: .reverse)
      case .episodes:
        return SortDescriptor(\DbAnime.numberOfEpisodes, order: .reverse)
      }
    }
  }

  // MARK: - Anime Queries

  func getAnime(id: Int) throws -> DbAnime? {
    let descriptor = FetchDescriptor<DbAnime>(
      predicate: #Predicate<DbAnime> { anime in
        anime.id == id
      }
    )
    return try modelContext.fetch(descriptor).first
  }

  func getAnime(malId: Int) throws -> DbAnime? {
    let descriptor = FetchDescriptor<DbAnime>(
      predicate: #Predicate<DbAnime> { anime in
        anime.myAnimeListId == malId
      }
    )
    return try modelContext.fetch(descriptor).first
  }

  func getAnimeList(
    descriptor: FetchDescriptor<DbAnime>
  ) throws -> [DbAnime] {
    try modelContext.fetch(descriptor)
  }

  // MARK: - Genre Queries

  func getGenre(id: Int) throws -> DbGenre? {
    let descriptor = FetchDescriptor<DbGenre>(
      predicate: #Predicate<DbGenre> { genre in
        genre.id == id
      }
    )
    return try modelContext.fetch(descriptor).first
  }

  func getAllGenres(sortBy: SortDescriptor<DbGenre>? = nil) throws -> [DbGenre] {
    let descriptor = FetchDescriptor<DbGenre>(
      sortBy: sortBy.map { [$0] } ?? [SortDescriptor(\.title)]
    )
    return try modelContext.fetch(descriptor)
  }

  // MARK: - Studio Queries

  func getStudio(id: Int) throws -> DbStudio? {
    let descriptor = FetchDescriptor<DbStudio>(
      predicate: #Predicate<DbStudio> { studio in
        studio.id == id
      }
    )
    return try modelContext.fetch(descriptor).first
  }

  func getAllStudios(sortBy: SortDescriptor<DbStudio>? = nil) throws -> [DbStudio] {
    let descriptor = FetchDescriptor<DbStudio>(
      sortBy: sortBy.map { [$0] } ?? [SortDescriptor(\.name)]
    )
    return try modelContext.fetch(descriptor)
  }
}
