//
//  NotificationCenterView.swift
//  ani365
//
//  Created by p.flaks on 20.01.2024.
//

import SwiftUI

struct NotificationCenterView: View {
    var body: some View {
        List {
            Section {
                Text("Уведомление 1")
                Text("Уведомление 2")
                Text("Уведомление 3")
            } header: {
                Text("Сегодня")
            }

            Section {
                Text("Уведомление 1")
                Text("Уведомление 2")
                Text("Уведомление 3")
            } header: {
                Text("Вчера")
            }
        }
        .toolbar {
            NavigationLink(destination: OnboardingView()) {
                Image(systemName: "person.circle")
            }
        }
        .navigationTitle("Уведомления")
    }
}

#Preview {
    NavigationStack {
        NotificationCenterView()
    }
}
