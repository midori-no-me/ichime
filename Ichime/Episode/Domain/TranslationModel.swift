//
//  TranslationModel.swift
//  ichime
//
//  Created by p.flaks on 15.01.2024.
//

import Anime365ApiClient
import Foundation

struct Translation: Hashable, Identifiable {
  static func createFromApiSeries(
    translation: Anime365ApiTranslation
  ) -> Translation {
    var sourceVideoQuality: SourceVideoQuality = .other

    switch translation.qualityType {
    case "tv":
      sourceVideoQuality = .tv
    case "bd":
      sourceVideoQuality = .bd
    default:
      sourceVideoQuality = .other
    }

    var translatedToLanguage: TranslatedToLanguage = .other

    switch translation.typeLang {
    case "ru":
      translatedToLanguage = .russian
    case "en":
      translatedToLanguage = .english
    case "ja":
      translatedToLanguage = .japanese
    default:
      translatedToLanguage = .other
    }

    var translationMethod: TranslationMethod = .other

    switch translation.typeKind {
    case "voice":
      translationMethod = .voiceover
    case "sub":
      translationMethod = .subtitles
    case "raw":
      translationMethod = .raw
    default:
      translationMethod = .other
    }

    return Translation(
      id: translation.id,
      translationTeam: translation.authorsSummary == ""
        ? "???"
        : translation.authorsSummary
          .trimmingCharacters(in: .whitespacesAndNewlines),
      websiteUrl: URL(string: translation.url)!,
      translatedToLanguage: translatedToLanguage,
      translationMethod: translationMethod,
      height: translation.height,
      sourceVideoQuality: sourceVideoQuality,
      translationUrl: translation.url
    )
  }

  static func == (lhs: Translation, rhs: Translation) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let id: Int
  let translationTeam: String
  let websiteUrl: URL
  let translatedToLanguage: TranslatedToLanguage
  let translationMethod: TranslationMethod
  let height: Int
  let sourceVideoQuality: SourceVideoQuality
  let translationUrl: String

  enum SourceVideoQuality {
    case tv
    case bd
    case other

    func getLocalizedTranslation() -> String {
      switch self {
      case .tv:
        String(localized: "TV")
      case .bd:
        String(localized: "BD")
      case .other:
        String(localized: "Качество неизвестно")
      }
    }
  }

  enum TranslatedToLanguage: Int, Comparable {
    case russian = 1
    case english = 2
    case japanese = 3
    case other = 4

    static func < (lhs: TranslatedToLanguage, rhs: TranslatedToLanguage) -> Bool {
      return lhs.rawValue < rhs.rawValue
    }
  }

  enum TranslationMethod: Int, Comparable {
    case subtitles = 1
    case voiceover = 2
    case raw = 3
    case other = 4

    static func < (lhs: TranslationMethod, rhs: TranslationMethod) -> Bool {
      return lhs.rawValue < rhs.rawValue
    }
  }

  enum CompositeType: Int, Comparable {
    case russianSubtitles = 1
    case russianVoiceOver = 2
    case englishSubtitles = 3
    case englishVoiceOver = 4
    case japanese = 5
    case other = 6

    static func < (lhs: CompositeType, rhs: CompositeType) -> Bool {
      return lhs.rawValue < rhs.rawValue
    }

    func getLocalizedTranslation() -> String {
      switch self {
      case .russianSubtitles:
        String(localized: "Русские субтитры")
      case .russianVoiceOver:
        String(localized: "Русская озвучка")
      case .englishSubtitles:
        String(localized: "Английские субтитры")
      case .englishVoiceOver:
        String(localized: "Английская озвучка")
      case .japanese:
        String(localized: "Японский")
      case .other:
        String(localized: "Прочее")
      }
    }

    var translationTypeForCookie: String {
      switch self {
      case .russianSubtitles:
        "subRu"
      case .russianVoiceOver:
        "voiceRu"
      case .englishSubtitles:
        "subEn"
      case .englishVoiceOver:
        "voiceEn"
      case .japanese:
        "raw"
      case .other:
        ""
      }
    }
  }

  func getCompositeType() -> CompositeType {
    if translatedToLanguage == .russian && translationMethod == .subtitles {
      return .russianSubtitles
    }

    if translatedToLanguage == .russian && translationMethod == .voiceover {
      return .russianVoiceOver
    }

    if translatedToLanguage == .english && translationMethod == .subtitles {
      return .englishSubtitles
    }

    if translatedToLanguage == .english && translationMethod == .voiceover {
      return .englishVoiceOver
    }

    if translatedToLanguage == .japanese {
      return .japanese
    }

    return .other
  }
}
