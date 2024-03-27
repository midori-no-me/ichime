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
                ScrollView([.vertical]) {
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
        #if !os(tvOS)
            HeadingSectionWithBackground(imageUrl: show.posterUrl!) {
                ShowKeyDetailsSection(show: show, viewModel: viewModel)
                    .padding(.bottom, SPACING_BETWEEN_SECTIONS)
                    .horizontalScreenEdgePadding()
            }
            .padding(.bottom, SPACING_BETWEEN_SECTIONS)
        #endif

        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
            #if os(tvOS)
                ShowKeyDetailsSection(show: show, viewModel: viewModel)
            #endif

            if !show.descriptions.isEmpty {
                ShowDescriptionCards(descriptions: show.descriptions)
            }
        }
        .horizontalScreenEdgePadding()
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
                            value: self.show.score != nil ? self.show.score!.formatted() : "???"
                        )

                        ShowProperty(
                            label: "Сезон",
                            value: self.show.calendarSeason
                        )

                        ShowProperty(
                            label: "Количество эпизодов",
                            value: (self.show.numberOfEpisodes != nil ? self.show.numberOfEpisodes!
                                .formatted() : "???")
                                + (self.show.isOngoing ? " — онгоинг" : "")
                        )

                        ShowProperty(
                            label: "Тип",
                            value: self.show.typeTitle
                        )

                        if !self.show.genres.isEmpty {
                            ShowProperty(
                                label: "Жанры",
                                value: self.show.genres.formatted(.list(type: .and, width: .narrow))
                            )
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
                    Label("Смотреть", systemImage: "play.fill")
                    #if os(tvOS)
                        .padding(20)
                    #endif
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #else
                .buttonStyle(.borderedProminent)
                #endif

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

            if !show.episodePreviews.isEmpty && show.isOngoing,
               let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: show.episodePreviews)
            {
                Text(
                    "Обычно новые серии выходят по \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1)."
                )
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
            }
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

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.label)
                .foregroundStyle(.secondary)
                .font(.caption)
                .fontWeight(.medium)

            Text(self.value)
                .font(.caption)
        }
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
    }
}

#Preview {
    NavigationStack {
        ShowView(showId: 8762)
    }
}
