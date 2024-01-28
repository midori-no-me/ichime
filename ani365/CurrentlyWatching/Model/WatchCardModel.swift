//
//  WatchCardModel.swift
//  ani365
//
//  Created by Nikita Nafranets on 28.01.2024.
//

import Foundation
import ScraperAPI

struct WatchCardModel: Equatable, Identifiable {
    static func == (lhs: WatchCardModel, rhs: WatchCardModel) -> Bool {
        lhs.id == rhs.id
    }

    let id: Int
    let name: ScraperAPI.Types.Name
    let image: URL
    let title: String
    let sideText: String

    init(id: Int, image: URL, name: ScraperAPI.Types.Name, title: String, sideText: String) {
        self.id = id
        self.name = name
        self.image = image
        self.title = title
        self.sideText = sideText
    }

    init(from show: ScraperAPI.Types.WatchShow) {
        self.init(
            id: show.id,
            image: show.imageURL,
            name: show.name,
            title: show.episode.displayName,
            sideText: show.update.displayName
        )
    }

    init(from notification: ScraperAPI.Types.Notification) {
        self.init(
            id: notification.translation.id,
            image: notification.imageURL,
            name: notification.name,
            title: notification.episode.displayName,
            sideText: notification.translation.type
        )
    }
}
