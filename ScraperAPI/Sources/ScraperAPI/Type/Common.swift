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
        public let episodeNumber: Double

        public enum EpisodeType: String {
            case TV
            case Movie
            case OVA
            case ONA
        }

        init(id: Int, type: EpisodeType, episodeNumber: Double) {
            self.id = id
            self.type = type
            self.episodeNumber = episodeNumber
        }

        init(id: Int, episodeText: String) {
            let episodeMeta = Self.extractEpisodeInfo(from: episodeText)
            self.init(id: id, type: episodeMeta.type, episodeNumber: episodeMeta.number)
        }

        private static func extractEpisodeInfo(from input: String) -> (type: EpisodeType, number: Double) {
            // Паттерн для поиска типа эпизода и номера
            let pattern = #/^(OVA|Фильм|ONA)?\s?(\d+\.?\d?)?(?:\sсерия)?/#

            if let match = input.firstMatch(of: pattern) {
                let typeString = match.output.1 ?? ""
                let type: EpisodeType
                switch typeString.lowercased() {
                case "ova":
                    type = .OVA
                case "фильм":
                    type = .Movie
                case "ona":
                    type = .ONA
                case "tv":
                    fallthrough
                default:
                    type = .TV
                }

                let episodeNumber = Double(match.output.2 ?? "") ?? 0
                return (type, episodeNumber)
            }

            // По умолчанию, если не удалось извлечь значения, возвращаем TV и 0
            return (.TV, 0)
        }
    }

    struct Name {
        public let ru, en: String
    }
}
