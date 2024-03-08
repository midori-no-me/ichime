//
//  ShowView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import CachedAsyncImage
import SwiftUI

private enum Anime365ListTypeMenu: String, CaseIterable {
    case completed
    case dropped
    case notInList
    case onHold
    case planned
    case watching

    var imageInDropdown: String {
        switch self {
        case .notInList: return ""
        case .planned: return "hourglass"
        case .watching: return "eye.fill"
        case .completed: return "checkmark"
        case .onHold: return "pause.fill"
        case .dropped: return "archivebox.fill"
        }
    }

    var imageInToolbar: String {
        switch self {
        case .notInList: return "plus.circle"
        case .planned: return "hourglass.circle.fill"
        case .watching: return "eye.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "archivebox.circle.fill"
        }
    }
}

class ShowViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loaded(Show)
    }

    @Published private(set) var state = State.idle
    @Published private(set) var shareUrl: URL

    private let client: Anime365Client
    private let showId: Int

    init(
        showId: Int,
        preloadedShow: Show? = nil
    ) {
        self.showId = showId
        shareUrl = getWebsiteUrlByShowId(showId: showId)

        if let preloadedShow = preloadedShow {
            state = .loaded(preloadedShow)
        }

        client = ServiceLocator.getAnime365Client()
    }

    func performInitialLoad() async {
        state = .loading

        do {
            let show = try await client.getShow(
                seriesId: showId
            )

            state = .loaded(show)
            shareUrl = show.websiteUrl
        } catch {
            state = .loadingFailed(error)
        }
    }

    func performPullToRefresh() async {
        do {
            let show = try await client.getShow(
                seriesId: showId
            )

            state = .loaded(show)
            shareUrl = show.websiteUrl
        } catch {
            state = .loadingFailed(error)
        }
    }
}

struct ShowView: View {
    @ObservedObject var viewModel: ShowViewModel

    @State private var userListStatus: Anime365ListTypeMenu = .notInList

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad()
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
                    ShowDetails(show: show)
                        .scenePadding(.bottom)
                }
                .navigationTitle(show.title.translated.japaneseRomaji ?? show.title.full)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // TODO: Add network request to actually update status in list on a server

                    Section("Hi") {
                        Picker(selection: self.$userListStatus, label: Text("Управление списком")) {
                            Label("Запланировано", systemImage: Anime365ListTypeMenu.planned.imageInDropdown)
                                .tag(Anime365ListTypeMenu.planned)
                            Label("Смотрю", systemImage: Anime365ListTypeMenu.watching.imageInDropdown)
                                .tag(Anime365ListTypeMenu.watching)
                            Label("Просмотрено", systemImage: Anime365ListTypeMenu.completed.imageInDropdown)
                                .tag(Anime365ListTypeMenu.completed)
                            Label("Отложено", systemImage: Anime365ListTypeMenu.onHold.imageInDropdown)
                                .tag(Anime365ListTypeMenu.onHold)
                            Label("Брошено", systemImage: Anime365ListTypeMenu.dropped.imageInDropdown)
                                .tag(Anime365ListTypeMenu.dropped)
                        }
                    }

                    if self.userListStatus != Anime365ListTypeMenu.notInList {
                        Button(role: .destructive) {
                            self.userListStatus = .notInList
                        } label: {
                            Label("Удалить из списка", systemImage: "trash")
                        }
                    }
                }
                label: {
                    Label("Управлять списком", systemImage: self.userListStatus.imageInToolbar)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: self.viewModel.shareUrl) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await self.viewModel.performPullToRefresh()
        }
    }
}

private struct ShowDetails: View {
    let show: Show

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if let russianTitle = show.title.translated.russian {
            Text(russianTitle)
                .font(.title3)
                .scenePadding(.horizontal)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }

        HStack(alignment: .top, spacing: 18) {
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
                                .shadow(radius: 8)

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

            let gridColumns = self.horizontalSizeClass == .compact
                ? [GridItem(.flexible(), spacing: 18, alignment: .topLeading)]
                : [
                    GridItem(.flexible(), spacing: 18, alignment: .topLeading),
                    GridItem(.flexible(), spacing: 18, alignment: .topLeading),
                ]

            VStack(alignment: .trailing, spacing: 18) {
                LazyVGrid(columns: gridColumns, spacing: 18) {
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
                    if !self.show.descriptions.isEmpty {
                        VStack {
                            ForEach(self.show.descriptions, id: \.self) { description in
                                ShowDescription(description: description)
                            }
                        }
                        .padding(.top, 18)
                    }
                }
            }
            .frame(width: .infinity)
        }
        .scenePadding(.horizontal)
        .padding(.top, 18)

        if self.horizontalSizeClass == .compact {
            if !self.show.descriptions.isEmpty {
                VStack {
                    ForEach(self.show.descriptions, id: \.self) { description in
                        ShowDescription(description: description)
                    }
                }
                .scenePadding(.horizontal)
                .padding(.top, 18)
            }
        }

        if !self.show.episodePreviews.isEmpty {
            EpisodePreviewList(
                isOngoing: self.show.isOngoing,
                episodePreviews: self.show.episodePreviews
            )
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
        .sheet(isPresented: self.$showingSheet) {
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
            .navigationBarTitleDisplayMode(.inline)
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

private struct EpisodePreviewList: View {
    let isOngoing: Bool
    let episodePreviews: [EpisodePreview]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Серии")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink(destination: EpisodeListView(episodePreviews: self.episodePreviews, lastEpisodeWatched: 0)) {
                    Text("Все серии")
                        .font(.callout)
                }
                .buttonStyle(.borderless)
                .frame(alignment: .trailing)
            }

            if self.isOngoing, let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: episodePreviews) {
                Text(
                    "Это онгоинг. Обычно новые серии выходят по \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1)."
                )
                .font(.subheadline)
            }

            ForEach(self.episodePreviews.prefix(5), id: \.self) { episodePreview in
                NavigationLink(destination: EpisodeTranslationsView(
                    episodeId: episodePreview.id,
                    episodeTitle: episodePreview
                        .title ?? episodePreview
                        .typeAndNumber
                )) {
                    HStack {
                        EpisodePreviewRow(data: episodePreview)

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .foregroundColor(Color(UIColor.systemGray3))
                            .fontWeight(.bold)
                            .font(.footnote)
                    }
                    .contentShape(Rectangle()) // по какой-то причине без этого не будет работать NavigationLink если
                    // нажимать на Spacer
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
        .padding(.top, 22)
        .scenePadding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ShowView(viewModel: .init(showId: 8762))
    }
}
