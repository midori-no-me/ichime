import Anime365ApiClient
import Foundation
import JikanApiClient

struct EpisodeService {
  private let anime365ApiClient: Anime365ApiClient.ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient

  init(
    anime365ApiClient: Anime365ApiClient.ApiClient,
    jikanApiClient: JikanApiClient.ApiClient
  ) {
    self.anime365ApiClient = anime365ApiClient
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
    anime365EpisodePreviews: [Anime365ApiClient.Episode],
    jikanEpisodes: [JikanApiClient.Episode]
  ) -> [EpisodeInfo] {
    var jikanEpisodeNumberToEpisode: [Int: JikanApiClient.Episode] = [:]

    for jikanEpisode in jikanEpisodes {
      jikanEpisodeNumberToEpisode[jikanEpisode.mal_id] = jikanEpisode
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
        jikanEpisode: jikanEpisode
      )

      guard let episodeInfo else {
        continue
      }

      episodeInfos.append(episodeInfo)
    }

    return episodeInfos
  }

  func getEpisodeList(
    showId: Int
  ) async throws -> [EpisodeInfo] {
    let anime365Series = try await anime365ApiClient.getSeries(
      seriesId: showId
    )

    var jikanEpisodes: [JikanApiClient.Episode] = []

    // Jikan возвращает только 100 эпизодов за раз, поэтому пока не поддерживаем пагинацию
    if anime365Series.episodes?.count ?? 0 <= 100 {
      jikanEpisodes = (try? await self.jikanApiClient.getAnimeEpisodes(id: anime365Series.myAnimeListId)) ?? []
    }

    return Self.mapAnime365EpisodesToJikanEpisodes(
      anime365EpisodePreviews: anime365Series.episodes ?? [],
      jikanEpisodes: jikanEpisodes
    )
  }

  func getEpisodeTranslations(
    episodeId: Int
  ) async throws -> [EpisodeTranslationInfo] {
    let anime365Episode = try await anime365ApiClient.getEpisode(episodeId: episodeId)

    var items: [EpisodeTranslationInfo] = []

    for anime365ApiTranslation in anime365Episode.translations {
      let translationInfo = EpisodeTranslationInfo.createValid(anime365ApiTranslation: anime365ApiTranslation)

      guard let translationInfo else {
        continue
      }

      items.append(translationInfo)
    }

    return items
  }

  func filterAndGroupEpisodeTranslations(
    episodeTranslationInfos: [EpisodeTranslationInfo],
    hiddenTranslationsPreference: HiddenTranslationsPreference
  ) -> [EpisodeTranslationGroup] {
    var groupTypeToEpisodeTranslationInfosDictionary: [EpisodeTranslationGroupType: [EpisodeTranslationInfo]] = [:]

    for episodeTranslationInfo in episodeTranslationInfos {
      if episodeTranslationInfo.translatedToLanguage == .russian {
        if episodeTranslationInfo.translationMethod == .subtitles {
          if hiddenTranslationsPreference.hideRussianSubtitles {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.russianSubtitles, default: []].append(episodeTranslationInfo)
        }

        if episodeTranslationInfo.translationMethod == .voiceover {
          if hiddenTranslationsPreference.hideRussianVoiceover {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.russianVoiceOver, default: []].append(episodeTranslationInfo)
        }
      }
      else if episodeTranslationInfo.translatedToLanguage == .english {
        if episodeTranslationInfo.translationMethod == .subtitles {
          if hiddenTranslationsPreference.hideEnglishSubtitles {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.englishSubtitles, default: []].append(episodeTranslationInfo)
        }

        if episodeTranslationInfo.translationMethod == .voiceover {
          if hiddenTranslationsPreference.hideEnglishVoiceover {
            continue
          }

          groupTypeToEpisodeTranslationInfosDictionary[.englishVoiceOver, default: []].append(episodeTranslationInfo)
        }
      }
      else if episodeTranslationInfo.translatedToLanguage == .japanese {
        if hiddenTranslationsPreference.hideJapanese {
          continue
        }

        groupTypeToEpisodeTranslationInfosDictionary[.japanese, default: []].append(episodeTranslationInfo)
      }
      else if episodeTranslationInfo.translatedToLanguage == .other {
        if hiddenTranslationsPreference.hideOther {
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
    let anime365TranslationEmbed = try await anime365ApiClient.getTranslationEmbed(
      translationId: translationId
    )

    let episodeTranslationStreamingInfo = EpisodeTranslationStreamingInfo.createValid(
      anime365ApiTranslationEmbed: anime365TranslationEmbed,
      anime365ApiBaseUrl: self.anime365ApiClient.baseURL
    )

    return episodeTranslationStreamingInfo!
  }

  func getTranslationInfoForMarkingEpisodeAsWatchedAlert(
    translationId: Int
  ) async throws -> (String, String) {
    let anime365Translation = try await anime365ApiClient.getTranslation(
      translationId: translationId
    )

    return (anime365Translation.episode.episodeFull, anime365Translation.series.title)
  }
}
