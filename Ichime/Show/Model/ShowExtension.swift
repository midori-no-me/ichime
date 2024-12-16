//
//  Test.swift
//  Ichime
//
//  Created by Nafranets Nikita on 15.12.2024.
//

import Foundation

extension Show {
  init(from dbAnime: DbAnime) {
    self.id = dbAnime.id
    self.title = Show.Title(
      full: dbAnime.titles.ru,
      translated: Show.Title.TranslatedTitles(
        russian: dbAnime.titles.ru,
        english: dbAnime.titles.en,
        japanese: dbAnime.titles.ja,
        japaneseRomaji: dbAnime.titles.romaji
      )
    )
    self.descriptions = dbAnime.descriptions.map { description in
      Show.Description(
        text: description.value,
        source: description.source
      )
    }
    self.posterUrl = URL(string: dbAnime.poster.anime365.original)
    self.websiteUrl = getWebsiteUrlByShowId(showId: dbAnime.id)
    if let score = Float(dbAnime.score) {
      self.score = score <= 0 ? nil : score
    }
    else {
      self.score = nil
    }
    self.airingSeason = AiringSeason(
      fromTranslatedString: dbAnime.season
    )
    self.numberOfEpisodes = dbAnime.numberOfEpisodes <= 0 ? nil : dbAnime.numberOfEpisodes
    self.typeTitle = dbAnime.typeTitle
    self.broadcastType = .createFromApiType(apiType: dbAnime.type)
    self.genres = dbAnime.genres.map { genre in
      Show.Genre(
        id: genre.id,
        title: genre.title
      )
    }
    self.isOngoing = dbAnime.isAiring == 1
    self.episodePreviews = dbAnime.episodes.map { episode in
      let title = episode.titles?.en ?? (episode.title.isEmpty ? nil : episode.title)
      let uploadDate =
        episode
          .firstUploadedDateTime == "2000-01-01 00:00:00"
        ? nil : convertApiDateStringToDate(string: episode.firstUploadedDateTime)!
      return EpisodePreview(
        id: episode.id,
        title: title,
        typeAndNumber: "\(episode.number) серия",
        uploadDate: uploadDate,
        type: EpisodeType.createFromApiType(apiType: episode.type),
        episodeNumber: Float(episode.number),
        isUnderProcessing: episode.isFirstUploaded == 0
      )
    }
  }
}
