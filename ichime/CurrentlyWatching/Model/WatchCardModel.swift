//
//  WatchCardModel.swift
//  ichime
//
//  Created by Nikita Nafranets on 28.01.2024.
//

import Foundation
import ScraperAPI

extension ScraperAPI.Types.WatchShow.UpdateType {
    var displayName: String {
        let formatedDate: String
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        formatedDate = formatter.string(from: date)

        switch self {
        case .plan:
            return String(localized: "В планах с \(formatedDate)")
        case .release:
            return String(localized: "Вышло \(formatedDate)")
        case .update:
            return String(localized: "Смотрели \(formatedDate)")
        }
    }
}

public extension ScraperAPI.Types.Episode {
    var displayName: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        switch type {
        case .Movie:
            return "Фильм"
        case let .TV(episode):
            return String(localized: "\(formatter.string(for: episode)!) серия")
        case let .ONA(episode):
            return String(localized: "ONA \(formatter.string(for: episode)!) серия")
        case let .OVA(episode):
            return String(localized: "OVA \(formatter.string(for: episode)!) серия")
        }
    }
}

struct WatchCardModel: Equatable, Identifiable, Hashable {
    static func == (lhs: WatchCardModel, rhs: WatchCardModel) -> Bool {
        lhs.id == rhs.id
    }

    let id: Int
    let name: ScraperAPI.Types.Name
    let image: URL
    let title: String
    let sideText: String
    let data: WatchData

    struct WatchData: Hashable {
        let episode: Int
        let title: String
        let translation: Int?
    }

    init(id: Int, image: URL, name: ScraperAPI.Types.Name, title: String, sideText: String, data watchData: WatchData) {
        self.id = id
        self.name = name
        self.image = image
        self.title = title
        self.sideText = sideText
        data = watchData
    }

    init(from show: ScraperAPI.Types.WatchShow) {
        self.init(
            id: show.episode.id,
            image: show.imageURL,
            name: show.name,
            title: show.episode.displayName,
            sideText: show.update.displayName,
            data: .init(episode: show.episode.id, title: show.episode.displayName, translation: nil)
        )
    }

    init(from notification: ScraperAPI.Types.Notification) {
        self.init(
            id: notification.translation.id,
            image: notification.imageURL,
            name: notification.name,
            title: notification.episode.displayName,
            sideText: notification.translation.type,
            data: .init(
                episode: notification.episode.id,
                title: notification.episode.displayName,
                translation: notification.translation.id
            )
        )
    }
}
