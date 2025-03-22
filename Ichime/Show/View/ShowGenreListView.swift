import SwiftUI

struct ShowGenreListView: View {
  private let genres: [ShowFull.Genre]
  private let showService: ShowService

  init(
    genres: [ShowFull.Genre],
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.genres = genres
    self.showService = showService
  }

  var body: some View {
    List {
      Section {
        ForEach(self.genres) { genre in
          NavigationLink(
            destination: FilteredShowsView(
              title: genre.title,
              displaySeason: true,
              fetchShows: self.getShowsByGenre(genreId: genre.id)
            )
          ) {
            Text(genre.title)
          }
        }
      } header: {
        Text("Жанры")
      }
    }
    .listStyle(.grouped)
  }

  private func getShowsByGenre(genreId: Int) -> (_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
      try await self.showService.getByGenre(
        offset: offset,
        limit: limit,
        genreIds: [genreId]
      )
    }

    return fetchFunction
  }
}
