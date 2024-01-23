//
//  ProfileView.swift
//  ani365
//
//  Created by p.flaks on 29.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var scraperManager: ScraperClient

    var body: some View {
        if let user = scraperManager.user {
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
                        scraperManager.dropAuth()
                    }
                }
            }
            .navigationTitle("Ваш профиль")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(ScraperClient(scraperClient: ServiceLocator.getScraperAPIClient()))
    }
}
