import SwiftUI

private struct MyListEntry: View {
  let primaryTitle: String
  let secondaryTitle: String?
  let currentEpisodeProgress: Int
  let totalEpisodes: Int?

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(self.primaryTitle)

        if let secondaryTitle {
          Text(secondaryTitle)
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
      }

      Spacer()

      Text(self.formatEpisodeProgressString())
        .foregroundStyle(Color.secondary)
    }
  }

  private func formatEpisodeProgressString() -> String {
    var stringComponents: [String] = [
      String(currentEpisodeProgress)
    ]

    if let totalEpisodes {
      stringComponents.append(String(totalEpisodes))
    }
    else {
      stringComponents.append(
        EpisodeService.formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(self.currentEpisodeProgress)
      )
    }

    return stringComponents.joined(separator: " / ")
  }
}

struct AnimeList: View {
  let status: AnimeWatchStatus
  let animeList: [UserAnimeListModel]

  @State private var selectedShow: MyListShow?

  var body: some View {
    List {
      Section {
        ForEach(self.animeList, id: \.id) { show in
          Button(action: {
            self.selectedShow = .init(id: show.id, name: show.name.ru, totalEpisodes: show.progress.total)
          }) {
            MyListEntry(
              primaryTitle: show.name.ru,  // TODO: сделать romaji primary
              secondaryTitle: show.name.romaji,
              currentEpisodeProgress: show.progress.watched,
              totalEpisodes: show.progress.total
            )
            .contextMenu(
              menuItems: {
                NavigationLink(destination: ShowView(showId: show.id)) {
                  Text("Открыть")
                }
              },
              preview: {
                IndependentShowCardContextMenuPreview(showId: show.id)
              }
            )
          }
        }
      } header: {
        Text(self.status.title)
      }
    }
    .sheet(
      item: self.$selectedShow,
      content: { show in
        MyListEditView(
          show: show
        )
      }
    )
  }
}
