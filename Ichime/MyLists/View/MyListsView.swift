//
//  MyListsView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import ScraperAPI
import SwiftData
import SwiftUI

struct MyListsView: View {
  let status: AnimeWatchStatus
  @Query private var userAnimeList: [UserAnimeListModel]

  init(status: AnimeWatchStatus) {
    self.status = status
    let rawValue = status.rawValue
    self._userAnimeList = .init(filter: #Predicate<UserAnimeListModel> { $0.statusRaw == rawValue })
  }

  var body: some View {
    Group {
      if userAnimeList.isEmpty {
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("В этой категории пока нет аниме")
        }
        .focusable()
      }
      else {
        AnimeList(status: status, animeList: userAnimeList)
      }
    }
  }
}

#Preview {
  NavigationStack {
    MyListsView(status: .watching)
  }
}
