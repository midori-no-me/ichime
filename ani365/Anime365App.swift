//
//  ani365App.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//
import DITranquillity
import ScraperAPI
import SwiftUI

@main
struct Anime365App: App {
    @StateObject var scraperManager: ScraperClient = .init(scraperClient: ServiceLocator.getScraperAPIClient())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scraperManager)
        }
    }
}
