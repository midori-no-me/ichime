//
//  ContentView.swift
//  ichime
//
//  Created by p.flaks on 05.01.2024.
//

import ScraperAPI
import SwiftUI

struct ContentView: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()

    var body: some View {
        Group {
            switch userManager.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await userManager.checkAuth()
                    }
                }
            case .loading:
                ProgressView()
            case .isAuth:
                #if os(iOS)
                    if UIDevice.userInterfaceIdiom == .phone {
                        ContentViewWithTabBar()

                    } else {
                        ContentViewWithSideBar()
                    }
                #elseif os(tvOS)
                    ContentViewWithTabBarTV()
                #else
                    ContentViewWithSideBar()
                #endif
            case .isAnonym:
                NavigationStack {
                    OnboardingView()
                }
            }
        }
    }
}

@ViewBuilder
func viewShow(show: WatchCardModel) -> some View {
    EpisodeTranslationsView(
        episodeId: show.data.episode,
        episodeTitle: show.data.title,
        preselectedTranslation: show.data.translation
    )
}

#Preview {
    ContentView()
}
