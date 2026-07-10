import IchimeShow
import SwiftUI

struct GenreCard: View {
  // MARK: Properties

  let id: Int
  let title: String

  private let showService: ShowService

  // MARK: Lifecycle

  init(
    id: Int,
    title: String,
    showService: ShowService = AppDependencies.live.showService
  ) {
    self.id = id
    self.title = title
    self.showService = showService
  }

  // MARK: Content Properties

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
    .buttonStyle(.card)
  }

  // MARK: Functions

  private func getShowsByGenre(_ genreID: Int) -> (_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
      try await self.showService.getByGenre(
        offset: offset,
        limit: limit,
        genreIDs: [genreID]
      )
    }

    return fetchFunction
  }
}
