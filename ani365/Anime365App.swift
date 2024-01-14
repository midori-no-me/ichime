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
    @ObservedObject var scraperAuthViewManager: Anime365ScraperAuthViewManager
    @ObservedObject var scraperManager: Anime365ScraperManager

    init() {
        let auth = Anime365ScraperAuthViewManager()
        let scraper = Anime365ScraperManager(authViewManager: auth)
        self.scraperAuthViewManager = auth
        self.scraperManager = scraper
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: $scraperAuthViewManager.isNeedAuth) {
                    Anime365ScraperAuth {
                        scraperAuthViewManager.isNeedAuth = false
                    }
                }.environmentObject(scraperManager)
        }
    }
}
