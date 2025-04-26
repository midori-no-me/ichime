import Foundation
import OrderedCollections
import ShikimoriApiClient

struct ShowSearchService {
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient

  init(
    shikimoriApiClient: ShikimoriApiClient.ApiClient
  ) {
    self.shikimoriApiClient = shikimoriApiClient
  }

  func getAllGenresAndStudios() async -> (genres: OrderedSet<Genre>, studios: OrderedSet<Studio>) {
    async let allGenresFuture = self.getAllGenres()
    async let allStudiosFuture = self.getAllStudios()

    return (
      genres: .init((try? await allGenresFuture) ?? []),
      studios: .init(((try? await allStudiosFuture) ?? []).filter { $0.image != nil })
    )
  }

  func getAllGenres() async throws -> [Genre] {
    let apiResponse = try await shikimoriApiClient.listGenres()

    var items: [Genre] = []

    for shikimoriGenre in apiResponse {
      let genre = Genre(fromShikimoriGenre: shikimoriGenre)

      guard let genre else {
        continue
      }

      items.append(genre)
    }

    items = items.sorted(by: { $0.title < $1.title })

    return items
  }

  func getAllStudios() async throws -> [Studio] {
    let apiResponse = try await shikimoriApiClient.listStudios()

    return
      apiResponse
      .map { .init(fromShikimoriStudio: $0, shikimoriBaseUrl: self.shikimoriApiClient.baseUrl) }
      .sorted(by: { $0.name < $1.name })
  }
}
