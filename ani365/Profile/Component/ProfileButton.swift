//
//  ProfileButton.swift
//  ani365
//
//  Created by p.flaks on 05.02.2024.
//

import CachedAsyncImage
import ScraperAPI
import SwiftUI

struct ProfileButton: View {
    @EnvironmentObject var scraperManager: ScraperClient

    @State private var user: ScraperAPI.Types.User?

    @State var profileSheetPresented = false

    var body: some View {
        Button(action: {
            profileSheetPresented.toggle()
        }, label: {
            if let user = user {
                CachedAsyncImage(
                    url: user.avatarURL,
                    transaction: .init(animation: .easeInOut),
                    content: { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.circle")
                        case let .success(image):
                            image.resizable()
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
            } else {
                Image(systemName: "person.circle")
            }
        })
        .onReceive(scraperManager.user) { user = $0 }
        .sheet(isPresented: $profileSheetPresented, content: {
            ProfileSheet()
        })
    }
}

#Preview {
    NavigationStack {
        Text("Profile Button Preview")
            .toolbar {
                ToolbarItem {
                    ProfileButton()
                        .environmentObject(ScraperClient(scraperClient: ServiceLocator.getScraperAPIClient()))
                }
            }
    }
}
