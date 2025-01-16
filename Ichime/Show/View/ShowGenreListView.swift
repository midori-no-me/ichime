import SwiftUI

struct ShowGenreListView: View {
  private let showTitle: Show.Title
  private let genres: [Show.Genre]
  private let client: Anime365Client

  init(
    showTitle: Show.Title,
    genres: [Show.Genre],
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.showTitle = showTitle
    self.genres = genres
    self.client = client
  }

  var body: some View {
    List {
      Section {
        ForEach(genres) { genre in
          NavigationLink(
            destination: FilteredShowsView(
              viewModel: .init(fetchShows: getShowsByGenre(genreId: genre.id)),
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
      try await client.getByGenre(
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
      showTitle: Show.Title(
        full: "Full Title",
        translated: Show.Title.TranslatedTitles(
          russian: "Russian",
          english: "English",
          japanese: "Japanese",
          japaneseRomaji: "Japanese Romaji"
        )
      ),
      genres: [
        Show.Genre(id: 22, title: "Романтика"),
        Show.Genre(id: 23, title: "Школа"),
      ]
    )
  }
}
