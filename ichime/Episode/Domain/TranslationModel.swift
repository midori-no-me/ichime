//
//  TranslationModel.swift
//  ichime
//
//  Created by p.flaks on 15.01.2024.
//

import Foundation
import Anime365ApiClient

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
            translationTeam: translation.authorsSummary == "" ? "???" : translation.authorsSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            websiteUrl: URL(string: translation.url)!,
            translatedToLanguage: translatedToLanguage,
            translationMethod: translationMethod,
            height: translation.height,
            sourceVideoQuality: sourceVideoQuality
        )
    }

    static func == (lhs: Translation, rhs: Translation) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    let id: Int
    let translationTeam: String
    let websiteUrl: URL
    let translatedToLanguage: TranslatedToLanguage
    let translationMethod: TranslationMethod
    let height: Int
    let sourceVideoQuality: SourceVideoQuality

    enum SourceVideoQuality {
        case tv
        case bd
        case other

        func getLocalizaedTranslation() -> String {
            switch self {
            case .tv:
                "TV"
            case .bd:
                "BD"
            case .other:
                "Качество неизвестно"
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

        func getLocalizaedTranslation() -> String {
            switch self {
            case .russianSubtitles:
                "Русские субтитры"
            case .russianVoiceOver:
                "Русская озвучка"
            case .englishSubtitles:
                "Английские субтитры"
            case .englishVoiceOver:
                "Английская озвучка"
            case .japanese:
                "Японский"
            case .other:
                "Прочее"
            }
        }
    }

    func getCompositeType() -> CompositeType {
        if self.translatedToLanguage == .russian && self.translationMethod == .subtitles {
            return .russianSubtitles
        }

        if self.translatedToLanguage == .russian && self.translationMethod == .voiceover {
            return .russianVoiceOver
        }

        if self.translatedToLanguage == .english && self.translationMethod == .subtitles {
            return .englishSubtitles
        }

        if self.translatedToLanguage == .english && self.translationMethod == .voiceover {
            return .englishVoiceOver
        }

        if self.translatedToLanguage == .japanese {
            return .japanese
        }

        return .other
    }
}
