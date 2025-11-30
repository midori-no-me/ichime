import SwiftUI

struct HomeView: View {
  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: 64) {
        OngoingsSection()

        MomentsSection.withRandomSorting()

        if Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
          RandomSection()
        }

        NextSeasonSection()

        TopScoredSection()

        MostPopularSection()
      }
    }
    .id(self.anime365BaseURL)
  }
}
