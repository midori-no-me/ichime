//
//  ShowView.swift
//  ichime
//
//  Created by p.flaks on 05.01.2024.
//

import ScraperAPI
import SwiftUI

typealias UserRateStatus = ScraperAPI.Types.UserRateStatus
extension ScraperAPI.Types.UserRateStatus {
    var imageInDropdown: String {
        switch self {
        case .deleted: return "trash"
        case .planned: return "hourglass"
        case .watching: return "eye.fill"
        case .completed: return "checkmark"
        case .onHold: return "pause.fill"
        case .dropped: return "archivebox.fill"
        }
    }

    var imageInToolbar: String {
        switch self {
        case .deleted: return "plus.circle"
        case .planned: return "hourglass.circle.fill"
        case .watching: return "eye.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "archivebox.circle.fill"
        }
    }
}

@Observable
class ShowViewModel {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loaded(Show)
    }

    private(set) var state = State.idle
    private var userRate: ScraperAPI.Types.UserRate?
    var showRateStatus: UserRateStatus {
        if let userRate {
            return userRate.status
        } else {
            return .deleted
        }
    }

    var statusReady: Bool {
        userRate != nil
    }

    private let client: Anime365Client
    private let scraperClient: ScraperAPI.APIClient
    private var showId: Int = 0

    var shareUrl: URL {
        getWebsiteUrlByShowId(showId: showId)
    }

    init(
        client: Anime365Client = ApplicationDependency.container.resolve(),
        scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()
    ) {
        self.client = client
        self.scraperClient = scraperClient
    }

    func performInitialLoad(showId: Int, preloadedShow: Show?) async {
        state = .loading

        self.showId = showId

        do {
            if let preloadedShow {
                state = .loaded(preloadedShow)
            } else {
                let show = try await client.getShow(
                    seriesId: showId
                )

                state = .loaded(show)
            }

            await getUserRate(showId: showId)
        } catch {
            state = .loadingFailed(error)
        }
    }

    func performPullToRefresh() async {
        do {
            let show = try await client.getShow(
                seriesId: showId
            )

            await getUserRate(showId: showId)

            state = .loaded(show)
        } catch {
            state = .loadingFailed(error)
        }
    }

    private func getUserRate(showId: Int) async {
        do {
            userRate = try await scraperClient.sendAPIRequest(
                ScraperAPI.Request.GetUserRate(showId: showId, fullCheck: true)
            )
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    func addToList() async {
        let request = ScraperAPI.Request.UpdateUserRate(
            showId: showId,
            userRate: .init(
                score: userRate?.score ?? 0,
                currentEpisode: userRate?.currentEpisode ?? 0,
                status: .planned,
                comment: ""
            )
        )

        do {
            userRate = try await scraperClient.sendAPIRequest(request)
        } catch {
            print("\(error.localizedDescription)")
        }
    }
}

struct ShowView: View {
    var showId: Int
    var preloadedShow: Show?

    @State private var viewModel: ShowViewModel = .init()

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad(showId: self.showId, preloadedShow: self.preloadedShow)
                    }
                }

            case .loading:
                ProgressView()
                #if os(tvOS)
                    .focusable()
                #endif

            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif

            case let .loaded(show):
                ScrollView(.vertical) {
                    ShowDetails(show: show, viewModel: self.viewModel)
                        .scenePadding(.bottom)
                }
                #if os(tvOS)
                .scrollClipDisabled(true)
                #endif
                #if !os(tvOS)
                .navigationTitle(show.title.translated.japaneseRomaji ?? show.title.full)
                #endif
                #if os(macOS)
                .navigationSubtitle(show.title.translated.russian ?? "")
                #endif
            }
        }
        #if !os(tvOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: self.viewModel.shareUrl) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        #endif
        #if os(tvOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .refreshable {
            await self.viewModel.performPullToRefresh()
        }
    }
}

#if os(tvOS)
    private let SPACING_BETWEEN_SECTIONS: CGFloat = 50
#else
    private let SPACING_BETWEEN_SECTIONS: CGFloat = 20
#endif

private struct ShowDetails: View {
    let show: Show
    var viewModel: ShowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
            #if !os(tvOS)
                HeadingSectionWithBackground(imageUrl: show.posterUrl) {
                    ShowKeyDetailsSection(show: show, viewModel: viewModel)
                        .padding(.bottom, SPACING_BETWEEN_SECTIONS)
                        .horizontalScreenEdgePadding()
                }
            #endif

            Group {
                #if os(tvOS)
                    ShowKeyDetailsSection(show: show, viewModel: viewModel)
                #endif

                if !show.descriptions.isEmpty {
                    ShowDescriptionCards(descriptions: show.descriptions)
                }

                ShowMomentsCardsView(showId: show.id, showName: show.title.compose)
            }
            .horizontalScreenEdgePadding()
        }
    }
}

private struct ShowKeyDetailsSection: View {
    let show: Show
    @State private var showImage = false
    var viewModel: ShowViewModel

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
            #if os(iOS)
                if let russianTitle = show.title.translated.russian, horizontalSizeClass == .compact {
                    ShowSecondaryTitle(title: russianTitle)
                }
            #endif

            HStack(alignment: .top, spacing: SPACING_BETWEEN_SECTIONS) {
                VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
                    #if os(tvOS)
                        ShowPrimaryAndSecondaryTitles(title: show.title)
                    #elseif os(iOS)
                        if let russianTitle = show.title.translated.russian, horizontalSizeClass == .regular {
                            ShowSecondaryTitle(title: russianTitle)
                        }
                    #endif

                    #if os(tvOS)
                        ShowActionButtons(show: show, viewModel: viewModel)
                    #endif

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 18, alignment: .topLeading),
                    ], spacing: 18) {
                        ShowProperty(
                            label: "Рейтинг",
                            value: self.show
                                .score != nil ?
                                "★ \(self.show.score!.formatted(.number.precision(.fractionLength(2))))" :
                                "???",
                            isInteractive: false
                        )

                        ShowProperty(
                            label: "Тип",
                            value: self.show.typeTitle,
                            isInteractive: false
                        )

                        EpisodesShowProperty(
                            totalEpisodes: self.show.numberOfEpisodes,
                            episodePreviews: self.show.episodePreviews,
                            isOngoing: self.show.isOngoing
                        )

                        if let airingSeason = self.show.airingSeason {
                            SeasonShowProperty(airingSeason: airingSeason)
                        } else {
                            ShowProperty(
                                label: "Сезон",
                                value: "???",
                                isInteractive: false
                            )
                        }

                        if !self.show.genres.isEmpty {
                            GenresShowProperty(showTitle: self.show.title, genres: self.show.genres)
                        }
                    }

                    #if !os(tvOS)
                        if horizontalSizeClass == .regular {
                            Spacer()

                            ShowActionButtons(show: show, viewModel: viewModel)
                        }
                    #endif
                }

                if let posterUrl = self.show.posterUrl {
                    GeometryReader { geometry in
                        AsyncImage(
                            url: posterUrl,
                            transaction: .init(animation: .easeInOut(duration: 0.5)),
                            content: { phase in
                                switch phase {
                                case .empty:
                                    EmptyView()
                                case let .success(image):
                                    image.resizable()
                                        .cornerRadiusForLargeObject()
                                        .aspectRatio(contentMode: .fit)
                                        .clipped()
                                        .onTapGesture(perform: {
                                            self.showImage = true
                                        })

                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
                    }
                    .fullScreenCover(isPresented: $showImage, content: {
                        NavigationStack {
                            AsyncImage(url: self.show.posterUrl)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Закрыть") {
                                            showImage = false
                                        }
                                    }
                                }
                        }
                        .preferredColorScheme(.dark)
                    })
                }
            }

            #if !os(tvOS)
                if horizontalSizeClass == .compact {
                    ShowActionButtons(show: show, viewModel: viewModel)
                }
            #endif
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }
}

@available(tvOS 17.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
private struct ShowPrimaryAndSecondaryTitles: View {
    let title: Show.Title

    var body: some View {
        VStack {
            Group {
                if title.translated.japaneseRomaji == nil || title.translated.russian == nil {
                    Text(title.full)
                        .font(.title2)
                }

                if let japaneseRomajiTitle = title.translated.japaneseRomaji {
                    Text(japaneseRomajiTitle)
                        .font(.title2)
                }

                if let russianTitle = title.translated.russian {
                    Text(russianTitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(2)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@available(tvOS, unavailable)
private struct ShowSecondaryTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }
}

private struct ShowActionButtons: View {
    let show: Show
    var viewModel: ShowViewModel
    @State var showEdit = false

    #if os(tvOS)
        private let SPACING_BETWEEN_BUTTONS: CGFloat = 40
    #else
        private let SPACING_BETWEEN_BUTTONS: CGFloat = 10
    #endif

    var isInMyList: Bool {
        viewModel.showRateStatus != UserRateStatus.deleted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: SPACING_BETWEEN_BUTTONS) {
                NavigationLink(
                    destination: EpisodeListView(episodePreviews: self.show.episodePreviews)
                ) {
                    Label("Смотреть", systemImage: show.episodePreviews.isEmpty ? "play.slash.fill" : "play.fill")
                    #if os(tvOS)
                        .padding(20)
                    #endif
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #else
                .buttonStyle(.borderedProminent)
                #endif
                .disabled(show.episodePreviews.isEmpty)

                if viewModel.statusReady {
                    Button(action: {
                        if isInMyList {
                            showEdit = true
                        } else {
                            Task {
                                await viewModel.addToList()
                            }
                        }
                    }) {
                        Group {
                            if isInMyList {
                                Label(
                                    self.viewModel.showRateStatus.statusDisplayName,
                                    systemImage: self.viewModel.showRateStatus.imageInToolbar
                                )
                            } else {
                                Label(
                                    UserRateStatus.deleted.statusDisplayName,
                                    systemImage: UserRateStatus.deleted.imageInToolbar
                                )
                            }
                        }
                        #if os(tvOS)
                        .padding(20)
                        #endif
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    #else
                    .buttonStyle(.bordered)
                    #endif
                }
            }
            #if os(tvOS)
            .focusSection()
            #endif

            Group {
                if !show.episodePreviews.isEmpty && show.isOngoing,
                   let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: show.episodePreviews)
                {
                    Text(
                        "Обычно новые серии выходят по \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1)."
                    )
                }

                if show.episodePreviews.isEmpty {
                    Text(
                        "У этого тайтла пока что нет загруженных серий."
                    )
                }
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.caption)
        }
        .sheet(isPresented: $showEdit, content: {
            MyListEditView(
                show: .init(id: show.id, name: show.title.compose, totalEpisodes: show.numberOfEpisodes ?? Int.max),
                onUpdate: {
                    Task {
                        await self.viewModel.performPullToRefresh()
                    }
                }
            )
        })
    }
}

private struct ShowProperty: View {
    let label: String
    let value: String
    let isInteractive: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 4) {
                Text(self.label)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .fontWeight(.medium)

                #if !os(tvOS)
                    if isInteractive {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                    }
                #endif
            }

            Text(self.value)
                .font(.caption)
        }
    }
}

private struct SeasonShowProperty: View {
    let airingSeason: AiringSeason
    let client: Anime365Client

    init(
        airingSeason: AiringSeason,
        client: Anime365Client = ApplicationDependency.container.resolve()
    ) {
        self.airingSeason = airingSeason
        self.client = client
    }

    var body: some View {
        NavigationLink(destination: FilteredShowsView(
            viewModel: .init(fetchShows: getShowsBySeason()),
            title: airingSeason.getLocalizedTranslation(),
            description: nil,
            displaySeason: false
        )) {
            ShowProperty(
                label: "Сезон",
                value: airingSeason.getLocalizedTranslation(),
                isInteractive: true
            )
        }
        .buttonStyle(.plain)
    }

    private func getShowsBySeason() -> (_ offset: Int, _ limit: Int) async throws -> [Show] {
        func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [Show] {
            return try await client.getSeason(
                offset: offset,
                limit: limit,
                airingSeason: airingSeason
            )
        }

        return fetchFunction
    }
}

private struct GenresShowProperty: View {
    let showTitle: Show.Title
    let genres: [Show.Genre]

    var body: some View {
        NavigationLink(destination: ShowGenreListView(
            showTitle: showTitle,
            genres: genres
        )) {
            ShowProperty(
                label: "Жанры",
                value: genres
                    .map { genre in genre.title }
                    .formatted(.list(type: .and, width: .narrow)),
                isInteractive: true
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EpisodesShowProperty: View {
    let totalEpisodes: Int?
    let episodePreviews: [EpisodePreview]
    let isOngoing: Bool

    var body: some View {
        ShowProperty(
            label: "Количество эпизодов",
            value: formatString(),
            isInteractive: false
        )
    }

    private func formatString() -> String {
        let latestEpisodeNumber = getLatestEpisodeNumber()

        if isOngoing {
            return "Вышло \(latestEpisodeNumber.formatted()) из \(totalEpisodes?.formatted() ?? "???")"
        }

        if let totalEpisodes {
            return totalEpisodes.formatted()
        }

        return "???"
    }

    private func getLatestEpisodeNumber() -> Float {
        let filteredAndSortedEpisodes = episodePreviews
            .filter { episodePreview in episodePreview.type != .trailer }
            .filter { episodePreview in episodePreview.episodeNumber != nil }
            .filter { episodePreview in episodePreview.episodeNumber! > 0 }
            .filter { episodePreview in
                episodePreview.episodeNumber!.truncatingRemainder(dividingBy: 1) == 0
            } // remove episodes with non-round number like 35.5
            .sorted(by: { $0.episodeNumber! > $1.episodeNumber! })

        if filteredAndSortedEpisodes.isEmpty {
            return 0
        }

        return filteredAndSortedEpisodes[0].episodeNumber ?? 0
    }
}

private struct ShowDescriptionCards: View {
    let descriptions: [Show.Description]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(
                .adaptive(minimum: CardWithExpandableText.RECOMMENDED_MINIMUM_WIDTH),
                spacing: CardWithExpandableText.RECOMMENDED_SPACING
            ),
        ], spacing: CardWithExpandableText.RECOMMENDED_SPACING) {
            ForEach(descriptions, id: \.self) { description in
                CardWithExpandableText(
                    title: "Описание от \(description.source)",
                    text: description.text
                )
            }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }
}

#Preview {
    NavigationStack {
        ShowView(showId: 8762)
    }
}
