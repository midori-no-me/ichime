//
//  ShowView.swift
//  ani365
//
//  Created by p.flaks on 07.01.2024.
//

import CachedAsyncImage
import SwiftUI

private struct ShowCard: View {
    let show: Show
    let textLineLimit: Int?

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geometry in
                CachedAsyncImage(
                    url: show.posterUrl!,
                    transaction: .init(animation: .easeInOut),
                    content: { phase in
                        switch phase {
                        case .empty:
                            VStack {
                                ProgressView()
                            }
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .clipped()
                                .shadow(radius: 4)

                        case .failure:
                            VStack {
                                Image(systemName: "wifi.slash")
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }

            if let textLineLimit {
                Text(show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title.translated.russian ?? show.title.full)
                    .font(.subheadline)
                    .lineLimit(textLineLimit, reservesSpace: true)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text(show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title.translated.russian ?? show.title.full)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct ShowCardWithLink: View {
    let show: Show

    var body: some View {
        NavigationLink(destination: ShowView(showId: show.id, show: show)) {
            ShowCard(show: show, textLineLimit: 2)
                .contextMenu {
                    Button {} label: {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                } preview: {
                    ShowCard(show: show, textLineLimit: nil)
                        .padding(8)
                        .frame(width: 200, height: 400)
                }
        }
        .contentShape(Rectangle()) // чтобы хитбокс у ссылки был такой же как и карточка, без этого он может быть больше
        .border(Color.red)
        .buttonStyle(PlainButtonStyle())
    }
}

// #Preview {
//    ShowCard()
// }
