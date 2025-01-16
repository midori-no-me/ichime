import BackgroundTasks
import Foundation
import ScraperAPI
import SwiftUI
import UserNotifications

class NotificationCounterWatcher: ObservableObject {
  static let storageKey = "notificationCount"
  let logger = createLogger(category: String(describing: NotificationCounterWatcher.self))

  @AppStorage("notificationCount") var counter = 0
  @AppStorage("accessToBadge") var badgeIsAvailable = false

  private let api: ScraperAPI.APIClient

  init() {
    self.api = ApplicationDependency.container.resolve()
  }

  func checkCounter() async {
    do {
      let counter = try await api.sendAPIRequest(ScraperAPI.Request.GetNotificationCount())
      self.logger.notice("get counter \(counter)")
      await MainActor.run {
        self.counter = counter
      }
      if self.badgeIsAvailable {
        do {
          try await UNUserNotificationCenter.current().setBadgeCount(counter)
          self.logger.notice("set badge")
        }
        catch {
          print(error)
        }
      }
    }
    catch {}
  }

  static func checkCounter() async {
    await NotificationCounterWatcher().checkCounter()
  }

  static func askBadgePermission() {
    NotificationCounterWatcher().askBadgePermission()
  }

  func askBadgePermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: .badge) { granted, _ in
      self.badgeIsAvailable = granted
      if granted {
        self.logger.notice("Notification access granted.")
      }
      else {
        self.logger.notice("Notification access denied.")
      }
    }
  }
}

func scheduleAppRefresh() {
  let request = BGAppRefreshTaskRequest(identifier: ServiceLocator.permittedScheduleBGTaskName)
  request.earliestBeginDate = .now.addingTimeInterval(1 * 3600)
  try? BGTaskScheduler.shared.submit(request)
}
