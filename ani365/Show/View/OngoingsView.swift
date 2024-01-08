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

    /// Изменение этой переменной форсит ререндер сетки карточек.
    @State private var uuidThatForcesCardsGridRerender: UUID = .init()

    @State private var currentPage = 1

    var body: some View {
        Group {
            if let shows = self.shows {
                ScrollView([.vertical]) {
                    OngoingsDetails(
                        shows: shows,
                        uuidThatForcesCardsGridRerender: self.uuidThatForcesCardsGridRerender,
                        loadMore: { await self.fetchOngoings(page: self.currentPage + 1) }
                    )
                }
            } else {
                if self.isLoading {
                    ProgressView()
                } else if self.loadingError != nil {
                    SceneLoadingErrorView(
                        loadingError: self.loadingError!,
                        reload: { await self.fetchOngoings(page: 1) }
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
                await self.fetchOngoings(page: 1)
            }
        }
        .refreshable {
            await self.fetchOngoings(page: 1)
        }
    }

    private func fetchOngoings(
        page: Int
    ) async {
        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let shows = try await anime365Client.getOngoings(
                page: page,
                limit: 20
            )

            DispatchQueue.main.async {
                if self.shows == nil {
                    self.shows = []
                }

                /// Если запрашивают страницу, номер которой меньше или равен текущей странице в стейте,
                /// то загружаем все сериалы с начала и заставляем все карточки перерендериться (через `self.uuidThatForcesCardsGridRerender`),
                /// чтобы у них сбросился `View.onAppear()`, без которого не будет работать lazy loading.
                if page <= self.currentPage {
                    self.shows = []
                    self.uuidThatForcesCardsGridRerender = UUID()
                }

                self.shows! += shows
                self.currentPage = page
            }
        } catch {
            DispatchQueue.main.async {
                self.loadingError = error
            }
        }

        self.isLoading = false
    }
}

private struct OngoingsDetails: View {
    let shows: [Show]
    let uuidThatForcesCardsGridRerender: UUID
    let loadMore: () async -> ()

    var body: some View {
        Text("Сериалы, у которых продолжают выходить новые серии")
            .font(.title3)
            .padding(.horizontal)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .topLeading)], spacing: 18) {
            ForEach(self.shows) { show in
                ShowCardWithLink(show: show)
                    .frame(height: 300)
                    .onAppear {
                        print(self.uuidThatForcesCardsGridRerender)
                        Task {
                            if show == self.shows.last {
                                await self.loadMore()
                            }
                        }
                    }
            }
        }
        .id(self.uuidThatForcesCardsGridRerender)
        .padding(.horizontal)
        .padding(.top, 18)
    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
