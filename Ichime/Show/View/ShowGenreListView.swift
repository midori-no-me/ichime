import SwiftUI

struct ShowGenreListView: View {
  private let genres: [ShowFull.Genre]
  private let client: Anime365Client

  init(
    genres: [ShowFull.Genre],
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.genres = genres
    self.client = client
  }

  var body: some View {
    List {
      Section {
        ForEach(self.genres) { genre in
          NavigationLink(
            destination: FilteredShowsView(
              viewModel: .init(fetchShows: self.getShowsByGenre(genreId: genre.id)),
              title: genre.title,
              description: nil,
              displaySeason: true
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

  private func getShowsByGenre(genreId: Int) -> (_ offset: Int, _ limit: Int) async throws -> [Show] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [Show] {
      try await self.client.getByGenre(
        offset: offset,
        limit: limit,
        genreIds: [genreId]
      )
    }

    return fetchFunction
  }
}

#Preview {
  NavigationStack {
    ShowGenreListView(
      genres: [
        ShowFull.Genre(id: 22, title: "Романтика"),
        ShowFull.Genre(id: 23, title: "Школа"),
      ]
    )
  }
}
