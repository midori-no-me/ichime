//
//  ShowView.swift
//  ichime
//
//  Created by p.flaks on 05.01.2024.
//

import CachedAsyncImage
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
        get {
            if let userRate {
                return userRate.status
            } else {
                return .deleted
            }
        }
        set {
            Task {
                await updateUserRateShow(rate: newValue)
            }
        }
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

    func updateUserRateShow(rate newRate: UserRateStatus) async {
        let request = ScraperAPI.Request.UpdateUserRate(
            showId: showId,
            userRate: .init(
                score: userRate?.score ?? 0,
                currentEpisode: userRate?.currentEpisode ?? 0,
                status: newRate,
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
                .textSelection(.enabled)

            case let .loaded(show):
                ScrollView([.vertical]) {
                    ShowDetails(show: show, viewModel: self.viewModel)
                        .scenePadding(.bottom)
                }
                .navigationTitle(show.title.translated.japaneseRomaji ?? show.title.full)
                #if os(macOS)
                    .navigationSubtitle(show.title.translated.russian ?? "")
                #endif
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: self.viewModel.shareUrl) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        #endif
        .refreshable {
            await self.viewModel.performPullToRefresh()
        }
    }
}

private struct ShowDetails: View {
    let show: Show
    @State private var showImage = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State public var viewModel: ShowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            #if !os(macOS)
                if horizontalSizeClass == .compact {
                    if let russianTitle = show.title.translated.russian {
                        Text(russianTitle)
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            #endif

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 30) {
                    #if !os(macOS)
                        if horizontalSizeClass == .regular {
                            if let russianTitle = show.title.translated.russian {
                                Text(russianTitle)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
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
                            value: (self.show.numberOfEpisodes != nil ? self.show.numberOfEpisodes!.formatted() : "???")
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

                    if self.horizontalSizeClass == .regular {
                        Spacer()

                        ActionButtons(show: show, viewModel: viewModel)
                    }
                }

                GeometryReader { geometry in
                    CachedAsyncImage(
                        url: self.show.posterUrl!,
                        transaction: .init(animation: .easeInOut),
                        content: { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case let .success(image):
                                image.resizable()
                                    .cornerRadius(10)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                                    .onTapGesture(perform: {
                                        self.showImage = true
                                    })

                            case .failure:
                                VStack {
                                    Image(systemName: "wifi.slash")
                                }
                                .scaledToFit()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .fullScreenCover(isPresented: $showImage, content: {
                    NavigationStack {
                        CachedAsyncImage(url: self.show.posterUrl)
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

            if horizontalSizeClass == .compact {
                ActionButtons(show: show, viewModel: viewModel)
            }

            if !show.descriptions.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 500, maximum: .infinity), spacing: 18, alignment: .topLeading),
                ], spacing: 18) {
                    ForEach(self.show.descriptions, id: \.self) { description in
                        ShowDescription(description: description)
                    }
                }
            }
        }
        .scenePadding(.horizontal)
    }
}

private struct ActionButtons: View {
    let show: Show
    @State public var viewModel: ShowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                NavigationLink(
                    destination: EpisodeListView(episodePreviews: self.show.episodePreviews)
                ) {
                    Label("Смотреть", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Menu {
                    Section("Добавить в список") {
                        Picker(selection: self.$viewModel.showRateStatus, label: Text("Управление списком")) {
                            ForEach(UserRateStatus.allCases, id: \.self) { status in
                                if status != .deleted {
                                    Label(status.displayName, systemImage: status.imageInDropdown)
                                        .tag(status)
                                }
                            }
                        }
                    }

                    if self.viewModel.showRateStatus != UserRateStatus.deleted {
                        Button(role: .destructive) {
                            self.viewModel.showRateStatus = .deleted
                        } label: {
                            Label(
                                UserRateStatus.deleted.displayName,
                                systemImage: UserRateStatus.deleted.imageInDropdown
                            )
                        }
                    }
                } label: {
                    Label(
                        self.viewModel.showRateStatus.statusDisplayName,
                        systemImage: self.viewModel.showRateStatus.imageInToolbar
                    )
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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

            Text(self.value)
                .font(.caption)
        }
    }
}

private struct ShowDescription: View {
    let description: Show.Description

    @State private var showingSheet = false

    var body: some View {
        Button {
            self.showingSheet.toggle()
        } label: {
            GroupBox(label: Text("Описание от \(self.description.source)")) {
                VStack(alignment: .leading) {
                    Text(self.description.text)
                        .lineLimit(5)
                        .truncationMode(.tail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showingSheet) {
            ShowDescriptionSheetView(
                description: self.description
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ShowDescriptionSheetView: View {
    let description: Show.Description

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                VStack(alignment: .leading) {
                    Text(self.description.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scenePadding()
                        .textSelection(.enabled)

                    Spacer()
                }
            }
            .navigationTitle("Описание от \(self.description.source)")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif

                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") {
                            self.dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        ShowView(showId: 8762)
    }
}
