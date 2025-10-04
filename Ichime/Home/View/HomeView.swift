import SwiftUI

struct HomeView: View {
  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: 64) {
        OngoingsSection()

        MomentsSection.withRandomSorting()

        NextSeasonSection()

        TopScoredSection()

        MostPopularSection()
      }
    }
  }
}
