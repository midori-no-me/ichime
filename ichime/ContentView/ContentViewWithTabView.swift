//
//  ContentViewWithSideBar.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.03.2024.
//

import SwiftUI

struct ContentViewWithTabView: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

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

        Tab("Уведомления", systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge") {
          NavigationStack {
            NotificationCenterView()
              .navigationDestination(
                for: WatchCardModel.self,
                destination: { viewEpisodes(show: $0) }
              )
          }
        }
        #if !os(tvOS)
          .badge(notificationCounterWatcher.counter)
        #endif

        #if os(tvOS)
          Tab("Профиль", systemImage: "person.circle") {
            NavigationStack {
              ProfileSheet()
            }
          }
        #endif

        Tab("Поиск", systemImage: "magnifyingglass", role: .search) {
          NavigationStack {
            SearchShowsView()
          }
        }

        TabSection("Мой список") {
          Tab("Запланировано", systemImage: "hourglass.circle") {
            NavigationStack {
              Text("Запланировано")
            }
          }

//          Tab("Смотрю", systemImage: "eye.circle") {
//            NavigationStack {
//              Text("Смотрю")
//            }
//          }
//
//          Tab("Просмотрено", systemImage: "checkmark.circle") {
//            NavigationStack {
//              Text("Просмотрено")
//            }
//          }
//
//          Tab("Отложено", systemImage: "pause.circle") {
//            NavigationStack {
//              Text("Отложено")
//            }
//          }
//
//          Tab("Брошено", systemImage: "archivebox.circle") {
//            NavigationStack {
//              Text("Брошено")
//            }
//          }
        }
        #if !os(tvOS)
          .defaultVisibility(.hidden, for: .tabBar)
        #endif
      }
      .tabViewStyle(.sidebarAdaptable)
      #if !os(tvOS)
        .tabViewSidebarBottomBar {
          SidebarProfileButton()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
      #endif
    }
}

private struct SidebarProfileButton: View {
  private var userManager: UserManager = ApplicationDependency.container.resolve()

  @State var profileSheetPresented = false

  var body: some View {
    Button(action: {
      profileSheetPresented.toggle()
    }, label: {
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
      } else {
        HStack {
          Image(systemName: "person.circle")

          Text("Профиль")
            .fontWeight(.semibold)
        }
      }
    })
    .buttonStyle(.plain)
    .sheet(isPresented: $profileSheetPresented, content: {
      ProfileSheet()
    })
  }
}

// #Preview {
//    ContentViewWithSideBar()
// }
