import SwiftUI

struct EpisodeFromCurrentlyWatchingListCard: View {
  let episode: EpisodeFromCurrentlyWatchingList

  var body: some View {
    NavigationLink(destination: EpisodeTranslationListView(episodeId: self.episode.episodeId)) {
      RawShowCard(
        metadataLineComponents: [self.episode.episodeTitle, self.episode.updateNote],
        cover: self.episode.coverUrl,
        primaryTitle: self.romajiTitle(),
        secondaryTitle: self.russianTitle()
      )
    }
    .buttonStyle(.borderless)
    .contextMenu {
      NavigationLink(destination: ShowView(showId: self.episode.showId)) {
        Label("Перейти к тайтлу", systemImage: "info.circle")
      }
    }
  }

  private func romajiTitle() -> String {
    if let parsedShowName = self.episode.showName as? ParsedShowName {
      return parsedShowName.romaji
    }

    return self.episode.showName.getFullName()
  }

  private func russianTitle() -> String? {
    if let parsedShowName = self.episode.showName as? ParsedShowName {
      return parsedShowName.russian
    }

    return nil
  }
}
