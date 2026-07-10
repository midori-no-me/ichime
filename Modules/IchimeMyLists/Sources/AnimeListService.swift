import IchimeAnime365
import IchimeShow
import OrderedCollections

public struct AnimeListService: Sendable {
  private let anime365KitFactory: Anime365KitFactory

  public init(
    anime365KitFactory: Anime365KitFactory,
  ) {
    self.anime365KitFactory = anime365KitFactory
  }

  public func getAnimeList(userID: Int, category: AnimeListCategory) async throws -> (
    count: Int, groups: [AnimeListEntriesGroup]
  ) {
    let anime365AnimeListEntries = try await self.anime365KitFactory.createWebClient()
      .getAnimeList(userID: userID, category: category.anime365KitType)

    let entries: [AnimeListEntry] = anime365AnimeListEntries.map { .init(fromAnime365KitAnimeListEntry: $0) }

    var letterToEntriesDictionary: [String: OrderedSet<AnimeListEntry>] = [:]

    for entry in entries {
      let character = entry.name.getFullName().first!

      if !character.isLetter {
        letterToEntriesDictionary["#", default: .init()].append(entry)
      }
      else {
        letterToEntriesDictionary[String(character).uppercased(), default: .init()].append(entry)
      }
    }

    var groups: [AnimeListEntriesGroup] = []

    for (letter, entries) in letterToEntriesDictionary {
      groups.append(
        .init(
          letter: letter,
          entries: entries
        )
      )
    }

    groups.sort(by: { $0.letter.compare($1.letter).rawValue < 0 })

    return (count: entries.count, groups: groups)
  }

  public func getAnimeListEditableEntry(showID: Int) async throws -> AnimeListEditableEntry {
    let animeListEditableEntry = try await self.anime365KitFactory.createWebClient()
      .getAnimeListEditableEntry(seriesID: showID)

    return .init(fromAnime365KitAnimeListEditableEntry: animeListEditableEntry)
  }

  public func editAnimeListEntry(
    showID: Int,
    status: AnimeListCategory,
    score: AnimeListScore,
    episodesWatched: Int
  ) async throws -> Void {
    try await self.anime365KitFactory.createWebClient()
      .editAnimeListEntry(
        seriesID: showID,
        score: score.rawValue,
        episodes: episodesWatched,
        status: status.anime365KitType.numericID,
        comment: ""
      )
  }

  public func deleteAnimeListEntry(
    showID: Int
  ) async throws -> Void {
    try await self.anime365KitFactory.createWebClient()
      .editAnimeListEntry(
        seriesID: showID,
        score: 0,
        episodes: 0,
        status: 99,
        comment: ""
      )
  }
}
