//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation

public extension ScraperAPI.Types {
    struct Episode {
        public let id: Int
        public let type: EpisodeType

        init(id: Int, type: EpisodeType) {
            self.id = id
            self.type = type
        }

        init(id: Int, episodeText: String) {
            self.init(id: id, type: EpisodeType(from: episodeText))
        }

        public enum EpisodeType {
            case TV(episode: Double)
            case Movie
            case OVA(episode: Double)
            case ONA(episode: Double)

            init(from input: String) {
                // Паттерн для поиска типа эпизода и номера
                let pattern = #/^(OVA|Фильм|ONA)?\s?(\d+\.?\d?)?(?:\sсерия)?/#

                guard let match = input.firstMatch(of: pattern) else {
                    self = .TV(episode: 0)
                    return
                }

                let episodeNumber = Double(match.output.2 ?? "") ?? 0
                let typeString = match.output.1 ?? ""
                switch typeString.lowercased() {
                case "ova":
                    self = .OVA(episode: episodeNumber)
                case "фильм":
                    self = .Movie
                case "ona":
                    self = .ONA(episode: episodeNumber)
                case "tv":
                    fallthrough
                default:
                    // По умолчанию, если не удалось извлечь значения, возвращаем TV и 0
                    self = .TV(episode: episodeNumber)
                }
            }
        }
    }

    struct Name: Hashable {
        public let ru, romaji: String
        
        public init(ru: String, romaji: String) {
            self.ru = ru
            self.romaji = romaji
        }
    }
}
