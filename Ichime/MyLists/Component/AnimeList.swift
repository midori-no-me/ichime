//
//  AnimeList.swift
//  ichime
//
//  Created by Nikita Nafranets on 26.01.2024.
//

import ScraperAPI
import SwiftUI

extension ScraperAPI.Types.Show {
  public var websiteUrl: URL {
    getWebsiteUrlByShowId(showId: id)
  }
}

private struct MyListEntry: View {
  public let primaryTitle: String
  public let secondaryTitle: String?
  public let currentEpisodeProgress: Int
  public let totalEpisodes: Int?

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(primaryTitle)

        if let secondaryTitle {
          Text(secondaryTitle)
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
      }

      Spacer()

      Text(formatEpisodeProgressString())
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
      stringComponents.append("??")
    }

    return stringComponents.joined(separator: " / ")
  }
}

struct AnimeList: View {
  let status: AnimeWatchStatus
  let animeList: [UserAnimeListModel]

  @State var selectedShow: MyListShow?

  var body: some View {
    List {
      Section {
        ForEach(animeList, id: \.id) { show in
          Button(action: {
            selectedShow = .init(id: show.id, name: show.name.ru, totalEpisodes: show.progress.total)
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
        Text(status.title)
      }
    }
    .sheet(
      item: $selectedShow,
      content: { show in
        MyListEditView(
          show: show
        )
      }
    )
  }
}
