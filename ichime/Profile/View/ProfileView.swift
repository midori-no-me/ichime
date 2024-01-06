//
//  ProfileView.swift
//  ichime
//
//  Created by p.flaks on 29.01.2024.
//

import CachedAsyncImage
import ScraperAPI
import SwiftUI

struct ProfileView: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()
    
    var body: some View {
        Group {
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
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(.circle)
                    }

                    Section {
                        Button("Выйти из аккаунта", role: .destructive) {
                            userManager.dropAuth()
                        }
                    }
                }
            }
        }
        .navigationTitle("Ваш профиль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
