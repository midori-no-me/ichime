//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//

import SwiftUI

struct OngoingsView: View {
    @State private var shows: [Show] = []
    @State private var isLoading = true
    @State private var isErrorLoading = false

    var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                VStack(alignment: .leading) {
                    Text("Сериалы, новые серии которых продолжают выходить")
                        .font(.subheadline)
                        .padding(.leading, 22)
                        .padding(.trailing, 22)
                        .foregroundStyle(.secondary)

                    if self.isLoading {
                        VStack {
                            ProgressView()
                        }
                    }

                    if self.isErrorLoading {
                        Text("Ошибка при загрузке")
                    }

                    if !self.shows.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10, alignment: .topLeading)]) {
                            ForEach(self.shows, id: \.self) { show in
                                NavigationLink(destination: ShowView(showId: show.id, show: show)) {
                                    ShowCard(show: show)
                                        .frame(width: 150)
                                }
                            }
                        }.padding(22)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await self.fetchOngoings()
            }
        }
        .refreshable {
            await self.fetchOngoings(forceRefresh: true)
        }
        .navigationTitle("Онгоинги")
    }

    private func fetchOngoings(forceRefresh: Bool = false) async {
        if !forceRefresh && !self.isLoading {
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
                self.shows = []
                self.isErrorLoading = true
            }
        }

        self.isLoading = false
    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
