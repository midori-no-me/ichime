import Foundation
import OrderedCollections
import ShikimoriApiClient

public struct ShowSearchService: Sendable {
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient

  public init(
    shikimoriApiClient: ShikimoriApiClient.ApiClient
  ) {
    self.shikimoriApiClient = shikimoriApiClient
  }

  public func getAllGenresAndStudios() async -> (genres: OrderedSet<Genre>, studios: OrderedSet<Studio>) {
    let allGenres = (try? await self.getAllGenres()) ?? []
    let allStudios = (try? await self.getAllStudios()) ?? []

    return (
      genres: .init(allGenres),
      studios: .init(allStudios.filter { $0.image != nil })
    )
  }

  public func getAllGenres() async throws -> [Genre] {
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

  public func getAllStudios() async throws -> [Studio] {
    let apiResponse = try await shikimoriApiClient.listStudios()

    return
      apiResponse
      .map { .init(fromShikimoriStudio: $0, shikimoriBaseURL: self.shikimoriApiClient.baseURL) }
      .sorted(by: { $0.name < $1.name })
  }
}
