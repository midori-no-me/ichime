import Anime365Kit
import ShikimoriApiClient

struct Genre: Identifiable, Hashable {
  let id: Int
  let title: String

  init?(
    fromShikimoriGenre: ShikimoriApiClient.Genre
  ) {
    if fromShikimoriGenre.entry_type != .anime {
      return nil
    }

    self.id = fromShikimoriGenre.id
    self.title = fromShikimoriGenre.russian
  }

  init(
    fromAnime365Genre: Anime365Kit.SeriesFull.Genre
  ) {
    self.id = fromAnime365Genre.id
    self.title = fromAnime365Genre.title
  }
}
