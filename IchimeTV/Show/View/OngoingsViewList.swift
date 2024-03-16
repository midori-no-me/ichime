//
//  OngoingsViewList.swift
//  IchimeTV
//
//  Created by p.flaks on 16.03.2024.
//

import SwiftUI

struct OngoingsViewList: View {
    var body: some View {
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

#Preview {
    NavigationStack {
        OngoingsViewList()
    }
}
