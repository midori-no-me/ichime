//
//  ShowView.swift
//  ani365
//
//  Created by p.flaks on 07.01.2024.
//

import SwiftUI

struct ShowCard: View {
    let show: Show

    var body: some View {
        NavigationLink(destination: ShowView(showId: show.id, show: show)) {
            VStack(alignment: .leading) {
                GeometryReader { geometry in
                    AsyncImage(
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
                    .cornerRadius(4)
                }

                Text(show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title.translated.russian ?? show.title.full)
                    .font(.caption)
                    .lineLimit(2, reservesSpace: true)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// #Preview {
//    ShowCard()
// }
