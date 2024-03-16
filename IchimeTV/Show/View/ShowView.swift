//
//  ShowView.swift
//  IchimeTV
//
//  Created by p.flaks on 16.03.2024.
//

import CachedAsyncImage
import SwiftUI

struct ShowView: View {
    let showId: Int
    private let preloadedShow: Show? = Show(
        id: 30414,
        title: Show.Title(
            full: "Провожающая в последний путь Фрирен / Sousou no Frieren",
            translated: Show.Title.TranslatedTitles(
                russian: "Провожающая в последний путь Фрирен",
                english: "Frieren: Beyond Journey's End",
                japanese: "葬送のフリーレン",
                japaneseRomaji: "Sousou no Frieren"
            )
        ),
        descriptions: [Show.Description(
            text: "Владыка Тьмы повержен, и вместе с тем подошло к концу путешествие героя Химмеля и его отряда. Шли годы, все они разбрелись кто куда, но только эльфийке-долгожительнице Фрирен десятилетия показались мгновением, и однажды на её плечи легла тяжесть осознания того, что людской век ужасно скоротечен. В конце концов эльфийка решает во чтобы то ни стало исполнить предсмертные желания своих друзей. Но сможет ли она это сделать? И как сильно её потрясёт череда неизбежных потерь? Фрирен пускается в путь, чтобы это выяснить.",
            source: "world-art"
        )],
        posterUrl: URL(string: "https://anime365.ru/posters/30414.41480234924.jpg")!,
        websiteUrl: URL(string: "https://anime365.ru/catalog/sousou-no-frieren-30414")!,
        score: 9.17,
        calendarSeason: "Осень 2023",
        numberOfEpisodes: 28,
        typeTitle: "ТВ сериал",
        genres: ["Приключения", "Сёнен", "Фентези", "Драма"],
        isOngoing: true,
        episodePreviews: []
    )

    var body: some View {
        if let show = preloadedShow {
            ZStack {
                CachedAsyncImage(
                    url: show.posterUrl!,
                    transaction: .init(animation: .easeInOut),
                    content: { phase in
                        switch phase {
                        case .empty:
                            EmptyView()

                        case let .success(image):
                            image.resizable()
                                .scaledToFill()
                                .clipShape(
                                    .rect(
                                        topLeadingRadius: 10,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 10
                                    )
                                )
                                .clipped()

                        case .failure:
                            EmptyView()

                        @unknown default:
                            EmptyView()
                        }
                    }
                )
                .ignoresSafeArea()
                .overlay(.ultraThickMaterial)

                HStack(alignment: .top) {
                    CachedAsyncImage(
                        url: show.posterUrl!,
                        transaction: .init(animation: .easeInOut),
                        content: { phase in
                            switch phase {
                            case .empty:
                                ProgressView()

                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                    .clipped()

                            case .failure:
                                Image(systemName: "wifi.slash")

                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(maxHeight: 800)
//                    .border(Color.red)

                    VStack(alignment: .leading, spacing: 30) {
                        if let russianTitle = show.title.translated.russian {
                            Text(russianTitle)
                                .font(.title3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 30, alignment: .topLeading),
                            GridItem(.flexible(), spacing: 30, alignment: .topLeading),
                        ], spacing: 30) {
                            ShowProperty(
                                label: "Рейтинг",
                                value: show.score != nil ? show.score!.formatted() : "???"
                            )

                            ShowProperty(
                                label: "Сезон",
                                value: show.calendarSeason
                            )

                            ShowProperty(
                                label: "Количество эпизодов",
                                value: (show.numberOfEpisodes != nil ? show.numberOfEpisodes!.formatted() : "???")
                                    + (show.isOngoing ? " — онгоинг" : "")
                            )

                            ShowProperty(
                                label: "Тип",
                                value: show.typeTitle
                            )

                            if !show.genres.isEmpty {
                                ShowProperty(
                                    label: "Жанры",
                                    value: show.genres.formatted(.list(type: .and, width: .narrow))
                                )
                            }
                        }

                        HStack(alignment: .top) {
                            NavigationLink(destination: Text("episode list")) {
                                Text("Смотреть")
                            }
                        }
                        .padding(.top, 100)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .border(Color.red)
                }
            }
            .navigationTitle(show.title.translated.japaneseRomaji ?? show.title.full)
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

#Preview {
    NavigationStack {
        ShowView(
            showId: 30414
        )
    }
}
