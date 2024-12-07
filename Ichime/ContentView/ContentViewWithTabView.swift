//
//  ContentViewWithSideBar.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.03.2024.
//

import ScraperAPI
import SwiftData
import SwiftUI

struct ContentViewWithTabView: View {
  @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
  @Environment(\.modelContext) private var modelContext

  @State var viewModel: ShowListStatusModel = ApplicationDependency.container.resolve()

  var body: some View {
    TabView {
      Tab("Главная", systemImage: "play.house") {
        NavigationStack {
          HomeView()
        }
      }

      Tab("К просмотру", systemImage: "play.square.stack") {
        NavigationStack {
          CurrentlyWatchingView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Мой список", systemImage: "film.stack") {
        NavigationStack {
          MyListsSelectorView()
        }
      }

      Tab(
        "Уведомления",
        systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge"
      ) {
        NavigationStack {
          NotificationCenterView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Календарь", systemImage: "calendar") {
        NavigationStack {
          CalendarView()
        }
      }
      Tab("Профиль", systemImage: "person.circle") {
        NavigationStack {
          ProfileSheet()
        }
      }

      Tab("Поиск", systemImage: "magnifyingglass", role: .search) {
        NavigationStack {
          SearchShowsView()
        }
      }
    }
    .task {
      await viewModel.cacheCategories()
    }
    .tabViewStyle(.sidebarAdaptable)

  }
}

private struct SidebarProfileButton: View {
  private var userManager: UserManager = ApplicationDependency.container.resolve()

  @State var profileSheetPresented = false

  var body: some View {
    Button(
      action: {
        profileSheetPresented.toggle()
      },
      label: {
        if case let .isAuth(user) = userManager.state {
          HStack {
            AsyncImage(
              url: user.avatarURL,
              transaction: .init(animation: .easeInOut),
              content: { phase in
                switch phase {
                case .empty:
                  Image(systemName: "person.circle")
                case let .success(image):
                  image
                    .resizable()
                    .frame(width: 26, height: 26)
                    .clipShape(.circle)
                    .clipped()
                case .failure:
                  Image(systemName: "person.circle")
                @unknown default:
                  Image(systemName: "person.circle")
                }
              }
            )

            Text(user.username)
              .fontWeight(.semibold)
          }
        }
        else {
          HStack {
            Image(systemName: "person.circle")

            Text("Профиль")
              .fontWeight(.semibold)
          }
        }
      }
    )
    .buttonStyle(.plain)
    .sheet(
      isPresented: $profileSheetPresented,
      content: {
        ProfileSheet()
      }
    )
  }
}

// #Preview {
//    ContentViewWithSideBar()
// }
