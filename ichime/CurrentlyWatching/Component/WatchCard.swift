//
//  WatchCard.swift
//  ichime
//
//  Created by Nikita Nafranets on 28.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct WatchCard: View {
    private let ROW_PADDING: CGFloat = 4

    let data: WatchCardModel

    var body: some View {
        HStack(alignment: .top) {
            CachedAsyncImage(
                url: data.image,
                transaction: .init(animation: .easeInOut)
            ) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case let .success(image):
                    image.resizable()
                        .scaledToFit()
                        .cornerRadius(4)
                        .clipped()

                case .failure:
                    Image(systemName: "wifi.slash")
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 100, height: 135, alignment: .top)
            .padding(.trailing, ROW_PADDING)

            VStack(alignment: .leading, spacing: 4) {
                Text(data.title + " • " + data.sideText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(data.name.ru)
                    .font(.callout)
                    .fontWeight(.medium)

                if !data.name.romaji.isEmpty {
                    Text(data.name.romaji)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.top, ROW_PADDING)
    }
}

#Preview("Notification") {
    NavigationStack {
        List {
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "2 серия",
                sideText: "Русские субтитры",
                type: .notication
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "OVA 2 серия",
                sideText: "Русская озвучка",
                type: .notication
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "Фильм",
                sideText: "RAW",
                type: .notication
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/35064.34978564114.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "Фильм",
                sideText: "RAW",
                type: .notication
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/31760.23724939004.jpg")!,
                name: .init(
                    ru: "Меня выгнали из гильдии героев, потому что я был плохим компаньоном, поэтому я решил неспешно жить в глуши 2 сезон",
                    romaji: "Shin no Nakama ja Nai to Yuusha no Party wo Oidasareta node, Henkyou de Slow Life suru Koto ni Shimashita 2nd Season"
                ),
                title: "Фильм",
                sideText: "RAW",
                type: .notication
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/35509.36660560254.jpg")!,
                name: .init(ru: "Братик-братик 2", romaji: "Shixiong A Shixiong 2nd Season"),
                title: "Фильм",
                sideText: "RAW",
                type: .notication
            ))
        }
        .listStyle(.plain)
        .navigationTitle("Уведомления")
    }
}

#Preview("Watch") {
    NavigationStack {
        List {
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "2 серия",
                sideText: "Вышло сегодня",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "2 серия",
                sideText: "Вышло 18.01.24",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "OVA 2 серия",
                sideText: "Смотрели вчера",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "Фильм",
                sideText: "В плане с 18.01.24",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "4000 серия",
                sideText: "В плане сегодня",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "4000 серия",
                sideText: "Запланировали 18.01.24",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/35064.34978564114.jpg")!,
                name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
                title: "Фильм",
                sideText: "Запланировали 18.01.24",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/31760.23724939004.jpg")!,
                name: .init(
                    ru: "Меня выгнали из гильдии героев, потому что я был плохим компаньоном, поэтому я решил неспешно жить в глуши 2 сезон",
                    romaji: "Shin no Nakama ja Nai to Yuusha no Party wo Oidasareta node, Henkyou de Slow Life suru Koto ni Shimashita 2nd Season"
                ),
                title: "Фильм",
                sideText: "Запланировали 18.01.24",
                type: .show
            ))
            WatchCard(data: .init(
                id: 1,
                image: URL(string: "https://smotret-anime.com/posters/35509.36660560254.jpg")!,
                name: .init(ru: "Братик-братик 2", romaji: "Shixiong A Shixiong 2nd Season"),
                title: "Фильм",
                sideText: "Запланировали 18.01.24",
                type: .show
            ))
        }
        .listStyle(.plain)
        .navigationTitle("Смотрю")
    }
}
