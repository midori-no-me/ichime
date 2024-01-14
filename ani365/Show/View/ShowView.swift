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
        case .planned: return "clock"
        case .watching: return "eye.fill"
        case .completed: return "checkmark"
        case .onHold: return "pause.fill"
        case .dropped: return "archivebox.fill"
        }
    }

    var imageInToolbar: String {
        switch self {
        case .notInList: return "plus.circle"
        case .planned: return "clock.circle.fill"
        case .watching: return "eye.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "archivebox.circle.fill"
        }
    }
}

struct ShowView: View {
    let showId: Int

    @State public var show: Show?
    @State private var isLoading = true
    @State private var loadingError: Error?
    @State private var userListStatus: Anime365ListTypeMenu = .notInList

    var body: some View {
        Group {
            if let show = self.show {
                ScrollView([.vertical]) {
                    ShowDetails(show: show)
                        .scenePadding(.bottom)
                }
            } else {
                if self.isLoading {
                    ProgressView()
                } else if self.loadingError != nil {
                    SceneLoadingErrorView(
                        loadingError: self.loadingError!,
                        reload: { await self.fetchShow(showId: self.showId, forceRefresh: true) }
                    )
                }
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

            //            ToolbarItem(placement: .navigationBarTrailing) {
            //                ShareLink(item: show?.websiteUrl) {
            //                    Label("Поделиться", systemImage: "square.and.arrow.up")
            //                }
            //            }
        }
        .navigationTitle((self.show?.title.translated.japaneseRomaji ?? self.show?.title.full) ?? "")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if self.show != nil {
                return
            }

            Task {
                await self.fetchShow(showId: self.showId)
            }
        }
        .refreshable {
            await self.fetchShow(showId: self.showId, forceRefresh: true)
        }
    }

    private func fetchShow(showId: Int, forceRefresh: Bool = false) async {
        if !forceRefresh && !isLoading {
            return
        }

        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let show = try await anime365Client.getShow(seriesId: showId)

            DispatchQueue.main.async {
                self.show = show
            }
        } catch {
            DispatchQueue.main.async {
                self.loadingError = error
            }
        }

        isLoading = false
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
                        case .success(let image):
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

            let gridColumns = horizontalSizeClass == .compact
                ? [GridItem(.flexible(), spacing: 18, alignment: .topLeading)]
                : [
                    GridItem(.flexible(), spacing: 18, alignment: .topLeading),
                    GridItem(.flexible(), spacing: 18, alignment: .topLeading)
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
                        value: (show.numberOfEpisodes != nil ? show.numberOfEpisodes!.formatted() : "???")
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

                if horizontalSizeClass == .regular {
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

        if horizontalSizeClass == .compact {
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
                isOgnoing: self.show.isOngoing,
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
            Text(label)
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(value)
                .font(.caption)
        }
    }
}

private struct ShowDescription: View {
    let description: Show.Description

    @State private var showingSheet = false

    var body: some View {
        GroupBox(label: Text("Описание от \(self.description.source)")) {
            VStack(alignment: .leading) {
                Text(self.description.text)
                    .lineLimit(5)
                    .truncationMode(.tail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        showingSheet.toggle()
                    }
                    .sheet(isPresented: $showingSheet) {
                        NavigationStack {
                            VStack(alignment: .leading) {
                                Text(self.description.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .scenePadding()

                                Spacer()
                            }
                            .navigationTitle("Описание от \(self.description.source)")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(
                                        action: {
                                            showingSheet.toggle()
                                        },
                                        label: {
                                            Text("Закрыть")
                                        }
                                    )
                                }
                            }
                        }
                    }
            }
            .padding(.top, 4)
        }
    }
}

private struct EpisodePreviewList: View {
    let isOgnoing: Bool
    let episodePreviews: [EpisodePreview]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Серии")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink(destination: EpisodeListView(episodePreviews: episodePreviews)) {
                    Text("Все серии")
                        .font(.callout)
                }
                .buttonStyle(.borderless)
                .frame(alignment: .trailing)
            }

            if isOgnoing, let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: episodePreviews) {
                Text("Это онгоинг. Обычно новые серии выходят в \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1).")
                    .font(.subheadline)
            }

            ForEach(episodePreviews.prefix(5), id: \.self) { episodePreview in
                EpisodePreviewRow(data: episodePreview)

                Divider()
            }
        }
        .padding(.top, 18)
        .scenePadding(.horizontal)
    }
}

private struct EpisodePreviewBox: View {
    let title: String?
    let releaseDate: Date
    let typeAndNumber: String

    var body: some View {
        VStack {
            Text(typeAndNumber)
                .padding(8)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ShowView(showId: 8762)
    }
}
