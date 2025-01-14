//
//  ProfileView.swift
//  ichime
//
//  Created by p.flaks on 29.01.2024.
//

import ScraperAPI
import SwiftUI

struct ProfileSheet: View {
  private var userManager: UserManager = ApplicationDependency.container.resolve()
  @Environment(\.dismiss) private var dismiss
  @StateObject var baseUrlPreference: BaseUrlPreference = .init()

  private let appName =
    (Bundle.main.infoDictionary?["CFBundleDisplayName"]
    ?? Bundle.main
    .infoDictionary?[kCFBundleNameKey as String]) as? String ?? "???"
  private let appVersion =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "???"
  private let buildNumber =
    Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "???"

  #if DEBUG
    private let buildConfiguration = "Debug"
  #else
    private let buildConfiguration = "Release"
  #endif

  var body: some View {
    NavigationStack {
      if case let .isAuth(user) = userManager.state {
        List {
          Section {
            Label {
              VStack {
                Text(user.username)
                  .padding()
              }
            } icon: {
              AsyncImage(
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
              .clipShape(.circle)
            }

            Button("Выйти из аккаунта", role: .destructive) {
              userManager.dropAuth()
            }
          }

          if let host = baseUrlPreference.url.host() {
            Section {
              Link("Настройки приложения", destination: URL(string: UIApplication.openSettingsURLString)!)
            } footer: {
              Text(
                "Адрес сайта: \(host). Этот адрес используется для работы приложения. Попробуйте выбрать другой адрес, если приложение работает некорректно. Для изменения адреса нужно выйти из аккаунта."
              )
            }
          }

          Section {
          } footer: {
            Text("\(appName) \(appVersion) (\(buildNumber)) \(buildConfiguration)")
          }
        }
        .listStyle(.grouped)
      }
    }
  }
}

#Preview {
  ProfileSheet()
}
