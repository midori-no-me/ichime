//
//  ContentViewWithSideBar.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.03.2024.
//

import ScraperAPI
import SwiftData
import SwiftUI

enum Tabs: String {
  case home
  case currentlyWatching
  case myLists
  case notifications
  case calendar
  case profile
  case search
}

struct ContentViewWithTabView: View {
  @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
  @Environment(\.modelContext) private var modelContext
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

  @State var viewModel: ShowListStatusModel = ApplicationDependency.container.resolve()

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Главная", systemImage: "play.house", value: .home) {
        NavigationStack {
          HomeView()
        }
      }

      Tab("К просмотру", systemImage: "play.square.stack", value: .currentlyWatching) {
        NavigationStack {
          CurrentlyWatchingView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Мой список", systemImage: "film.stack", value: .myLists) {
        NavigationStack {
          MyListsSelectorView()
        }
      }

      Tab(
        "Уведомления",
        systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge",
        value: .notifications
      ) {
        NavigationStack {
          NotificationCenterView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Календарь", systemImage: "calendar", value: .calendar) {
        NavigationStack {
          CalendarView()
        }
      }
      Tab("Профиль", systemImage: "person.circle", value: .profile) {
        NavigationStack {
          ProfileSheet()
        }
      }

      Tab("Поиск", systemImage: "magnifyingglass", value: .search, role: .search) {
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
