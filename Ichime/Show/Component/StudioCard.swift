import SwiftUI

struct StudioCard: View {
  let id: Int
  let title: String
  let cover: URL?

  let showService: ShowService

  init(
    id: Int,
    title: String,
    cover: URL?,
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.id = id
    self.title = title
    self.cover = cover
    self.showService = showService
  }

  var body: some View {
    NavigationLink(
      destination: FilteredShowsView(
        title: "Студия \(self.title)",
        displaySeason: true,
        fetchShows: self.getShowsByStudio(self.id)
      )
    ) {
      VStack(alignment: .leading, spacing: 16) {
        AsyncImage(
          url: self.cover,
          transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
        ) { phase in
          switch phase {
          case .empty:
            Image(systemName: "photo")
              .font(.title)
              .foregroundStyle(.secondary)

          case let .success(image):
            image
              .resizable()
              .scaledToFit()

          case .failure:
            Image(systemName: "photo.badge.exclamationmark")
              .font(.title)
              .foregroundStyle(.secondary)

          @unknown default:
            Color.clear
          }
        }
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity
        )

        Text(self.title)
          .lineLimit(1)
          .truncationMode(.tail)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .padding(24)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .leading
      )
    }
    .buttonStyle(.card)
  }

  private func getShowsByStudio(_ studioId: Int) -> (_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
      try await self.showService.getStudio(
        offset: offset,
        limit: limit,
        studioId: studioId
      )
    }

    return fetchFunction
  }
}
