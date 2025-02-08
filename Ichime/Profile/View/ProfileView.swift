import ScraperAPI
import SwiftUI

struct ProfileView: View {
  private var userManager: UserManager = ApplicationDependency.container.resolve()
  @StateObject private var baseUrlPreference: BaseUrlPreference = .init()

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
    if case let .isAuth(user) = userManager.state {
      List {
        Section {
          Label {
            Text(user.username)
              .font(.headline)
              .fontWeight(.bold)
              .padding()
          } icon: {
            Circle()
              .foregroundStyle(.regularMaterial)
              .overlay(
                AsyncImage(
                  url: user.avatarURL,
                  transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
                ) { phase in
                  switch phase {
                  case .empty:
                    Color.clear

                  case let .success(image):
                    image
                      .resizable()
                      .scaledToFill()
                  case .failure:
                    Color.clear

                  @unknown default:
                    Color.clear
                  }
                },
                alignment: .top
              )
              .clipShape(.circle)
              .frame(width: 128, height: 128)
          }

          Button("Выйти из аккаунта", role: .destructive) {
            self.userManager.dropAuth()
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
          Text("\(self.appName) \(self.appVersion) (\(self.buildNumber)) \(self.buildConfiguration)")
        }
      }
      .listStyle(.grouped)
    }
  }
}

#Preview {
  ProfileView()
}
