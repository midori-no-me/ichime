//
//  ShowView.swift
//  ichime
//
//  Created by p.flaks on 07.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct ShowCard: View {
    #if os(tvOS)
        public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 500
    #else
        public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 250
    #endif

    #if os(tvOS)
        public static let RECOMMENDED_SPACING: CGFloat = 80
    #else
        public static let RECOMMENDED_SPACING: CGFloat = 10
    #endif

    #if os(tvOS)
        private static let IMAGE_WIDTH: CGFloat = 200
        private static let IMAGE_HEIGHT: CGFloat = 270
    #else
        private static let IMAGE_WIDTH: CGFloat = 100
        private static let IMAGE_HEIGHT: CGFloat = 135
    #endif

    #if os(tvOS)
        private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 20
    #else
        private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 10
    #endif

    let show: Show

    var body: some View {
        NavigationLink(
            destination: ShowView(showId: show.id, preloadedShow: show)
        ) {
            HStack(alignment: .top, spacing: ShowCard.SPACING_BETWEEN_IMAGE_AND_CONTENT) {
                CachedAsyncImage(
                    url: show.posterUrl!,
                    transaction: .init(animation: .easeInOut(duration: 0.5))
                ) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.clear)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(4)
                            .clipped()

                    case .failure:
                        Rectangle()
                            .fill(Color.clear)
                    @unknown default:
                        Rectangle()
                            .fill(Color.clear)
                    }
                }
                .frame(
                    width: ShowCard.IMAGE_WIDTH,
                    height: ShowCard.IMAGE_HEIGHT,
                    alignment: .top
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(formatMetadataLine(show))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    if show.title.translated.japaneseRomaji == nil || show.title.translated.russian == nil {
                        Text(show.title.full)
                    } else {
                        Text(show.title.translated.japaneseRomaji!)
                            .font(.callout)
                            .fontWeight(.medium)

                        Text(show.title.translated.russian!)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }
        }
        #if !os(tvOS)
        .contextMenu {
            ShareLink(item: show.websiteUrl) {
                Label("Поделиться", systemImage: "square.and.arrow.up")
            }
        } preview: {
            ShowCardContextMenuPreview(
                posterUrl: show.posterUrl!,
                title: show.title.compose,
                calendarSeason: show.calendarSeason,
                typeTitle: show.typeTitle
            )
        }
        #endif
        .buttonStyle(.plain)
    }
}

private func formatMetadataLine(_ show: Show) -> String {
    var metadataLineComponents: [String] = []

    if let score = show.score {
        metadataLineComponents.append(score.formatted())
    }

    metadataLineComponents.append(show.calendarSeason)

    if show.broadcastType != .tv {
        metadataLineComponents.append(show.typeTitle)
    }

    return metadataLineComponents.joined(separator: " • ")
}

struct IndependentShowCardContextMenuPreview: View {
    let showId: Int
    @State var show: Show? = nil
    var client: Anime365Client = ApplicationDependency.container.resolve()

    var body: some View {
        Group {
            if let show, let posterUrl = show.posterUrl {
                ShowCardContextMenuPreview(
                    posterUrl: posterUrl,
                    title: show.title.compose,
                    calendarSeason: show.calendarSeason,
                    typeTitle: show.typeTitle
                )
            } else {
                ProgressView()
            }
        }.task {
            show = try? await client.getShow(
                seriesId: showId
            )
        }
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
            #endif
            #if os(iOS) // !os(tvOS)
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

#Preview {
    NavigationStack {
        OngoingsView()
    }
}

// #Preview("ShowCardContextMenuPreview (vertical image)") {
//    Text("Long tap to preview")
//        .contextMenu {
//            Button {} label: {
//                Label("Поделиться", systemImage: "square.and.arrow.up")
//            }
//        } preview: {
//            ShowCardContextMenuPreview(
//                posterUrl: URL(string: "https://placekitten.com/200/400")!,
//                title: "Preview traits are used to customize the appearance of certain kinds of previews",
//                calendarSeason: "Summer 2024",
//                typeTitle: "ТВ-сериал"
//            )
//        }
// }
//
// #Preview("ShowCardContextMenuPreview (horizontal image)") {
//    Text("Long tap to preview")
//        .contextMenu {
//            Button {} label: {
//                Label("Поделиться", systemImage: "square.and.arrow.up")
//            }
//        } preview: {
//            ShowCardContextMenuPreview(
//                posterUrl: URL(string: "https://placekitten.com/400/200")!,
//                title: "Preview traits are used to customize the appearance of certain kinds of previews",
//                calendarSeason: "Summer 2024",
//                typeTitle: "ТВ-сериал"
//            )
//        }
// }

// #Preview {
//    @State var show: Show?
//    let client: Anime365Client = ApplicationDependency.container.resolve()
//
//    return Group {
//        VStack {
//            if let show {
//                ShowCard(show: show)
//            }
//        }.onAppear(perform: {
//            Task {
//                print("start")
//                show = try? await client.getShow(
//                    seriesId: 8762
//                )
//                print(show)
//            }
//        })
//    }
// }
