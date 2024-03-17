//
//  ContentView.swift
//  IchimeTV
//
//  Created by p.flaks on 16.03.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentViewWithTabBar()
    }
}

struct ContentViewWithTabBar: View {
    var body: some View {
        TabView {
            NavigationStack {
                OngoingsView()
            }
            .tabItem {
                Text("Онгоинги")
            }

            NavigationStack {
                Text("Я смотрю")
            }
            .tabItem {
                Text("Я смотрю")
            }

            NavigationStack {
                Text("Мой список")
            }
            .tabItem {
                Text("Мой список")
            }

            NavigationStack {
                Text("Профиль")
            }
            .tabItem {
                Text("Профиль")
            }

            NavigationStack {
                Text("Поиск")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

#Preview {
    ContentView()
}
