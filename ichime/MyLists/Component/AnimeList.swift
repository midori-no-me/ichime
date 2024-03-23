//
//  AnimeList.swift
//  ichime
//
//  Created by Nikita Nafranets on 26.01.2024.
//

import ScraperAPI
import SwiftUI

public extension ScraperAPI.Types.Show {
    var websiteUrl: URL {
        getWebsiteUrlByShowId(showId: id)
    }
}

#if !os(tvOS)
    struct AnimeList: View {
        let categories: [ScraperAPI.Types.ListByCategory]
        let onUpdate: () async -> Void

        @State var selectedShow: ScraperAPI.Types.Show?

        var body: some View {
            List {
                ForEach(categories, id: \.type) { category in
                    Section {
                        ForEach(category.shows, id: \.id) { show in
                            Button(action: {
                                selectedShow = show
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(show.name.ru).font(.body)
                                        if !show.name.romaji.isEmpty {
                                            Text(show.name.romaji).font(.caption).foregroundColor(Color.gray)
                                        }
                                    }
                                    Spacer()
                                    Text(
                                        "\(show.episodes.watched) / \(show.episodes.total == Int.max ? "??" : String(show.episodes.total))"
                                    )
                                    .font(.footnote).padding(.leading)
                                }
                                .contextMenu(menuItems: {
                                    #if !os(tvOS)
                                        ShareLink(item: show.websiteUrl) {
                                            Label("Поделиться", systemImage: "square.and.arrow.up")
                                        }
                                    #endif
                                    NavigationLink(destination: ShowView(showId: show.id)) {
                                        Text("Открыть")
                                    }
                                }, preview: {
                                    IndependentShowCardContextMenuPreview(showId: show.id)
                                })
                            }
                        }
                    } header: {
                        Text(category.type.rawValue)
                    }
                }
            }
            .listStyle(.grouped)
            .sheet(item: $selectedShow, content: { show in
                MyListEditView(
                    show: .init(id: show.id, name: show.name.ru, totalEpisodes: show.episodes.total)
                ) {
                    Task {
                        await onUpdate()
                    }
                }
            })
        }
    }
#else
    struct AnimeList: View {
        let categories: [ScraperAPI.Types.ListByCategory]
        let onUpdate: () async -> Void

        @State var selectedShow: ScraperAPI.Types.Show?

        @State var selectedCategory: ScraperAPI.Types.ListCategoryType?

        var category: ScraperAPI.Types.ListByCategory? {
            categories.first(where: { $0.type == selectedCategory })
        }

        var body: some View {
            NavigationSplitView(sidebar: {
                List(selection: $selectedCategory) {
                    ForEach(categories, id: \.type) { category in
                        Button(action: {
                            selectedCategory = category.type
                        }, label: {
                            Text(category.type.rawValue)
                        })
                    }
                }
            }, detail: {
                if let category {
                    List {
                        Section {
                            ForEach(category.shows, id: \.id) { show in
                                Button(action: {
                                    selectedShow = show
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(show.name.ru).font(.body)
                                            if !show.name.romaji.isEmpty {
                                                Text(show.name.romaji).font(.caption).foregroundColor(Color.gray)
                                            }
                                        }
                                        Spacer()
                                        Text(
                                            "\(show.episodes.watched) / \(show.episodes.total == Int.max ? "??" : String(show.episodes.total))"
                                        )
                                        .font(.footnote).padding(.leading)
                                    }
                                    .contextMenu(menuItems: {
                                        #if !os(tvOS)
                                            ShareLink(item: show.websiteUrl) {
                                                Label("Поделиться", systemImage: "square.and.arrow.up")
                                            }
                                        #endif
                                        NavigationLink(destination: ShowView(showId: show.id)) {
                                            Text("Открыть")
                                        }
                                    }, preview: {
                                        IndependentShowCardContextMenuPreview(showId: show.id)
                                    })
                                }
                            }
                        } header: {
                            Text(category.type.rawValue)
                        }
                    }
                    .listStyle(.grouped)
                    .sheet(item: $selectedShow, content: { show in
                        MyListEditView(
                            show: .init(id: show.id, name: show.name.ru, totalEpisodes: show.episodes.total)
                        ) {
                            Task {
                                await onUpdate()
                            }
                        }
                    })
                }
            })
        }
    }
#endif

#Preview {
    NavigationStack {
        AnimeList(categories: ScraperAPI.Types.ListByCategory.sampleData) {}
    }
}
