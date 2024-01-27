//
//  AnimeList.swift
//  ani365
//
//  Created by Nikita Nafranets on 26.01.2024.
//

import ScraperAPI
import SwiftUI

struct AnimeList: View {
    let categories: [ScraperAPI.Types.ListByCategory]

    @Binding var selectedShow: Int?

    var body: some View {
        List(selection: $selectedShow) {
            ForEach(categories, id: \.type) { category in
                Section(category.type.rawValue) {
                    ForEach(category.shows, id: \.id) { show in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(show.name.ru).font(.body)
                                if !show.name.romaji.isEmpty {
                                    Text(show.name.romaji).font(.caption).foregroundColor(Color.gray)
                                }
                            }
                            Spacer()
                            Text(
                                "\(show.episodes.watched) / \(show.episodes.total == Int.max ? "??" : String(show.episodes.total))"
                            )
                            .font(.footnote).padding(.leading)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @State var showId: Int?

    return AnimeList(categories: ScraperAPI.Types.ListByCategory.sampleData, selectedShow: $showId)
}
