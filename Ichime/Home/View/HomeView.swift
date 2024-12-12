import SwiftData
import SwiftUI

private protocol ShowsSectionLoader: Identifiable {
  var id: String { get }

  func getTitle() -> String
  func getSubtitle() -> String?
  func getCards(_ offset: Int, _ limit: Int) async -> [Show]
  func displaySeason() -> Bool
}

private class OngoingsSectionLoader: ShowsSectionLoader {
  private let client: Anime365Client

  init(
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.client = client
  }

  var id: String = "ongoing"

  func getTitle() -> String {
    "Онгоинги"
  }

  func getSubtitle() -> String? {
    "Регулярно выходят новые серии"
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await client.getOngoings(offset: offset, limit: limit)
    }
    catch {
      return []
    }
  }

  func displaySeason() -> Bool {
    true
  }
}

private class TopSectionLoader: ShowsSectionLoader {
  private let client: Anime365Client

  init(
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.client = client
  }

  var id: String = "top"

  func getTitle() -> String {
    "Топ по оценке"
  }

  func getSubtitle() -> String? {
    "По версии MyAnimeList"
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await client.getTop(offset: offset, limit: limit)
    }
    catch {
      return []
    }
  }

  func displaySeason() -> Bool {
    true
  }
}

private class SeasonalSectionLoader: ShowsSectionLoader {
  private let client: Anime365Client
  private let airingSeason: AiringSeason
  private let description: String?

  init(
    airingSeason: AiringSeason,
    description: String?,
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.client = client
    self.airingSeason = airingSeason
    self.description = description
    id = "\(airingSeason.year)_\(airingSeason.calendarSeason)"
  }

  var id: String

  func getTitle() -> String {
    "\(airingSeason.calendarSeason.getLocalizedTranslation()) \(airingSeason.year)"
  }

  func getSubtitle() -> String? {
    description
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await client.getSeason(
        offset: offset,
        limit: limit,
        airingSeason: airingSeason
      )
    }
    catch {
      return []
    }
  }

  func displaySeason() -> Bool {
    false
  }
}

struct HomeView: View {
  @State private var sectionLoaders: [any ShowsSectionLoader] = []
  private let SPACING_BETWEEN_SECTIONS: CGFloat = 70

  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
        ForEach(sectionLoaders, id: \.id) { sectionLoader in
          ShowsSection(
            sectionLoader: sectionLoader,
            onLoaded: {
              sectionLoaders.append(getNextSectionLoader())
            }
          )
        }
      }
    }
    .onAppear {
      sectionLoaders.append(getNextSectionLoader())
    }
  }

  private func getNextSectionLoader() -> any ShowsSectionLoader {
    let showSeasonService = ShowSeasonService()

    let predefinedLoaders: [any ShowsSectionLoader] = [
      OngoingsSectionLoader(),
      TopSectionLoader(),
      SeasonalSectionLoader(
        airingSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.NEXT_SEASON),
        description: "Следующий сезон"
      ),
      SeasonalSectionLoader(
        airingSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.CURRENT_SEASON),
        description: "Текущий сезон"
      ),
      SeasonalSectionLoader(
        airingSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.PREVIOUS_SEASON),
        description: "Прошлый сезон"
      ),
    ]

    if sectionLoaders.count < predefinedLoaders.count {
      return predefinedLoaders[sectionLoaders.count]
    }

    let lastPredefinedSeasonalSectionShift = ShowSeasonService.PREVIOUS_SEASON

    return SeasonalSectionLoader(
      airingSeason:
        showSeasonService
        .getRelativeSeason(
          shift: predefinedLoaders.count - sectionLoaders.count + lastPredefinedSeasonalSectionShift
            - 1
        ),
      description: nil
    )
  }
}

private struct ShowsSection: View {
  public let sectionLoader: any ShowsSectionLoader
  public let onLoaded: () -> Void

  @State var isLoading: Bool = true
  @State var shows: [Show] = []
  private let SPACING_BETWEEN_TITLE_CARD_CARDS: CGFloat = 50

  var body: some View {
    if isLoading {
      Color.clear.onAppear {
        Task {
          self.shows = await sectionLoader.getCards(0, 10)
          self.isLoading = false
          self.onLoaded()
        }
      }
    }
    else {
      VStack(alignment: .leading, spacing: SPACING_BETWEEN_TITLE_CARD_CARDS) {
        SectionHeader(
          title: sectionLoader.getTitle(),
          subtitle: sectionLoader.getSubtitle()
        ) {
          FilteredShowsView(
            viewModel: FilteredShowsViewModel(
              preloadedShows: shows,
              fetchShows: sectionLoader.getCards
            ),
            title: sectionLoader.getTitle(),
            description: sectionLoader.getSubtitle(),
            displaySeason: sectionLoader.displaySeason()
          )
        }

        ScrollView(.horizontal) {
          LazyHStack(spacing: RawShowCard.RECOMMENDED_SPACING) {
            ForEach(self.shows) { show in
              ShowCard(show: show, displaySeason: sectionLoader.displaySeason())
                .frame(width: RawShowCard.RECOMMENDED_MINIMUM_WIDTH)
            }
          }
        }
        .scrollClipDisabled()
      }
    }
  }
}

#Preview {
  NavigationStack {
    HomeView()
  }
}
