//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//

import SwiftUI

struct OngoingsView: View {
    @State public var shows: [Show]?
    @State private var currentOffset = 0
    @State private var isLoading = true
    @State private var loadingError: Error?
    @State private var stopLazyLoading = false

    /// Изменение этой переменной форсит ререндер сетки карточек.
    @State private var uuidThatForcesCardsGridRerender: UUID = .init()

    private let SHOWS_PER_PAGE = 20

    var body: some View {
        Group {
            if let shows = self.shows {
                if shows.isEmpty {
                    OngoingsViewWrapper {
                        Spacer()

                        ContentUnavailableView {
                            Label("Ничего не нашлось", systemImage: "rectangle.grid.3x2.fill")
                        } description: {
                            Text("Кажется, где-то закрался баг 😭")
                        }

                        Spacer()
                    }

                } else {
                    ScrollView([.vertical]) {
                        OngoingsViewWrapper {
                            OngoingsGrid(
                                shows: shows,
                                loadMore: { await self.fetchOngoings(offset: self.currentOffset + self.SHOWS_PER_PAGE) }
                            )
                            .id(self.uuidThatForcesCardsGridRerender)
                            .padding(.top, 18)
                            .scenePadding(.horizontal)
                            .scenePadding(.bottom)
                        }
                    }
                }
            } else {
                if self.isLoading {
                    OngoingsViewWrapper {
                        Spacer()

                        ProgressView()

                        Spacer()
                    }

                } else if let loadingError = self.loadingError {
                    OngoingsViewWrapper {
                        Spacer()

                        ContentUnavailableView {
                            Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(loadingError.localizedDescription)
                        }
                        .textSelection(.enabled)

                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Онгоинги")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if self.shows != nil || self.stopLazyLoading {
                return
            }

            Task {
                await self.fetchOngoings(offset: 0)
            }
        }
        .refreshable {
            self.stopLazyLoading = false
            await self.fetchOngoings(offset: 0)
        }
    }

    private func fetchOngoings(
        offset: Int
    ) async {
        if self.stopLazyLoading {
            return
        }

        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let shows = try await anime365Client.getOngoings(
                offset: offset,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.count < self.SHOWS_PER_PAGE {
                self.stopLazyLoading = true
            }

            var newShowsState = self.shows ?? []

            if self.shows == nil {
                newShowsState = []
            }

            /// Если запрашивают страницу, номер которой меньше или равен текущей странице в стейте,
            /// то загружаем все сериалы с начала и заставляем все карточки перерендериться (через `self.uuidThatForcesCardsGridRerender`),
            /// чтобы у них сбросился `View.onAppear()`, без которого не будет работать lazy loading.
            if offset <= self.currentOffset {
                newShowsState = []
                self.uuidThatForcesCardsGridRerender = UUID()
            }

            self.shows = newShowsState + shows
            self.currentOffset = offset

        } catch {
            self.loadingError = error
        }

        self.isLoading = false
    }
}

private struct OngoingsViewWrapper<Content>: View where Content: View {
    @ViewBuilder let content: Content

    var body: some View {
        Text("Сериалы, у которых продолжают выходить новые серии")
            .font(.title3)
            .scenePadding(.horizontal)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)

        self.content
    }
}

private struct OngoingsGrid: View {
    let shows: [Show]
    let loadMore: () async -> ()

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .topLeading)], spacing: 18) {
            ForEach(self.shows) { show in
                ShowCard(show: show)
                    .frame(height: 300)
                    .onAppear {
                        Task {
                            if show == self.shows.last {
                                await self.loadMore()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
