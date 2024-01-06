//
//  ShowView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

enum Anime365ListTypeMenu: String, CaseIterable {
    case notInList
    case planned
    case watching
    case completed
    case onHold
    case dropped

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

    @State public var show: Show? = nil
    @State private var isLoading = true
    @State private var isErrorLoading = false
    @State private var userListStatus: Anime365ListTypeMenu = .notInList

    var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                if let show = self.show {
                    ShowDetails(show: show)
                } else {
                    if self.isErrorLoading {
                        Text("Ошибка при загрузке")
                    } else if self.isLoading {
                        VStack {
                            ProgressView()
                        }
                    }
                }
            }
        }

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // TODO: Add network request to actually update status in list on a server

                    Section("Hi") {
                        Picker(selection: self.$userListStatus, label: Text("Управление списком")) {
                            Label("Запланировано", systemImage: Anime365ListTypeMenu.planned.imageInDropdown).tag(Anime365ListTypeMenu.planned)
                            Label("Смотрю", systemImage: Anime365ListTypeMenu.watching.imageInDropdown).tag(Anime365ListTypeMenu.watching)
                            Label("Просмотрено", systemImage: Anime365ListTypeMenu.completed.imageInDropdown).tag(Anime365ListTypeMenu.completed)
                            Label("Отложено", systemImage: Anime365ListTypeMenu.onHold.imageInDropdown).tag(Anime365ListTypeMenu.onHold)
                            Label("Брошено", systemImage: Anime365ListTypeMenu.dropped.imageInDropdown).tag(Anime365ListTypeMenu.dropped)
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
        .onAppear {
            if self.show != nil {
                return
            }

            Task {
                await self.fetchShow(showId: self.showId)
            }
        }
    }

    private func fetchShow(showId: Int) async {
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
                self.isErrorLoading = true
            }
        }

        isLoading = false
    }
}

struct ShowDetails: View {
    let show: Show

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if let russianTitle = show.title.translated.russian {
            Text(russianTitle)
                .font(.title3)
                .padding(.leading, 18)
                .padding(.trailing, 18)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }

        HStack(alignment: .top, spacing: 18) {
            GeometryReader { geometry in
                AsyncImage(
                    url: self.show.posterUrl!,
                    transaction: .init(animation: .easeInOut),
                    content: { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .cornerRadius(4)
                                .aspectRatio(contentMode: .fit)
//                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()

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
                : [GridItem(.flexible(), spacing: 18, alignment: .topLeading), GridItem(.flexible(), spacing: 18, alignment: .topLeading)]

            VStack(alignment: .trailing, spacing: 18) {
                LazyVGrid(columns: gridColumns, spacing: 18) {
                    ShowProperty(
                        label: "Рейтинг",
                        value: self.show.score != nil ? String(self.show.score!) : "???"
                    )

                    ShowProperty(
                        label: "Сезон",
                        value: self.show.calendarSeason
                    )

                    ShowProperty(
                        label: "Количество эпизодов",
                        value: (show.numberOfEpisodes != nil ? String(show.numberOfEpisodes!) : "???") + (self.show.isOngoing ? " — онгоинг" : "")
                    )

                    ShowProperty(
                        label: "Тип",
                        value: self.show.typeTitle
                    )

                    if !self.show.genres.isEmpty {
                        ShowProperty(
                            label: "Жанры",
                            value: self.show.genres.joined(separator: ", ")
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
        .padding(.leading, 18)
        .padding(.trailing, 18)
        .padding(.top, 18)

        if horizontalSizeClass == .compact {
            if !self.show.descriptions.isEmpty {
                VStack {
                    ForEach(self.show.descriptions, id: \.self) { description in
                        ShowDescription(description: description)
                    }
                }
                .padding(.leading, 18)
                .padding(.trailing, 18)
                .padding(.top, 18)
            }
        }

        Text("Серии")
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 18)
            .padding(.trailing, 18)
            .padding(.top, 18)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(self.show.episodePreviews, id: \.self) { episodePreview in
                EpisodePreviewBox(
                    title: episodePreview.title,
                    releaseDate: episodePreview.uploadDate,
                    typeAndNumber: episodePreview.typeAndNumber
                )
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, 18)
    }
}

struct ShowProperty: View {
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

struct ShowDescription: View {
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
                        NavigationView {
                            VStack(alignment: .leading) {
                                Text(self.description.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18)

                                Spacer()
                            }
                            .navigationBarTitle("Описание от \(self.description.source)", displayMode: .inline)
                            .navigationBarItems(trailing: Button(action: {
                                showingSheet.toggle()
                            }) {
                                Text("Закрыть")
                            })
                        }
                    }

            }.padding(.top, 4)
        }
    }
}

struct EpisodePreviewBox: View {
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
        .background(Color.gray.opacity(0.25))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ShowView(showId: 28240)
    }
}
