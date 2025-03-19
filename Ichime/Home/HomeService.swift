import Foundation

struct HomeService {
  private let showService: ShowService
  private let momentService: MomentService

  init(
    showService: ShowService,
    momentService: MomentService
  ) {
    self.showService = showService
    self.momentService = momentService
  }

  func preloadHomeSections() async -> (
    ongoings: [ShowPreview],
    topScored: [ShowPreview],
    nextSeason: [ShowPreviewShikimori],
    mostPopular: [ShowPreviewShikimori],
    moments: [Moment]
  ) {
    async let momentsFuture = self.momentService.getMoments(page: 1)

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

    async let mostPopularFuture = self.showService.getMostPopular(
      page: 0,
      limit: 10
    )

    return (
      ongoings: (try? await ongoingsFuture) ?? [],
      topScored: (try? await topScoredFuture) ?? [],
      nextSeason: (try? await nextSeasonFuture) ?? [],
      mostPopular: (try? await mostPopularFuture) ?? [],
      moments: (try? await momentsFuture) ?? []
    )
  }
}
