import SwiftUI

struct HomeView: View {
  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: 64) {
        if Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
          RecentlyUploadedEpisodesSection()
        }
        else {
          OngoingsSection()
        }

        MomentsSection.withRandomSorting()

        if Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
          RandomSection()

          YearSection(year: Self.currentYear())
          YearSection(year: Self.shiftedYear(shift: -1))
        }
        else {
          NextSeasonSection()
        }

        TopScoredSection()

        MostPopularSection()

        MostAnticipatedSection()
      }
    }
  }

  private static func currentYear() -> Int {
    let now = Date.now
    let calendar = Calendar.current

    return calendar.component(.year, from: now)
  }

  private static func shiftedYear(shift: Int) -> Int {
    let now = Date.now
    let calendar = Calendar.current
    let nextYearDate = calendar.date(byAdding: .year, value: shift, to: now)!

    return calendar.component(.year, from: nextYearDate)
  }
}
