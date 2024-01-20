//
//  MyListsView.swift
//  ani365
//
//  Created by p.flaks on 20.01.2024.
//

import SwiftUI

struct CurrentlyWatchingView: View {
    var body: some View {
        VStack {
            List {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Section {
                        NavigationLink(destination: NotificationCenterView()) {
                            Label("Уведомления", systemImage: "bell")
                                .badge(5)
                        }
                    }
                }

                Section {
                    Text("Сериал 1")
                    Text("Сериал 2")
                    Text("Сериал 3")
                } header: {
                    Text("Серии к просмотру")
                }
            }
        }
        .toolbar {
            NavigationLink(destination: OnboardingView()) {
                Image(systemName: "person.circle")
            }
        }
        .navigationTitle("Я смотрю")
    }
}

#Preview {
    NavigationStack {
        CurrentlyWatchingView()
    }
}
