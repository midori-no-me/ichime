//
//  IchimeApp.swift
//  Ichime
//
//  Created by p.flaks on 01.01.2024.
//
import DITranquillity
import ScraperAPI
import SwiftUI

@main
struct IchimeApp: App {
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
        }.backgroundTask(.appRefresh(ServiceLocator.getPermittedScheduleBGTaskName)) {
            await NotificationCounterWatcher.checkCounter()
        }
    }
}
