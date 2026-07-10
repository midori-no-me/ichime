import Anime365Kit
import ShikimoriApiClient

public struct Genre: Identifiable, Hashable {
  // MARK: Properties

  public let id: Int
  public let title: String

  // MARK: Lifecycle

  public init?(
    fromShikimoriGenre: ShikimoriApiClient.Genre
  ) {
    if fromShikimoriGenre.entry_type != .anime {
      return nil
    }

    self.id = fromShikimoriGenre.id
    self.title = fromShikimoriGenre.russian
  }

  public init(
    fromAnime365Genre: Anime365Kit.SeriesFull.Genre
  ) {
    self.id = fromAnime365Genre.id
    self.title = fromAnime365Genre.title
  }
}
