import Foundation
import OrderedCollections

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
    ongoings: OrderedSet<ShowPreview>,
    topScored: OrderedSet<ShowPreview>,
    nextSeason: OrderedSet<ShowPreviewShikimori>,
    mostPopular: OrderedSet<ShowPreviewShikimori>,
    random: OrderedSet<ShowPreviewShikimori>,
    moments: (OrderedSet<Moment>, MomentSorting)
  ) {
    let momentSorting: MomentSorting =
      Int.random(in: 1...100) <= 10
      ? .popular
      : .newest

    async let momentsFuture = self.momentService.getMoments(page: 1, sorting: momentSorting)

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

    //        async let randomFuture = self.showService.getRandom(
    //          page: 0,
    //          limit: 10
    //        )

    return (
      ongoings: (try? await ongoingsFuture) ?? [],
      topScored: (try? await topScoredFuture) ?? [],
      nextSeason: (try? await nextSeasonFuture) ?? [],
      mostPopular: (try? await mostPopularFuture) ?? [],
      //      random: (try? await randomFuture) ?? [],
      random: [],
      moments: ((try? await momentsFuture) ?? [], momentSorting)
    )
  }
}
