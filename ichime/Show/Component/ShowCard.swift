//
//  ShowView.swift
//  ichime
//
//  Created by p.flaks on 07.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct ShowCard: View {
    let show: Show

    var body: some View {
        NavigationLink(value: show) {
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
                            case let .success(image):
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
                    #if os(macOS)
                        .background(Color(nsColor: .windowBackgroundColor))
                    #else
                        .background(Color(UIColor.secondarySystemBackground))
                    #endif
                        .cornerRadius(10)
                }

                Text(show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title.translated
                    .russian ?? show.title.full)
                    .font(.subheadline)
                    .lineLimit(2, reservesSpace: true)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .contextMenu {
                ShareLink(item: show.websiteUrl) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
            } preview: {
                ShowCardContextMenuPreview(
                    posterUrl: show.posterUrl!,
                    title: show.title.translated.japaneseRomaji ?? show.title.translated.english ?? show.title
                        .translated.russian ?? show.title.full,
                    calendarSeason: show.calendarSeason,
                    typeTitle: show.typeTitle
                )
            }
        }
        .contentShape(Rectangle()) // чтобы хитбокс у ссылки был такой же как и карточка, без этого он может быть больше
        .buttonStyle(.plain)
    }
}

private struct ShowCardContextMenuPreview: View {
    let posterUrl: URL
    let title: String
    let calendarSeason: String?
    let typeTitle: String?

    var body: some View {
        VStack(alignment: .center) {
            CachedAsyncImage(
                url: posterUrl,
                transaction: .init(animation: .easeInOut),
                content: { phase in
                    switch phase {
                    case .empty:
                        VStack {
                            ProgressView()
                        }
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()

                    case .failure:
                        VStack {
                            Image(systemName: "wifi.slash")
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            )
            #if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
            #else
            .background(Color(UIColor.secondarySystemBackground))
            #endif
            .cornerRadius(10)

            if let metaInformationLine = self.getMetaInformationLine(
                calendarSeason: calendarSeason,
                typeTitle: typeTitle
            ) {
                Text(metaInformationLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding()
    }

    private func getMetaInformationLine(
        calendarSeason: String?,
        typeTitle: String?
    ) -> String? {
        var parts: [String] = []

        if let typeTitle {
            parts.append(typeTitle)
        }

        if let calendarSeason {
            parts.append(calendarSeason)
        }

        return parts.isEmpty
            ? nil
            : parts.formatted(.list(type: .and, width: .narrow))
    }
}

#Preview("ShowCardContextMenuPreview (vertical image)") {
    Text("Long tap to preview")
        .contextMenu {
            Button {} label: {
                Label("Поделиться", systemImage: "square.and.arrow.up")
            }
        } preview: {
            ShowCardContextMenuPreview(
                posterUrl: URL(string: "https://placekitten.com/200/400")!,
                title: "Preview traits are used to customize the appearance of certain kinds of previews",
                calendarSeason: "Summer 2024",
                typeTitle: "ТВ-сериал"
            )
        }
}

#Preview("ShowCardContextMenuPreview (horizontal image)") {
    Text("Long tap to preview")
        .contextMenu {
            Button {} label: {
                Label("Поделиться", systemImage: "square.and.arrow.up")
            }
        } preview: {
            ShowCardContextMenuPreview(
                posterUrl: URL(string: "https://placekitten.com/400/200")!,
                title: "Preview traits are used to customize the appearance of certain kinds of previews",
                calendarSeason: "Summer 2024",
                typeTitle: "ТВ-сериал"
            )
        }
}

// #Preview {
//    ShowCard()
// }
