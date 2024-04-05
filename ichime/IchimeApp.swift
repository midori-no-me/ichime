//
//  IchimeApp.swift
//  Ichime
//
//  Created by p.flaks on 01.01.2024.
//
import AppMetricaCore
import DITranquillity
import ScraperAPI
import SwiftUI

@main
struct IchimeApp: App {
    @Environment(\.scenePhase) private var phase

    init() {
        let configuration = AppMetricaConfiguration(apiKey: "f17336dc-d959-4e4e-a103-b2c7a31433d1")
        AppMetrica.activate(with: configuration!)
    }

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
    }
}
