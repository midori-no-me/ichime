//
//  ProfileView.swift
//  ichime
//
//  Created by p.flaks on 29.01.2024.
//

import CachedAsyncImage
import ScraperAPI
import SwiftUI

struct ProfileSheet: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()
    @Environment(\.dismiss) private var dismiss
    @StateObject var baseUrlPreference: BaseUrlPreference = .init()

    var body: some View {
        NavigationStack {
            if case let .isAuth(user) = userManager.state {
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
                        #if !os(tvOS)
                            .background(Color(UIColor.secondarySystemBackground))
                        #endif
                            .clipShape(.circle)
                    }

                    Section {
                        Text(baseUrlPreference.url.host()!)
                    } header: {
                        Text("Адрес сайта")
                    } footer: {
                        Text(
                            "Этот адрес используется для работы приложения. Попробуйте выбрать другой адрес, если приложение работает некорректно. Для изменения адреса нужно выйти из аккаунта."
                        )
                    }

                    Section {
                        Button("Выйти из аккаунта", role: .destructive) {
                            userManager.dropAuth()
                        }
                    }
                }
                #if os(tvOS)
                .listStyle(.grouped)
                #endif
                .navigationTitle("Ваш профиль")
                #if !os(tvOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Закрыть") {
                                self.dismiss()
                            }
                        }
                    }
                #endif
            }
        }
    }
}

#Preview {
    ProfileSheet()
}
