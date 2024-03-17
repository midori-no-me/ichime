//
//  ShowView.swift
//  IchimeTV
//
//  Created by p.flaks on 16.03.2024.
//

import CachedAsyncImage
import SwiftUI

import UIKit

extension UIScrollView {
    override open var clipsToBounds: Bool {
        get { false }
        set {}
    }
}

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
        descriptions: [
            Show.Description(
                text: "Владыка Тьмы повержен, и вместе с тем подошло к концу путешествие героя Химмеля и его отряда. Шли годы, все они разбрелись кто куда, но только эльфийке-долгожительнице Фрирен десятилетия показались мгновением, и однажды на её плечи легла тяжесть осознания того, что людской век ужасно скоротечен. В конце концов эльфийка решает во чтобы то ни стало исполнить предсмертные желания своих друзей. Но сможет ли она это сделать? И как сильно её потрясёт череда неизбежных потерь? Фрирен пускается в путь, чтобы это выяснить.",
                source: "world-art"
            ),
            Show.Description(
                text: "Одержав победу над Королём демонов, отряд героя Химмеля вернулся домой. Приключение, растянувшееся на десятилетие, подошло к завершению. Волшебница-эльф Фрирен и её отважные товарищи принесли людям мир и разошлись в разные стороны, чтобы спокойно прожить остаток жизни. Однако не всех членов отряда ждёт одинаковая участь. Для эльфов время течёт иначе, поэтому Фрирен вынужденно становится свидетелем того, как её спутники один за другим постепенно уходят из жизни. Девушка осознала, что годы, проведённые в отряде героя, пронеслись в один миг, как падающая звезда в бескрайнем космосе её жизни, и столкнулась с сожалениями об упущенных возможностях. Сможет ли она смириться со смертью друзей и понять, что значит жизнь для окружающих её людей? Фрирен начинает новое путешествие, чтобы найти ответ.",
                source: "shikimori"
            ),
        ],
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
            ScrollView(.vertical) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 80) {
                        VStack {
                            Group {
                                if let japaneseRomajiTitle = show.title.translated.japaneseRomaji {
                                    Text(japaneseRomajiTitle)
                                        .font(.title)
                                }

                                if let russianTitle = show.title.translated.russian {
                                    Text(russianTitle)
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }

                                if show.title.translated.japaneseRomaji == nil && show.title.translated.russian == nil {
                                    Text(show.title.full)
                                        .font(.title)
                                }
                            }
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }

                        HStack(spacing: 50) {
                            Button(action: {}, label: {
                                Label("Смотреть", systemImage: "play.fill")
                            })

                            Button(action: {}, label: {
                                Label("Добавить в список", systemImage: "plus.circle")
                            })
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
                                value: (show.numberOfEpisodes != nil ? show.numberOfEpisodes!
                                    .formatted() : "???")
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
                    }

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
                }
                .frame(height: UIScreen.main.bounds.size.height * 0.7)

                if !show.descriptions.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 50, alignment: .topLeading),
                        GridItem(.flexible(), spacing: 50, alignment: .topLeading),
                        GridItem(.flexible(), spacing: 50, alignment: .topLeading),
                    ], spacing: 50) {
                        ForEach(show.descriptions, id: \.self) { description in
                            ShowDescription(description: description)
                        }
                    }
                    .padding(.top, 80)
                }
            }
            .frame(maxWidth: .infinity)
            .toolbar(.hidden, for: .tabBar)
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

private struct ShowDescription: View {
    let description: Show.Description

    @State private var showingSheet = false

    var body: some View {
        Button {
            self.showingSheet.toggle()
        } label: {
            VStack(spacing: 20) {
                Group {
                    Text("Описание от \(self.description.source)")
                    Text(self.description.text)
                        .lineLimit(5)
                        .truncationMode(.tail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(30)
        }
        .sheet(isPresented: $showingSheet) {
            ShowDescriptionSheetView(
                description: self.description
            )
        }
        .buttonStyle(.card)
    }
}

private struct ShowDescriptionSheetView: View {
    let description: Show.Description

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                VStack(alignment: .leading) {
                    Text(self.description.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scenePadding()

                    Spacer()
                }
            }
            .navigationTitle("Описание от \(self.description.source)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        self.dismiss()
                    }
                }
            }
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
