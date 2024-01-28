//
//  WatchCard.swift
//  ani365
//
//  Created by Nikita Nafranets on 28.01.2024.
//

import SwiftUI

struct WatchCard: View {
    let data: WatchCardModel

    var body: some View {
        HStack(alignment: .top, spacing: 10.0) {
            AsyncImage(
                url: data.image
            ) {
                $0.image?.resizable()
            }
            .scaledToFit()
            .padding(0)
            .clipped()
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
    List {
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "2 серия",
            sideText: "Русские субтитры"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "OVA 2 серия",
            sideText: "Русская озвучка"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "Фильм",
            sideText: "RAW"
        ))
    }
}

#Preview("Watch") {
    List {
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "2 серия",
            sideText: "Вышло сегодня"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "2 серия",
            sideText: "Вышло 18.01.24"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "OVA 2 серия",
            sideText: "Смотрели вчера"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "Фильм",
            sideText: "В плане с 18.01.24"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "4000 серия",
            sideText: "В плане сегодня"
        ))
        WatchCard(data: .init(
            id: 1,
            image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
            name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
            title: "4000 серия",
            sideText: "Запланировали 18.01.24"
        ))
    }
}
