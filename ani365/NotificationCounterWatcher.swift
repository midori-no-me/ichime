//
//  NotificationCounterWatcher.swift
//  ani365
//
//  Created by Nikita Nafranets on 07.03.2024.
//

import Foundation
import ScraperAPI
import SwiftUI

class NotificationCounterWatcher: ObservableObject {
    static let storageKey = "notificationCount"

    @AppStorage("notificationCount") var counter = 0

    private let api: ScraperAPI.APIClient

    init() {
        api = ApplicationDependency.container.resolve()
    }

    func checkCounter() async {
        do {
            let counter = try await api.sendAPIRequest(ScraperAPI.Request.GetNotificationCount())
            await MainActor.run {
                self.counter = counter
            }
        } catch {}
    }
}
