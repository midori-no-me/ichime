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
      EpisodeFromCurrentlyWatchingListCardContextMenuView(
        episodeId: self.episode.episodeId,
        showId: self.episode.showId,
        showName: self.episode.showName
      )
    }
  }
}
