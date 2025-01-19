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
  @State private var isImporting = false
  @State private var progressText = "Импорт базы данных..."

  var body: some Scene {
    WindowGroup {
      ContentView()
        .overlay(alignment: .bottom) {
          if self.isImporting {
            ProgressView(self.progressText)
              .padding()
              .background(.ultraThinMaterial)
              .cornerRadius(10)
          }
        }
        .onAppear {
          VideoPlayerController.enableBackgroundMode()
          NotificationCounterWatcher.askBadgePermission()
        }
    }.onChange(of: self.phase) {
      switch self.phase {
      case .background:
        scheduleAppRefresh()
      default: break
      }
    }.backgroundTask(.appRefresh(ServiceLocator.permittedScheduleBGTaskName)) {
      await NotificationCounterWatcher.checkCounter()
    }
    .modelContainer(self.container)
  }
}

struct DbServerResponse: Codable {
  let date: Int
  let url: String
}
