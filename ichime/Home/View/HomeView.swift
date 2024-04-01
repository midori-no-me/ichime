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
        "Тайтлы, у которых продолжают выходить новые серии"
    }

    func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
        do {
            return try await client.getOngoings(offset: offset, limit: limit)
        } catch {
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
        "Самые высокооцененные тайтлы"
    }

    func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
        do {
            return try await client.getTop(offset: offset, limit: limit)
        } catch {
            return []
        }
    }

    func displaySeason() -> Bool {
        true
    }
}

private class SeasonalSectionLoader: ShowsSectionLoader {
    private let client: Anime365Client
    private let yearAndSeason: (Int, SeasonName)
    private let description: String?

    init(
        yearAndSeason: (Int, SeasonName),
        description: String?,
        client: Anime365Client = ApplicationDependency.container.resolve()
    ) {
        self.client = client
        self.yearAndSeason = yearAndSeason
        self.description = description
        id = "\(yearAndSeason.0)_\(yearAndSeason.1)"
    }

    var id: String

    func getTitle() -> String {
        "\(yearAndSeason.1.getLocalizedTranslation()) \(yearAndSeason.0)"
    }

    func getSubtitle() -> String? {
        description
    }

    func getCards(_ offset: Int, _ limit: Int) async -> [Show] {
        do {
            return try await client.getSeason(
                offset: offset,
                limit: limit,
                season: yearAndSeason.1,
                year: yearAndSeason.0
            )
        } catch {
            return []
        }
    }

    func displaySeason() -> Bool {
        false
    }
}

struct HomeView: View {
    @State private var sectionLoaders: [any ShowsSectionLoader] = []

    #if os(tvOS)
        private let SPACING_BETWEEN_SECTIONS: CGFloat = 70
    #else
        private let SPACING_BETWEEN_SECTIONS: CGFloat = 30
    #endif

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
            .horizontalScreenEdgePadding()
        }
        .onAppear {
            sectionLoaders.append(getNextSectionLoader())
        }
        #if !os(tvOS)
        .navigationTitle("Главная")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ProfileButton()
        }
        #endif
        #if os(tvOS)
        .scrollClipDisabled(true)
        #endif
    }

    private func getNextSectionLoader() -> any ShowsSectionLoader {
        let showSeasonService = ShowSeasonService()

        let predefinedLoaders: [any ShowsSectionLoader] = [
            OngoingsSectionLoader(),
            TopSectionLoader(),
            SeasonalSectionLoader(
                yearAndSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.NEXT_SEASON),
                description: "Следующий сезон"
            ),
            SeasonalSectionLoader(
                yearAndSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.CURRENT_SEASON),
                description: "Текущий сезон"
            ),
            SeasonalSectionLoader(
                yearAndSeason: showSeasonService.getRelativeSeason(shift: ShowSeasonService.PREVIOUS_SEASON),
                description: "Прошлый сезон"
            ),
        ]

        if sectionLoaders.count < predefinedLoaders.count {
            return predefinedLoaders[sectionLoaders.count]
        }

        let lastPredefinedSeasonalSectionShift = ShowSeasonService.PREVIOUS_SEASON

        return SeasonalSectionLoader(
            yearAndSeason: showSeasonService
                .getRelativeSeason(
                    shift: predefinedLoaders.count - sectionLoaders.count + lastPredefinedSeasonalSectionShift - 1
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

    #if os(tvOS)
        private let SPACING_BETWEEN_TITLE_CARD_CARDS: CGFloat = 50
    #else
        private let SPACING_BETWEEN_TITLE_CARD_CARDS: CGFloat = 20
    #endif

    var body: some View {
        if isLoading {
            Color.clear.onAppear {
                Task {
                    self.shows = await sectionLoader.getCards(0, 10)
                    self.isLoading = false
                    self.onLoaded()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: SPACING_BETWEEN_TITLE_CARD_CARDS) {
                VStack(alignment: .leading) {
                    NavigationLink(destination: FilteredShowsView(
                        viewModel: FilteredShowsViewModel(
                            preloadedShows: shows,
                            fetchShows: sectionLoader.getCards
                        ),
                        title: sectionLoader.getTitle(),
                        description: sectionLoader.getSubtitle()
                    )) {
                        HStack(alignment: .center) {
                            #if os(tvOS)
                                Text(sectionLoader.getTitle())
                                    .font(.title3)
                                    .fontWeight(.bold)
                            #else
                                Text(sectionLoader.getTitle())
                                    .font(.title)
                                    .fontWeight(.bold)

                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.bold)
                            #endif
                        }
                    }
                    .buttonStyle(.plain)

                    if let description = sectionLoader.getSubtitle() {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                #if os(tvOS)
                .focusSection()
                #endif

                ScrollView(.horizontal) {
                    LazyHGrid(rows: [
                        GridItem(
                            .flexible(),
                            spacing: RawShowCard.RECOMMENDED_SPACING,
                            alignment: .topLeading
                        ),
                    ], spacing: RawShowCard.RECOMMENDED_SPACING) {
                        ForEach(self.shows) { show in
                            ShowCard(show: show, displaySeason: sectionLoader.displaySeason())
                                .frame(width: RawShowCard.RECOMMENDED_MINIMUM_WIDTH)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .transition(.asymmetric(insertion: .scale, removal: .opacity))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
