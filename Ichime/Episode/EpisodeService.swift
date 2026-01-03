import Anime365Kit
import Foundation
import JikanApiClient
import OrderedCollections

struct EpisodeService {
  private let anime365KitFactory: Anime365KitFactory
  private let jikanApiClient: JikanApiClient.ApiClient

  init(
    anime365KitFactory: Anime365KitFactory,
    jikanApiClient: JikanApiClient.ApiClient
  ) {
    self.anime365KitFactory = anime365KitFactory
    self.jikanApiClient = jikanApiClient
  }

  /// Форматирует неизвестное количество эпизодов
  ///
  /// Полезно для ситуаций, когда общее количество эпизодов у сериала не известно.
  /// Принимает число (количество уже вышедших или уже просмотренных эпизодов) и возвращает количество вопросиков такой же длины.
  ///
  /// Примеры:
  ///
  /// - Если передать 5, то вернется  "??"
  /// - Если передать 55, то вернется  "??"
  /// - Если передать 555, то вернется  "???"
  /// - Если передать 5555, то вернется  "????"
  static func formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(_ airedEpisodes: Int) -> String {
    let charactersLength = String(airedEpisodes).count

    return String(repeating: "?", count: max(2, charactersLength))
  }

  private static func mapAnime365EpisodesToJikanEpisodes(
    anime365EpisodePreviews: [Anime365Kit.Episode],
    jikanEpisodes: [JikanApiClient.Episode],
  ) -> [EpisodeInfo] {
    var jikanEpisodeNumberToEpisode: [Int: JikanApiClient.Episode] = [:]

    for jikanEpisode in jikanEpisodes {
      let malId = jikanEpisode.mal_id

      jikanEpisodeNumberToEpisode[malId] = jikanEpisode
    }

    var episodeInfos: [EpisodeInfo] = []

    for anime365EpisodePreview in anime365EpisodePreviews {
      let anime365EpisodeNumber = Int(anime365EpisodePreview.episodeInt)

      var jikanEpisode: JikanApiClient.Episode? = nil

      if let anime365EpisodeNumber {
        jikanEpisode = jikanEpisodeNumberToEpisode[anime365EpisodeNumber]
      }

      let episodeInfo = EpisodeInfo.createValid(
        anime365EpisodePreview: anime365EpisodePreview,
        jikanEpisode: jikanEpisode,
      )

      guard let episodeInfo else {
        continue
      }

      episodeInfos.append(episodeInfo)
    }

    return episodeInfos
  }

  func getEpisodeList(
    showId: Int,
  ) async throws -> OrderedSet<EpisodeInfo> {
    let anime365Series = try await self.anime365KitFactory.createApiClient()
      .getSeries(seriesId: showId)

    var jikanEpisodes: [JikanApiClient.Episode] = []

    if anime365Series.numberOfEpisodes <= 100 {
      jikanEpisodes =
        (try? await self.jikanApiClient.getAnimeEpisodes(
          id: anime365Series.myAnimeListId,
          page: 1
        )) ?? []
    }

    let episodes = Self.mapAnime365EpisodesToJikanEpisodes(
      anime365EpisodePreviews: anime365Series.episodes ?? [],
      jikanEpisodes: jikanEpisodes,
    )

    return .init(episodes)
  }

  func getEpisodeTranslations(
    episodeId: Int
  ) async throws -> (episode: EpisodeInfo?, translations: [EpisodeTranslationInfo]) {
    let anime365Episode = try await anime365KitFactory.createApiClient().getEpisode(episodeId: episodeId)
    let anime365Series = try? await anime365KitFactory.createApiClient().getSeries(seriesId: anime365Episode.seriesId)

    var episode: EpisodeInfo?

    if let anime365Series {
      var jikanEpisode: JikanApiClient.Episode?

      if let anime365EpisodeNumber = Int(anime365Episode.episodeInt) {
        jikanEpisode = try? await self.jikanApiClient.getAnimeEpisodeById(
          animeId: anime365Series.myAnimeListId,
          episodeId: anime365EpisodeNumber
        )
      }

      episode = EpisodeInfo.createValid(
        anime365EpisodePreview: anime365Episode,
        jikanEpisode: jikanEpisode,
      )
    }

    var items: [EpisodeTranslationInfo] = []

    for anime365ApiTranslation in anime365Episode.translations {
      let translationInfo = EpisodeTranslationInfo.createValid(anime365ApiTranslation: anime365ApiTranslation)

      guard let translationInfo else {
        continue
      }

      items.append(translationInfo)
    }

    return (episode: episode, translations: items)
  }

  func filterAndGroupEpisodeTranslations(
    episodeTranslationInfos: [EpisodeTranslationInfo],
    skipFiltering: Bool
  ) -> [EpisodeTranslationGroup] {
    var groupTypeToEpisodeTranslationInfosDictionary: [EpisodeTranslationGroupType: [EpisodeTranslationInfo]] = [:]

    for episodeTranslationInfo in episodeTranslationInfos {
      if episodeTranslationInfo.translatedToLanguage == .russian {
        if episodeTranslationInfo.translationMethod == .subtitles {
          if !skipFiltering && TranslationsRussianSubtitlesVisibility.get() == .hide {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.russianSubtitles, default: []].append(episodeTranslationInfo)
        }

        if episodeTranslationInfo.translationMethod == .voiceover {
          if !skipFiltering && TranslationsRussianVoiceoverVisibility.get() == .hide {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.russianVoiceOver, default: []].append(episodeTranslationInfo)
        }
      }
      else if episodeTranslationInfo.translatedToLanguage == .english {
        if episodeTranslationInfo.translationMethod == .subtitles {
          if !skipFiltering && TranslationsEnglishSubtitlesVisibility.get() == .hide {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.englishSubtitles, default: []].append(episodeTranslationInfo)
        }

        if episodeTranslationInfo.translationMethod == .voiceover {
          if !skipFiltering && TranslationsEnglishVoiceoverVisibility.get() == .hide {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.englishVoiceOver, default: []].append(episodeTranslationInfo)
        }
      }
      else if episodeTranslationInfo.translatedToLanguage == .japanese {
        if !skipFiltering && TranslationsJapaneseVisibility.get() == .hide {
          continue
        }

        groupTypeToEpisodeTranslationInfosDictionary[.japanese, default: []].append(episodeTranslationInfo)
      }
      else if episodeTranslationInfo.translatedToLanguage == .other {
        if !skipFiltering && TranslationsOtherVisibility.get() == .hide {
          continue
        }

        groupTypeToEpisodeTranslationInfosDictionary[.other, default: []].append(episodeTranslationInfo)
      }
    }

    var groups: [EpisodeTranslationGroup] = []

    for (groupType, episodeTranslationInfos) in groupTypeToEpisodeTranslationInfosDictionary {
      groups.append(
        .init(
          groupType: groupType,
          episodeTranslationInfos: episodeTranslationInfos
        )
      )
    }

    groups.sort(by: { $0.groupType.priority > $1.groupType.priority })

    return groups
  }

  func getTranslationStreamingData(
    translationId: Int
  ) async throws -> EpisodeTranslationStreamingInfo {
    let anime365TranslationEmbed = try await anime365KitFactory.createApiClient().getTranslationEmbed(
      translationId: translationId
    )

    let episodeTranslationStreamingInfo = EpisodeTranslationStreamingInfo.createValid(
      anime365ApiTranslationEmbed: anime365TranslationEmbed,
      anime365ApiBaseUrl: await self.anime365KitFactory.baseURL()
    )

    return episodeTranslationStreamingInfo!
  }

  func getTranslationInfoForMarkingEpisodeAsWatchedAlert(
    translationId: Int
  ) async throws -> (String, String?, String?) {
    let anime365Translation = try await anime365KitFactory.createApiClient().getTranslation(
      translationId: translationId
    )

    return (
      anime365Translation.episode.episodeFull, anime365Translation.series.titles.romaji,
      anime365Translation.series.titles.ru
    )
  }

  func getRecentEpisodes(page: Int) async throws -> OrderedSet<RecentlyUploadedEpisode> {
    let episodes = try await self.anime365KitFactory
      .createWebClient()
      .getRecentEpisodes(page: page)

    return .init(
      episodes.map {
        .init(fromAnime365KitNewEpisode: $0)
      }
    )
  }
}
