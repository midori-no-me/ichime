import SwiftUI

struct ShowFromCalendarWithExactReleaseDateCard: View {
  let show: ShowFromCalendarWithExactReleaseDate

  var body: some View {
    NavigationLink(destination: ShowByMyAnimeListIdView(myAnimeListId: self.show.id)) {
      RawShowCard(
        metadataLineComponents: self.metadataLineComponents(),
        cover: self.show.posterUrl,
        primaryTitle: self.show.title.translated.japaneseRomaji,
        secondaryTitle: self.show.title.translated.russian
      )
    }
    .buttonStyle(.borderless)
  }

  private func metadataLineComponents() -> [String] {
    var components: [String] = []

    if let nextEpisodeNumber = show.nextEpisodeNumber {
      components.append("\(nextEpisodeNumber.formatted(EpisodeNumberFormatter())) серия")
    }

    components.append(formatTime(self.show.nextEpisodeReleaseDate))

    return components
  }
}
