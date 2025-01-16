import Foundation

extension Show {
  init(from dbAnime: DbAnime) {
    id = dbAnime.id
    title = Show.Title(
      full: dbAnime.titles.ru,
      translated: Show.Title.TranslatedTitles(
        russian: dbAnime.titles.ru,
        english: dbAnime.titles.en,
        japanese: dbAnime.titles.ja,
        japaneseRomaji: dbAnime.titles.romaji
      )
    )
    descriptions = dbAnime.descriptions.map { description in
      Show.Description(
        text: description.value,
        source: description.source
      )
    }
    posterUrl = URL(string: dbAnime.poster.anime365.original)
    websiteUrl = getWebsiteUrlByShowId(showId: dbAnime.id)
    if let score = Float(dbAnime.score) {
      self.score = score <= 0 ? nil : score
    }
    else {
      score = nil
    }
    airingSeason = AiringSeason(
      fromTranslatedString: dbAnime.season
    )
    numberOfEpisodes = dbAnime.numberOfEpisodes <= 0 ? nil : dbAnime.numberOfEpisodes
    typeTitle = dbAnime.typeTitle
    broadcastType = .createFromApiType(apiType: dbAnime.type)
    genres = dbAnime.genres.map { genre in
      Show.Genre(
        id: genre.id,
        title: genre.title
      )
    }
    isOngoing = dbAnime.isAiring == 1
    episodePreviews = dbAnime.episodes.map { episode in
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
