//
//  ShowFromCalendarView.swift
//  Ichime
//
//  Created by Flaks Petr on 24.11.2024.
//

import SwiftUI

struct ShowFromCalendarCard: View {
  let show: ShowFromCalendar

  var body: some View {
#if os(tvOS)
    Button(action: {}, label: {
      RawShowCard(
        metadataLineComponents: [
          "\(show.nextEpisodeNumber.formatted()) серия",
          formatTime(show.nextEpisodeReleaseDate)
        ],
        cover: show.posterUrl,
        primaryTitle: show.title.translated.japaneseRomaji,
        secondaryTitle: show.title.translated.russian
      )
    })
    .buttonStyle(.borderless)
#else
    RawShowCard(
      metadataLineComponents: [
        "\(show.nextEpisodeNumber.formatted()) серия",
        formatTime(show.nextEpisodeReleaseDate)
      ],
      cover: show.posterUrl,
      primaryTitle: show.title.translated.japaneseRomaji,
      secondaryTitle: show.title.translated.russian
    )
#endif
  }
}
