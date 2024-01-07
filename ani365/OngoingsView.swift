//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//

import SwiftUI

struct OngoingsView: View {
    @State private var shows: [Show]?
    @State private var isLoading = true
    @State private var loadingError: Error?

    var body: some View {
        Group {
            if let shows = self.shows {
                ScrollView([.vertical]) {
                    OngoingsDetails(shows: shows)
                }
            } else {
                if self.isLoading {
                    ProgressView()
                } else if self.loadingError != nil {
                    SceneLoadingErrorView(
                        loadingError: self.loadingError!,
                        reload: { await self.fetchOngoings(forceRefresh: true) }
                    )
                }
            }
        }
        .navigationTitle("Онгоинги")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if self.shows != nil {
                return
            }

            Task {
                await self.fetchOngoings()
            }
        }
        .refreshable {
            await self.fetchOngoings(forceRefresh: true)
        }
    }

    private func fetchOngoings(forceRefresh: Bool = false) async {
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
            let shows = try await anime365Client.getOngoings()

            DispatchQueue.main.async {
                self.shows = shows
            }
        } catch {
            DispatchQueue.main.async {
                self.loadingError = error
            }
        }

        isLoading = false
    }
}

struct OngoingsDetails: View {
    let shows: [Show]

    var body: some View {
        Text("Сериалы, у которых продолжают выходить новые серии")
            .font(.title3)
            .scenePadding(.horizontal)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12, alignment: .topLeading)], spacing: 18) {
            ForEach(self.shows, id: \.self) { show in
                NavigationLink(destination: ShowView(showId: show.id, show: show)) {
                    VStack(alignment: .leading) {
                        GeometryReader { geometry in
                            AsyncImage(
                                url: show.posterUrl!,
                                transaction: .init(animation: .easeInOut),
                                content: { phase in
                                    switch phase {
                                    case .empty:
                                        VStack {
                                            ProgressView()
                                        }
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFill()
                                            .clipped()
                                            .shadow(radius: 4)

                                    case .failure:
                                        VStack {
                                            Image(systemName: "wifi.slash")
                                        }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(4)
                        }

                        Text(show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title.translated.russian ?? show.title.full)
                            .font(.caption)
                            .lineLimit(2, reservesSpace: true)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Spacer()
                    }
                    .frame(height: 220)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .scenePadding(.minimum, edges: .horizontal)
        .padding(.top, 18)
    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
