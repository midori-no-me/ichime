//
//  ani365App.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//

import Anime365Scraper
import SwiftUI

@main
struct Anime365App: App {
    @StateObject var scraperManager: Anime365ScraperManager = .init()
    @StateObject var manager: VideoPlayerController = .init()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(scraperManager)
                    .environmentObject(manager)
                if manager.loading {
                    Color.clear
                    ProgressView("Загружаем...")
                }
                if let player = manager.player {
                    PlayerView(showFullScreen: manager.isPlay, player: player)
                        .frame(width: 0, height: 0)
                }
            }.onReceive(manager.$isPlay) { isPlay in
                // This is called when there is a orientation change
                // You can set back the orientation to the one you like even
                // if the user has turned around their phone to use another
                // orientation.
                if isPlay == true {
                    changeOrientation(to: .landscapeLeft)
                } else {
                    changeOrientation(to: .portrait)
                }
            }
//            GeometryReader { proxy in
//                ZStack {
//                    ContentView()
//                        .environmentObject(scraperManager)
//                        .environmentObject(manager)
//                    if manager.loading {
//                        Color.clear
//                        ProgressView("Загружаем...")
//                    }
//                    if let player = manager.player {
//                        PlayerView(showFullScreen: manager.isPlay, player: player)
//                            .offset(x: 0, y: proxy.size.height - 1)
//                    }
//                }
//            }
//            .ignoresSafeArea()
        }
    }

    func changeOrientation(to orientation: UIInterfaceOrientationMask) {
        // tell the app to change the orientation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        print("Changing to", orientation)
    }
}
