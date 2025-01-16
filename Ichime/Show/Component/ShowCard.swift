import SwiftUI

struct ShowCard: View {
  let show: Show
  let displaySeason: Bool

  var body: some View {
    NavigationLink(
      destination: ShowView(showId: self.show.id, preloadedShow: self.show)
    ) {
      RawShowCard(
        metadataLineComponents: formatMetadataLine(self.show, displaySeason: self.displaySeason),
        cover: self.show.posterUrl,
        primaryTitle: self.show.title.translated.japaneseRomaji ?? self.show.title.full,
        secondaryTitle: self.show.title.translated.russian
      )
    }
    .buttonStyle(.borderless)
  }
}

private func formatMetadataLine(_ show: Show, displaySeason: Bool) -> [String] {
  var metadataLineComponents: [String] = []

  if let score = show.score {
    metadataLineComponents.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
  }

  if let airingSeason = show.airingSeason, displaySeason {
    metadataLineComponents.append(airingSeason.getLocalizedTranslation())
  }

  if show.broadcastType != .tv {
    metadataLineComponents.append(show.typeTitle)
  }

  return metadataLineComponents
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
          calendarSeason: show.airingSeason?.getLocalizedTranslation(),
          typeTitle: show.typeTitle
        )
      }
      else {
        ProgressView()
      }
    }.task {
      self.show = try? await self.client.getShow(
        seriesId: self.showId
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
      AsyncImage(
        url: self.posterUrl,
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

      Text(self.title)
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

// #Preview {
//    NavigationStack {
//        OngoingsView()
//    }
// }

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
