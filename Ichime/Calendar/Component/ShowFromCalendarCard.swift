import SwiftUI

struct ShowFromCalendarCard: View {
  let show: ShowFromCalendar

  var body: some View {
    Button(
      action: {},
      label: {
        RawShowCard(
          metadataLineComponents: [
            "\(self.show.nextEpisodeNumber.formatted()) серия",
            formatTime(self.show.nextEpisodeReleaseDate),
          ],
          cover: self.show.posterUrl,
          primaryTitle: self.show.title.translated.japaneseRomaji,
          secondaryTitle: self.show.title.translated.russian
        )
      }
    )
    .buttonStyle(.borderless)

  }
}
