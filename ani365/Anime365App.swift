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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scraperManager)
        }
    }
}
