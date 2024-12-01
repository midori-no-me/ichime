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
    switch userManager.state {
    case .idle:
      Color.clear
    case .loading:
      ProgressView()
        #if os(tvOS)
          .focusable()
        #endif
    case .isAuth:
      ContentViewWithTabView()
    case .isAnonym:
      NavigationStack {
        OnboardingView()
      }
    }
  }
}

@ViewBuilder
func viewEpisodes(show: WatchCardModel) -> some View {
  EpisodeTranslationsView(
    episodeId: show.data.episode,
    episodeTitle: show.data.title
  )
}

#Preview {
  ContentView()
}
