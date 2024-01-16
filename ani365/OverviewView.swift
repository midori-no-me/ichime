//
//  OverviewView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct OverviewView: View {
    @State private var ongoingsShows: [Show]?
    @State private var ongoingsIsLoading = true
    @State private var ongoingsLoadingError: Error?

    var body: some View {
        Group {
            if let shows = self.ongoingsShows {
                ScrollView([.vertical]) {
                    OverviewDetails(
                        ongoingsShows: shows
                    )
                    .scenePadding(.bottom)
                }

            } else {
                if self.ongoingsIsLoading {
                    ProgressView()
                } else if self.ongoingsLoadingError != nil {
                    SceneLoadingErrorView(
                        loadingError: self.ongoingsLoadingError!,
                        reload: { await self.fetchOngoings(offset: 0) }
                    )
                }
            }
        }
        .navigationTitle("Обзор")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if self.ongoingsShows != nil {
                return
            }

            Task {
                await self.fetchOngoings(offset: 0)
            }
        }
        .refreshable {
            await self.fetchOngoings(offset: 0)
        }
    }

    private func fetchOngoings(
        offset: Int
    ) async {
        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let shows = try await anime365Client.getOngoings(
                offset: offset,
                limit: 20
            )

            DispatchQueue.main.async {
                if self.ongoingsShows == nil {
                    self.ongoingsShows = []
                }

                self.ongoingsShows! += shows
            }
        } catch {
            DispatchQueue.main.async {
                self.ongoingsLoadingError = error
            }
        }

        self.ongoingsIsLoading = false
    }
}

private struct OverviewDetails: View {
    let ongoingsShows: [Show]

    var body: some View {
        ShowCategoryRow(
            title: "Онгоинги",
            description: "Сериалы, у которых продолжают выходить новые серии",
            shows: self.ongoingsShows
        ) {
            OngoingsView(viewModel: .init(
                preloadedShows: self.ongoingsShows
            ))
        }
    }
}

#Preview {
    NavigationStack {
        VStack(alignment: .leading) {
            OverviewView()
        }
    }
}
