import Foundation

struct Hentai365HomeService {
  private let showService: ShowService

  init(
    showService: ShowService
  ) {
    self.showService = showService
  }

  func preloadHomeSections() async -> (
    topScored: [ShowPreview],
    years: [(shows: [ShowPreview], year: Int)]
  ) {
    async let topScoredFuture = self.showService.getTopScored(
      offset: 0,
      limit: 10
    )

    let currentYear = Calendar.current.component(.year, from: Date.now)

    async let currentYearFuture = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear
    )

    async let currentYearMinus1Future = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear - 1
    )

    async let currentYearMinus2Future = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear - 2
    )

    async let currentYearMinus3Future = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear - 3
    )

    async let currentYearMinus4Future = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear - 4
    )

    async let currentYearMinus5Future = self.showService.getYear(
      offset: 0,
      limit: 10,
      year: currentYear - 5
    )

    return (
      topScored: (try? await topScoredFuture) ?? [],
      years: [
        (shows: (try? await currentYearFuture) ?? [], currentYear),
        (shows: (try? await currentYearMinus1Future) ?? [], currentYear - 1),
        (shows: (try? await currentYearMinus2Future) ?? [], currentYear - 2),
        (shows: (try? await currentYearMinus3Future) ?? [], currentYear - 3),
        (shows: (try? await currentYearMinus4Future) ?? [], currentYear - 4),
        (shows: (try? await currentYearMinus5Future) ?? [], currentYear - 5),
      ]
    )
  }
}
