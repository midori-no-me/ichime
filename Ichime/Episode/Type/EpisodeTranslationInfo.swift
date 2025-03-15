import Anime365ApiClient
import Foundation

struct EpisodeTranslationInfo: Identifiable {
  enum SourceVideoQuality {
    case tv
    case bd
    case other

    static func createFromAnime365ApiString(_ anime365ApiString: String) -> Self {
      switch anime365ApiString {
      case "tv":
        return .tv
      case "bd":
        return .bd
      default:
        return .other
      }
    }
  }

  enum TranslatedToLanguage {
    case russian
    case english
    case japanese
    case other

    static func createFromAnime365ApiString(_ anime365ApiString: String) -> Self {
      switch anime365ApiString {
      case "ru":
        return .russian
      case "en":
        return .english
      case "ja":
        return .japanese
      default:
        return .other
      }
    }
  }

  enum TranslationMethod {
    case subtitles
    case voiceover
    case raw
    case other

    static func createFromAnime365ApiString(_ anime365ApiString: String) -> Self {
      switch anime365ApiString {
      case "sub":
        return .subtitles
      case "voice", "voiceOth":
        return .voiceover
      case "raw":
        return .raw
      default:
        return .other
      }
    }
  }

  let id: Int
  let translationTeam: String
  let translatedToLanguage: TranslatedToLanguage
  let translationMethod: TranslationMethod
  let height: Int
  let sourceVideoQuality: SourceVideoQuality
  let isUnderProcessing: Bool

  static func createValid(
    anime365ApiTranslation: Anime365ApiClient.Translation
  ) -> Self? {
    if anime365ApiTranslation.height == 0 {
      return nil
    }

    let sourceVideoQuality = SourceVideoQuality.createFromAnime365ApiString(anime365ApiTranslation.qualityType)
    let translatedToLanguage = TranslatedToLanguage.createFromAnime365ApiString(anime365ApiTranslation.typeLang)
    let translationMethod = TranslationMethod.createFromAnime365ApiString(anime365ApiTranslation.typeKind)

    let activatedOnAnime365At =
      Anime365ApiClient.ApiDateDecoder.isEmptyDate(anime365ApiTranslation.activeDateTime)
      ? nil
      : anime365ApiTranslation.activeDateTime

    let addedToAnime365At =
      Anime365ApiClient.ApiDateDecoder.isEmptyDate(anime365ApiTranslation.addedDateTime)
      ? nil
      : anime365ApiTranslation.addedDateTime

    var addedTooLongAgo = true

    if let addedToAnime365At {
      addedTooLongAgo = Date.now.addingTimeInterval(60 * 60 * 24 * -1) > addedToAnime365At  // 1 day ago
    }

    if anime365ApiTranslation.isActive == 0 && addedTooLongAgo {
      return nil
    }

    var translationTeam = anime365ApiTranslation.authorsSummary
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if translationTeam.isEmpty {
      translationTeam = "???"
    }

    return Self(
      id: anime365ApiTranslation.id,
      translationTeam: translationTeam,
      translatedToLanguage: translatedToLanguage,
      translationMethod: translationMethod,
      height: anime365ApiTranslation.height,
      sourceVideoQuality: sourceVideoQuality,
      isUnderProcessing: anime365ApiTranslation.isActive == 0 && activatedOnAnime365At == nil
    )
  }
}
