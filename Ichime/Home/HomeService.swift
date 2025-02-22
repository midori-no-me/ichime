import Foundation

struct HomeService {
  private let showService: ShowService

  init(
    showService: ShowService
  ) {
    self.showService = showService
  }

  func preloadHomeSections() async -> (
    ongoings: [ShowPreview],
    topScored: [ShowPreview],
    nextSeason: [ShowPreviewShikimori]
  ) {
    async let ongoingsFuture = self.showService.getOngoings(
      offset: 0,
      limit: 10
    )

    async let topScoredFuture = self.showService.getTopScored(
      offset: 0,
      limit: 10
    )

    async let nextSeasonFuture = self.showService.getNextSeason(
      page: 0,
      limit: 10
    )

    return (
      ongoings: (try? await ongoingsFuture) ?? [],
      topScored: (try? await topScoredFuture) ?? [],
      nextSeason: (try? await nextSeasonFuture) ?? []
    )
  }
}
