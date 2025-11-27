import SwiftUI

struct GenreCard: View {
  let id: Int
  let title: String

  private let showService: ShowService

  init(
    id: Int,
    title: String,
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.id = id
    self.title = title
    self.showService = showService
  }

  var body: some View {
    NavigationLink(
      destination: FilteredShowsView(
        title: self.title,
        displaySeason: true,
        fetchShows: self.getShowsByGenre(self.id)
      )
    ) {
      Text(self.title)
        .padding(16)
    }
#if os(tvOS)
    .buttonStyle(.card)
    #endif
  }

  private func getShowsByGenre(_ genreId: Int) -> (_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
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
