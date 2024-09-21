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

private struct MyListEntry: View {
    public let primaryTitle: String
    public let secondaryTitle: String?
    public let currentEpisodeProgress: Int
    public let totalEpisodes: Int?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(primaryTitle)

                if let secondaryTitle {
                    Text(secondaryTitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            Text(formatEpisodeProgressString())
                .foregroundStyle(Color.secondary)
        }
    }

    private func formatEpisodeProgressString() -> String {
        var stringComponents: [String] = [
            String(currentEpisodeProgress),
        ]

        if let totalEpisodes {
            stringComponents.append(String(totalEpisodes))
        } else {
            stringComponents.append("??")
        }

        return stringComponents.joined(separator: " / ")
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
                                MyListEntry(
                                    primaryTitle: show.name.ru, // TODO: сделать romaji primary
                                    secondaryTitle: show.name.romaji,
                                    currentEpisodeProgress: show.episodes.watched,
                                    totalEpisodes: show.episodes.total == Int.max ? nil : show.episodes.total // TODO: че за костыль с Int.max?
                                )
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
                                    MyListEntry(
                                        primaryTitle: show.name.ru, // TODO: сделать romaji primary
                                        secondaryTitle: show.name.romaji,
                                        currentEpisodeProgress: show.episodes.watched,
                                        totalEpisodes: show.episodes.total == Int.max ? nil : show.episodes.total // TODO: че за костыль с Int.max?
                                    )
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
