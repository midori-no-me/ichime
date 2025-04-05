import SwiftUI

struct EpisodeFromCurrentlyWatchingListCard: View {
  let episode: EpisodeFromCurrentlyWatchingList

  var body: some View {
    NavigationLink(destination: EpisodeTranslationListView(episodeId: self.episode.episodeId)) {
      RawShowCard(
        metadataLineComponents: [self.episode.episodeTitle, self.episode.updateNote],
        cover: self.episode.coverUrl,
        primaryTitle: self.episode.showName.getRomajiOrFullName(),
        secondaryTitle: self.episode.showName.getRussian()
      )
    }
    .buttonStyle(.borderless)
    .contextMenu {
      NavigationLink(destination: ShowView(showId: self.episode.showId)) {
        Label("Перейти к тайтлу", systemImage: "info.circle")
      }
    }
  }
}
