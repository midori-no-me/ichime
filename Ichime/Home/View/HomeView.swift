import SwiftUI

struct HomeView: View {
  enum FocusTarget: Hashable {
    case profileButton
  }

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  @Environment(\.currentUserStore) private var currentUserStore

  @FocusState private var focused: FocusTarget?

  let size: CGFloat = 64

  var focusProfileTrigger: Int

  var body: some View {
    GeometryReader { proxy in
      ScrollView(.vertical) {
        VStack(alignment: .center, spacing: 0) {
          HStack {
            Button {
            } label: {
              if let user = currentUserStore.user {
                ZStack {
                  Circle()
                    .fill(ImagePlaceholder.color)

                  AsyncImage(
                    url: user.avatar,
                    transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
                  ) { phase in
                    switch phase {
                    case .empty:
                      Color.clear

                    case let .success(image):
                      image
                        .resizable()
                        .scaledToFill()

                    case .failure:
                      Image(systemName: "person.circle")
                        .font(.title)

                    @unknown default:
                      Color.clear
                    }
                  }
                }
                .frame(width: self.size, height: self.size)  // ✅ FIXED SIZE
                .clipShape(Circle())  // ✅ FORCE CIRCLE MASK
                .contentShape(Circle())
              }
              else {
                Label("Профиль", systemImage: "person.circle")
                  .frame(width: self.size, height: self.size)
              }
            }
            .buttonBorderShape(.circle)
            .focused(self.$focused, equals: .profileButton)
          }
          .frame(height: proxy.safeAreaInsets.top)
          .frame(maxWidth: .infinity, alignment: .leading)
          .border(Color.red)

          LazyVStack(alignment: .leading, spacing: 64) {
            if Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
              RecentlyUploadedEpisodesSection()
            }
            else {
              CurrentlyWatchingSection()
            }

            MomentsSection.withRandomSorting()

            if Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
              RandomSection()

              YearSection(year: Self.currentYear())
              YearSection(year: Self.shiftedYear(shift: -1))
            }
            else {
              OngoingsSection()

              NextSeasonSection()
            }

            TopScoredSection()

            MostPopularSection()

            MostAnticipatedSection()
          }
        }
      }
      .edgesIgnoringSafeArea(.top)
    }
    .onChange(of: self.focusProfileTrigger) { _, _ in
      self.focused = .profileButton
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
