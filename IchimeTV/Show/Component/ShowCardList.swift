//
//  ShowCard.swift
//  IchimeTV
//
//  Created by p.flaks on 16.03.2024.
//

import CachedAsyncImage
import SwiftUI

struct ShowCardList: View {
    public let id: Int
    public let posterUrl: URL
    public let titleFull: String
    public let titleRussian: String?
    public let titleRomaji: String?
    public let score: Float?
    public let showTypeTitle: String?
    public let numberOfEpisodes: Int?

    var body: some View {
        NavigationLink(destination: ShowView(showId: id)) {
            HStack(alignment: .top, spacing: 0) {
                CachedAsyncImage(
                    url: posterUrl,
                    transaction: .init(animation: .easeInOut),
                    content: { phase in
                        switch phase {
                        case .empty:
                            ProgressView()

                        case let .success(image):
                            image.resizable()
                                .scaledToFill()

                        case .failure:
                            Image(systemName: "wifi.slash")

                        @unknown default:
                            EmptyView()
                        }
                    }
                )
                .frame(width: 200, height: 300)
                .cornerRadius(10)
                .clipped()

                VStack(alignment: .leading, spacing: 15) {
                    Text(self.formatFirstLine())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let titleRomaji {
                        Text(titleRomaji)
                            .font(.callout)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    if let titleRussian {
                        Text(titleRussian)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    if titleRussian == nil && titleRomaji == nil {
                        Text(titleFull)
                            .font(.callout)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .padding()
            }
        }
    }

    private func formatFirstLine() -> String {
        var lineComponents: [String] = []

        if let score {
            lineComponents.append(score.formatted())
        } else {
            lineComponents.append("???")
        }

        if let showTypeTitle {
            lineComponents.append(showTypeTitle)
        } else {
            lineComponents.append("???")
        }

        if let numberOfEpisodes {
            lineComponents.append("эпизодов: \(numberOfEpisodes.formatted())")
        } else {
            lineComponents.append("эпизодов: ???")
        }

        return lineComponents.joined(separator: " • ")
    }
}

#Preview {
    NavigationStack {
        List {
            ShowCardList(
                id: 35064,
                posterUrl: URL(string: "https://smotret-anime.com/posters/35064.34978564114.jpg")!,
                titleFull: "Провожающая в последний путь Фрирен: Магия ●● / Sousou no Frieren: ●● no Mahou",
                titleRussian: "Провожающая в последний путь Фрирен: Магия ●●",
                titleRomaji: "Sousou no Frieren: ●● no Mahou",
                score: 9.17,
                showTypeTitle: "ТВ сериал",
                numberOfEpisodes: 28
            )

            ShowCardList(
                id: 35509,
                posterUrl: URL(string: "https://smotret-anime.com/posters/35509.36660560254.jpg")!,
                titleFull: "Братик-братик 2 / Shixiong A Shixiong 2nd Season",
                titleRussian: "Братик-братик 2",
                titleRomaji: "Shixiong A Shixiong 2nd Season",
                score: 9.17,
                showTypeTitle: "ТВ сериал",
                numberOfEpisodes: 28
            )
        }
    }
}
