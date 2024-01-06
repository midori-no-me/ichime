//
//  SeriesCategoryRow.swift
//  ani365
//
//  Created by p.flaks on 02.01.2024.
//

import SwiftUI

struct ShowCategoryRow: View {
    let title: String
    let description: String
    var shows: [Show]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2)
                    .padding(.leading, 22)
                    .fontWeight(.semibold)

                Text(Image(systemName: "chevron.forward"))
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
            }

            Text(description)
                .font(.subheadline)
                .padding(.leading, 22)
                .padding(.trailing, 22)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(shows, id: \.self) { show in
                        NavigationLink(destination: ShowView(showId: show.id)) {
                            ShowCard(show: show)
                                .frame(width: 150)
                        }
                    }
                }
                .padding(.leading, 22)
                .padding(.trailing, 22)
            }
            .frame(height: 300)
        }
    }
}

// #Preview {
//    ShowCategoryRow(
//        title: "Category Name",
//        description: "Сериалы, новые серии которых продолжают выходить",
//        shows: [
//            Show(
//                id: 123,
//                title: Show.Title(
//                    full: "Shangri-La Frontier: Kusoge Hunter, Kamige ni Idoman to su",
//                    translated: Show.Title.TranslatedTitles(
//                        russian: nil,
//                        english: nil,
//                        japanese: nil,
//                        japaneseRomaji: nil
//                    )
//                ),
//                posterUrl: URL(string: "https://loremflickr.com/400/600"),
//                websiteUrl: URL(string: "https://loremflickr.com/400/600")!
//            ),
//            Show(
//                id: 123,
//                title: Show.Title(
//                    full: "Shangri-La Frontier: Kusoge Hunter, Kamige ni Idoman to su",
//                    translated: Show.Title.TranslatedTitles(
//                        russian: nil,
//                        english: nil,
//                        japanese: nil,
//                        japaneseRomaji: nil
//                    )
//                ),
//                posterUrl: URL(string: "https://loremflickr.com/400/600"),
//                websiteUrl: URL(string: "https://loremflickr.com/400/600")!
//            )
//        ]
//    )
// }
