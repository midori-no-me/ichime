//
//  OnboardingView.swift
//  ani365
//
//  Created by p.flaks on 14.01.2024.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var scraperManager: Anime365ScraperManager
    
    var body: some View {
        Button("Auth") {
            Task {
                do {
                    let user = try await scraperManager.startAuth()
                    print(user)
                } catch {
                    print("some error", error.localizedDescription)
                }
            }
        }
        .onAppear {
            print(scraperManager.user!)
        }
    }
}

#Preview {
    OnboardingView()
}
