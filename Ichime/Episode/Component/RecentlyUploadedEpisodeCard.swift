import SwiftUI

struct RecentlyUploadedEpisodeCard: View {
  let episode: RecentlyUploadedEpisode

  var body: some View {
    NavigationLink(destination: EpisodeTranslationListView(episodeId: self.episode.episodeId)) {
      ShowCard(
        topChips: [self.episode.episodeTitle],
        bottomChips: [],
        cover: self.episode.coverUrl,
        primaryTitle: self.episode.showName.getRomajiOrFullName(),
        secondaryTitle: self.episode.showName.getRussian()
      )
    }
    .buttonStyle(.borderless)
    .contextMenu {
      NavigationLink(destination: ShowView(showId: self.episode.showId)) {
        Label(self.episode.showName.getRomajiOrFullName(), systemImage: "info.circle")

        if let russian = self.episode.showName.getRussian() {
          Text(russian)
        }
      }
    }
  }
}
