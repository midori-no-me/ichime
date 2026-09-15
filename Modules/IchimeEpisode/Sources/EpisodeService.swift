import Anime365Kit
import Foundation
import IchimeAnime365
import IchimePreferences
import OrderedCollections

public struct EpisodeService: Sendable {
  // MARK: Properties

  private let anime365KitFactory: Anime365KitFactory

  // MARK: Lifecycle

  public init(anime365KitFactory: Anime365KitFactory) {
    self.anime365KitFactory = anime365KitFactory
  }

  // MARK: Static Functions

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
  public static func formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(_ airedEpisodes: Int) -> String {
    let charactersLength = String(airedEpisodes).count

    return String(repeating: "?", count: max(2, charactersLength))
  }

  // MARK: Functions

  public func getEpisodeList(
    showID: Int,
  ) async throws -> OrderedSet<EpisodeInfo> {
    let anime365Series = try await self.anime365KitFactory.createApiClient()
      .getSeries(seriesID: showID)

    let episodes = (anime365Series.episodes ?? []).compactMap(EpisodeInfo.createValid)

    return .init(episodes)
  }

  public func getEpisodeTranslations(
    episodeID: Int
  ) async throws -> (episode: EpisodeInfo?, translations: [EpisodeTranslationInfo]) {
    let anime365Episode = try await anime365KitFactory.createApiClient().getEpisode(episodeID: episodeID)
    let episode = EpisodeInfo.createValid(anime365EpisodePreview: anime365Episode)

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

  public func filterAndGroupEpisodeTranslations(
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

  public func getTranslationStreamingData(
    translationID: Int
  ) async throws -> EpisodeTranslationStreamingInfo {
    let anime365TranslationEmbed = try await anime365KitFactory.createApiClient().getTranslationEmbed(
      translationID: translationID
    )

    let episodeTranslationStreamingInfo = EpisodeTranslationStreamingInfo.createValid(
      anime365ApiTranslationEmbed: anime365TranslationEmbed,
      anime365ApiBaseURL: await self.anime365KitFactory.baseURL()
    )

    return episodeTranslationStreamingInfo!
  }

  public func getTranslationInfoForMarkingEpisodeAsWatchedAlert(
    translationID: Int
  ) async throws -> (String, String?, String?) {
    let anime365Translation = try await anime365KitFactory.createApiClient().getTranslation(
      translationID: translationID
    )

    return (
      anime365Translation.episode.episodeFull, anime365Translation.series.titles.romaji,
      anime365Translation.series.titles.ru
    )
  }

  public func getRecentEpisodes(page: Int) async throws -> OrderedSet<RecentlyUploadedEpisode> {
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
