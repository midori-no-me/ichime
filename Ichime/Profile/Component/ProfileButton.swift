//
//  ProfileButton.swift
//  ichime
//
//  Created by p.flaks on 05.02.2024.
//

import ScraperAPI
import SwiftUI

struct ProfileButton: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()

    @State var profileSheetPresented = false

    var body: some View {
        Button(action: {
            profileSheetPresented.toggle()
        }, label: {
            if case let .isAuth(user) = userManager.state {
                AsyncImage(
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
                }
            }
    }
}
