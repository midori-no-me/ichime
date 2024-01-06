//
//  WatchCard.swift
//  ichime
//
//  Created by Nikita Nafranets on 28.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct WatchCard: View {
    let data: WatchCardModel

    var body: some View {
        HStack(alignment: .top, spacing: 10.0) {
            CachedAsyncImage(
                url: data.image,
                transaction: .init(animation: .easeInOut)
            ) { phase in
                switch phase {
                case .empty:
                    VStack {
                        ProgressView()
                    }
                case let .success(image):
                    image.resizable()
                        .scaledToFill()
                        .clipped()

                case .failure:
                    VStack {
                        Image(systemName: "wifi.slash")
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .padding(0)
            .frame(width: 71, height: 100, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading) {
                Text(data.title)
                    .font(.callout)
                    .foregroundColor(Color.blue)
                Text(data.name.ru)
                    .font(.subheadline)
                if !data.name.romaji.isEmpty {
                    Text(data.name.romaji)
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
                Spacer()
                Text(data.sideText)
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            }
            .padding(.bottom)
        }
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
        }
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
        }
    }
}
