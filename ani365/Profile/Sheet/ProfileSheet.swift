//
//  ProfileView.swift
//  ani365
//
//  Created by p.flaks on 29.01.2024.
//

import CachedAsyncImage
import ScraperAPI
import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject var scraperManager: ScraperClient
    @Environment(\.dismiss) private var dismiss
    @State private var user: ScraperAPI.Types.User?
    @StateObject var baseUrlPreference: BaseUrlPreference = .init()

    var body: some View {
        NavigationStack {
            if let user {
                List {
                    Label {
                        VStack {
                            Text(user.username)
                                .padding()
                        }
                    } icon: {
                        CachedAsyncImage(
                            url: user.avatarURL,
                            transaction: .init(animation: .easeInOut),
                            content: { phase in
                                switch phase {
                                case .empty:
                                    VStack {
                                        ProgressView()
                                    }
                                case let .success(image):
                                    image.resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .shadow(radius: 4)

                                case .failure:
                                    VStack {
                                        Image(systemName: "wifi.slash")
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        )
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(.circle)
                    }

                    Section {
                        Text(baseUrlPreference.url.host()!)
                    } header: {
                        Text("Адрес сайта")
                    } footer: {
                        Text("Этот адрес используется для работы приложения. Попробуйте выбрать другой адрес, если приложение работает некорректно. Для изменения адреса нужно выйти из аккаунта.")
                    }

                    Section {
                        Button("Выйти из аккаунта", role: .destructive) {
                            scraperManager.dropAuth()
                        }
                    }
                }
                .navigationTitle("Ваш профиль")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") {
                            self.dismiss()
                        }
                    }
                }
            }
        }
        .onReceive(scraperManager.user) { user = $0 }
    }
}

#Preview {
    ProfileSheet()
        .environmentObject(ScraperClient(scraperClient: ServiceLocator.getScraperAPIClient()))
}
