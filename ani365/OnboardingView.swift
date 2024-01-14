//
//  OnboardingView.swift
//  ani365
//
//  Created by p.flaks on 14.01.2024.
//

import Anime365Scraper
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var scraperManager: Anime365ScraperManager

    var body: some View {
        Group {
            Button(scraperManager.user != nil ? "is auth" : "no auth") {
                Task {
                    do {
                        let user = try await scraperManager.startAuth()
                        print(user)
                    } catch {
                        print("some error", error.localizedDescription)
                    }
                }
            }

        }.onAppear {
            print(scraperManager.user ?? "no user")
        }
    }
}

#Preview {
    AppPreview {
        OnboardingView()
    }
}

struct AppPreview<Content: View>: View {
    @ObservedObject var scraperAuthViewManager: Anime365ScraperAuthViewManager
    @ObservedObject var scraperManager: Anime365ScraperManager
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        let auth = Anime365ScraperAuthViewManager()
        let scraper = Anime365ScraperManager(authViewManager: auth)
        self.scraperAuthViewManager = auth
        self.scraperManager = scraper
        self.content = content
    }

    var body: some View {
        content()
            .fullScreenCover(isPresented: $scraperAuthViewManager.isNeedAuth) {
                Anime365ScraperAuth {
                    scraperAuthViewManager.isNeedAuth = false
                }
            }.environmentObject(scraperManager)
    }
}
