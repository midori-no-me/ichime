//
//  ContentViewWithSideBar.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.03.2024.
//

import SwiftUI
import ScraperAPI

enum Tabs: Equatable, Hashable, Identifiable {
    case home
    case currentlyWatching
    case notifications
    case profile
    case search
    case myLists(ScraperAPI.Types.ListCategoryType)
    var id: String {
        switch self {
        case .home: return "home"
        case .currentlyWatching: return "currentlyWatching"
        case .notifications: return "notifications"
        case .profile: return "profile"
        case .search: return "search"
        case .myLists(let category): return "myLists | \(category.rawValue)"
        }
    }
}

struct ContentViewWithTabView: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
    @State private var selectedTab: Tabs = .home
    
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

            Tab("Уведомления", systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge", value: .notifications) {
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
            Tab("Профиль", systemImage: "person.circle", value: .profile) {
                    NavigationStack {
                        ProfileSheet()
                    }
                }
            #endif

            Tab("Поиск", systemImage: "magnifyingglass", value: .search, role: .search) {
                NavigationStack {
                    SearchShowsView()
                }
            }

            TabSection("Мой список") {
                ForEach(ScraperAPI.Types.ListCategoryType.allCases, id: \.rawValue) { category in
                    Tab(category.rawValue, systemImage: category.imageInDropdown, value: Tabs.myLists(category)) {
                        NavigationStack {
                            MyListsView(categoryType: category)
                        }
                    }
                }
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
