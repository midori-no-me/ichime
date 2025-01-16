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
        .task {
          await self.importDatabase()
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

  private func importDatabase() async {
    guard !self.isImporting else { return }
    self.isImporting = true

    do {
      // Запрос к API
      let url = URL(string: "https://db.dimensi.dev/api/latest")!
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(DbServerResponse.self, from: data)

      let lastUpdated = UserDefaults().string(forKey: "lastUpdated") ?? ""
      let lastTimestamp = Int(lastUpdated) ?? 0

      if lastTimestamp == response.date {
        self.isImporting = false
        return
      }

      let animeImporter = AnimeImporter(modelContainer: container)
      Task.detached(priority: .high) {
        do {
          let dbUrl = "https://db.dimensi.dev\(response.url)"
          async let result: () = animeImporter.importDatabase(from: dbUrl)
          for await progress in await animeImporter.currentProgress {
            await MainActor.run {
              self.progressText = progress
            }
          }
          try await result
          await MainActor.run {
            self.isImporting = false
            UserDefaults().set(response.date, forKey: "lastUpdated")
          }
        }
        catch {
          await MainActor.run {
            self.isImporting = false
          }
        }
      }
    }
    catch {
      self.isImporting = false
      print("Error fetching database info: \(error)")
    }
  }
}

struct DbServerResponse: Codable {
  let date: Int
  let url: String
}
