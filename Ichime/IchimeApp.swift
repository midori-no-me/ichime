//
//  IchimeApp.swift
//  Ichime
//
//  Created by p.flaks on 01.01.2024.
//
import DITranquillity
import ScraperAPI
import SwiftData
import SwiftUI

@main
struct IchimeApp: App {
  let container: ModelContainer = ApplicationDependency.container.resolve()

  @Environment(\.scenePhase) private var phase

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          VideoPlayerController.enableBackgroundMode()
          NotificationCounterWatcher.askBadgePermission()
        }
    }.onChange(of: phase) {
      switch phase {
      case .background:
        scheduleAppRefresh()
      default: break
      }
    }.backgroundTask(.appRefresh(ServiceLocator.permittedScheduleBGTaskName)) {
      await NotificationCounterWatcher.checkCounter()
    }
    .modelContainer(container)
  }
}
