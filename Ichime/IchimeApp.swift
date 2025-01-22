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

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          VideoPlayerController.enableBackgroundMode()
        }
    }
    .modelContainer(self.container)
  }
}
