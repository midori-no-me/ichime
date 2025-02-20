import SwiftUI

struct ShowFromCalendarCard: View {
  let show: ShowFromCalendar

  var body: some View {
    NavigationLink(destination: ShowByMyAnimeListIdView(myAnimeListId: self.show.id)) {
      RawShowCard(
        metadataLineComponents: [
          "\(self.show.nextEpisodeNumber.formatted(EpisodeNumberFormatter())) серия",
          formatTime(self.show.nextEpisodeReleaseDate),
        ],
        cover: self.show.posterUrl,
        primaryTitle: self.show.title.translated.japaneseRomaji,
        secondaryTitle: self.show.title.translated.russian
      )
    }
    .buttonStyle(.borderless)
  }
}
