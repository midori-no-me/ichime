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
  var id: String = "ongoing"

  private let client: Anime365Client

  init(
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.client = client
  }

  func getTitle() -> String {
    "Онгоинги"
  }

  func getSubtitle() -> String? {
    "Регулярно выходят новые серии"
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await self.client.getOngoings(offset: offset, limit: limit)
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
  var id: String = "top"

  private let client: Anime365Client

  init(
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.client = client
  }

  func getTitle() -> String {
    "Топ по оценке"
  }

  func getSubtitle() -> String? {
    "По версии MyAnimeList"
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await self.client.getTop(offset: offset, limit: limit)
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
  var id: String

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
    self.id = "\(airingSeason.year)_\(airingSeason.calendarSeason)"
  }

  func getTitle() -> String {
    "\(self.airingSeason.calendarSeason.getLocalizedTranslation()) \(self.airingSeason.year)"
  }

  func getSubtitle() -> String? {
    self.description
  }

  func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
    do {
      return try await self.client.getSeason(
        offset: offset,
        limit: limit,
        airingSeason: self.airingSeason
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
      LazyVStack(alignment: .leading, spacing: self.SPACING_BETWEEN_SECTIONS) {
        ForEach(self.sectionLoaders, id: \.id) { sectionLoader in
          ShowsSection(
            sectionLoader: sectionLoader,
            onLoaded: {
              self.sectionLoaders.append(self.getNextSectionLoader())
            }
          )
        }
      }
    }
    .onAppear {
      self.sectionLoaders.append(self.getNextSectionLoader())
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

    if self.sectionLoaders.count < predefinedLoaders.count {
      return predefinedLoaders[self.sectionLoaders.count]
    }

    let lastPredefinedSeasonalSectionShift = ShowSeasonService.PREVIOUS_SEASON

    return SeasonalSectionLoader(
      airingSeason:
        showSeasonService
        .getRelativeSeason(
          shift: predefinedLoaders.count - self.sectionLoaders.count + lastPredefinedSeasonalSectionShift
            - 1
        ),
      description: nil
    )
  }
}

private struct ShowsSection: View {
  let sectionLoader: any ShowsSectionLoader
  let onLoaded: () -> Void

  @State private var isLoading: Bool = true
  @State private var shows: [Show] = []
  private let SPACING_BETWEEN_TITLE_CARD_CARDS: CGFloat = 50

  var body: some View {
    if self.isLoading {
      Color.clear.onAppear {
        Task {
          self.shows = await self.sectionLoader.getCards(0, 10)
          self.isLoading = false
          self.onLoaded()
        }
      }
    }
    else {
      VStack(alignment: .leading, spacing: self.SPACING_BETWEEN_TITLE_CARD_CARDS) {
        SectionHeader(
          title: self.sectionLoader.getTitle(),
          subtitle: self.sectionLoader.getSubtitle()
        ) {
          FilteredShowsView(
            viewModel: FilteredShowsViewModel(
              preloadedShows: self.shows,
              fetchShows: self.sectionLoader.getCards
            ),
            title: self.sectionLoader.getTitle(),
            description: self.sectionLoader.getSubtitle(),
            displaySeason: self.sectionLoader.displaySeason()
          )
        }

        ScrollView(.horizontal) {
          LazyHStack(spacing: RawShowCard.RECOMMENDED_SPACING) {
            ForEach(self.shows) { show in
              ShowCard(show: show, displaySeason: self.sectionLoader.displaySeason())
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
