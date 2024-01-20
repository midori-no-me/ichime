//
//  MyListsView.swift
//  ani365
//
//  Created by p.flaks on 20.01.2024.
//

import SwiftUI

struct MyListsView: View {
    var body: some View {
        List {
            Section {
                Text("Сериал 1")
                Text("Сериал 2")
                Text("Сериал 3")
            } header: {
                Text("Смотрю")
            }

            Section {
                Text("Сериал 1")
                Text("Сериал 2")
                Text("Сериал 3")
            } header: {
                Text("Запланировано")
            }

            Section {
                Text("Сериал 1")
                Text("Сериал 2")
                Text("Сериал 3")
            } header: {
                Text("Отложено")
            }

            Section {
                Text("Сериал 1")
                Text("Сериал 2")
                Text("Сериал 3")
            } header: {
                Text("Просмотрено")
            }

            Section {
                Text("Сериал 1")
                Text("Сериал 2")
                Text("Сериал 3")
            } header: {
                Text("Брошено")
            }
        }
        .toolbar {
            NavigationLink(destination: OnboardingView()) {
                Image(systemName: "person.circle")
            }
        }
        .navigationTitle("Мой список")
    }
}

#Preview {
    NavigationStack {
        MyListsView()
    }
}
