import SwiftUI

struct WatchCard: View {
  private let ROW_PADDING: CGFloat = 4

  let data: WatchCardModel

  var body: some View {
    RawShowCard(
      metadataLineComponents: [self.data.title, self.data.sideText],
      cover: self.data.image,
      primaryTitle: self.data.name.romaji,
      secondaryTitle: self.data.name.ru
    )
  }
}

#Preview("Notification") {
  NavigationStack {
    List {
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "2 серия",
          sideText: "Русские субтитры",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "OVA 2 серия",
          sideText: "Русская озвучка",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "Фильм",
          sideText: "RAW",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/35064.34978564114.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "Фильм",
          sideText: "RAW",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/31760.23724939004.jpg")!,
          name: .init(
            ru:
              "Меня выгнали из гильдии героев, потому что я был плохим компаньоном, поэтому я решил неспешно жить в глуши 2 сезон",
            romaji:
              "Shin no Nakama ja Nai to Yuusha no Party wo Oidasareta node, Henkyou de Slow Life suru Koto ni Shimashita 2nd Season"
          ),
          title: "Фильм",
          sideText: "RAW",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/35509.36660560254.jpg")!,
          name: .init(ru: "Братик-братик 2", romaji: "Shixiong A Shixiong 2nd Season"),
          title: "Фильм",
          sideText: "RAW",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
    }
    .listStyle(.plain)
    .navigationTitle("Уведомления")
  }
}

#Preview("Watch") {
  NavigationStack {
    List {
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "2 серия",
          sideText: "Вышло сегодня",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "2 серия",
          sideText: "Вышло 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "OVA 2 серия",
          sideText: "Смотрели вчера",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "Фильм",
          sideText: "В плане с 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "4000 серия",
          sideText: "В плане сегодня",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/33660.19485418034.400x400.0.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "4000 серия",
          sideText: "Запланировали 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/35064.34978564114.jpg")!,
          name: .init(ru: "Взрывной храбрец Брейверн", romaji: "Yuuki Bakuhatsu Bang Bravern"),
          title: "Фильм",
          sideText: "Запланировали 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/31760.23724939004.jpg")!,
          name: .init(
            ru:
              "Меня выгнали из гильдии героев, потому что я был плохим компаньоном, поэтому я решил неспешно жить в глуши 2 сезон",
            romaji:
              "Shin no Nakama ja Nai to Yuusha no Party wo Oidasareta node, Henkyou de Slow Life suru Koto ni Shimashita 2nd Season"
          ),
          title: "Фильм",
          sideText: "Запланировали 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
      WatchCard(
        data: .init(
          id: 1,
          image: URL(string: "https://smotret-anime.com/posters/35509.36660560254.jpg")!,
          name: .init(ru: "Братик-братик 2", romaji: "Shixiong A Shixiong 2nd Season"),
          title: "Фильм",
          sideText: "Запланировали 18.01.24",
          data: .init(episode: 1, title: "2 серия", translation: 1)
        )
      )
    }
    .listStyle(.plain)
    .navigationTitle("Смотрю")
  }
}
