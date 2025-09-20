import SwiftUI

@Observable
private class ProfileViewModel {
  private let authenticationManager: AuthenticationManager

  init(
    authenticationManager: AuthenticationManager = ApplicationDependency.container.resolve()
  ) {
    self.authenticationManager = authenticationManager
  }

  func logout() async -> Void {
    await self.authenticationManager.logout()
  }
}

struct ProfileView: View {
  @AppStorage(CurrentUserInfo.UserDefaultsKey.ID) private var userId: Int?
  @AppStorage(CurrentUserInfo.UserDefaultsKey.NAME) private var userName: String?
  @AppStorage(CurrentUserInfo.UserDefaultsKey.AVATAR_URL_PATH) private var userAvatarURLPath: String?

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  @AppStorage(NavigationStyle.UserDefaultsKey.STYLE) private var navigationStyle: NavigationStyle = NavigationStyle
    .DEFAULT_STYLE

  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.WATCHING) private var animeListEntriesCountWatching: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.COMPLETED) private var animeListEntriesCountCompleted: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.ON_HOLD) private var animeListEntriesCountOnHold: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.DROPPED) private var animeListEntriesCountDropped: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.PLANNED) private var animeListEntriesCountPlanned: Int = 0

  @State private var viewModel: ProfileViewModel = .init()
  @State private var showAuthenticationSheet: Bool = false
  @State private var currentAppIcon: AppIcon = .create(fromSystemIdentifier: UIApplication.shared.alternateIconName)

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
    List {
      if let userId {
        Section("Мой список") {
          NavigationLink(destination: AnimeListView(userId: userId, animeListCategory: .watching)) {
            HStack {
              Text(AnimeListCategory.watching.label)

              if self.animeListEntriesCountWatching > 0 {
                Spacer()

                Text(self.animeListEntriesCountWatching.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: userId, animeListCategory: .completed)) {
            HStack {
              Text(AnimeListCategory.completed.label)

              if self.animeListEntriesCountCompleted > 0 {
                Spacer()

                Text(self.animeListEntriesCountCompleted.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: userId, animeListCategory: .onHold)) {
            HStack {
              Text(AnimeListCategory.onHold.label)

              if self.animeListEntriesCountOnHold > 0 {
                Spacer()

                Text(self.animeListEntriesCountOnHold.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: userId, animeListCategory: .dropped)) {
            HStack {
              Text(AnimeListCategory.dropped.label)

              if self.animeListEntriesCountDropped > 0 {
                Spacer()

                Text(self.animeListEntriesCountDropped.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: userId, animeListCategory: .planned)) {
            HStack {
              Text(AnimeListCategory.planned.label)

              if self.animeListEntriesCountPlanned > 0 {
                Spacer()

                Text(self.animeListEntriesCountPlanned.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
      }

      Section("Настройки аккаунта") {
        if userId != nil {
          Button("Выйти из аккаунта", role: .destructive) {
            Task {
              await self.viewModel.logout()
            }
          }
        }
        else {
          Button("Войти") {
            self.showAuthenticationSheet = true
          }
          .fullScreenCover(isPresented: self.$showAuthenticationSheet) {
            NavigationStack {
              AuthenticationSheet()
            }
            .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
          }
        }
      }

      Section {
        NavigationLink("Скрытые переводы", destination: HiddenTranslationsView())

        Picker("Навигация", selection: self.$navigationStyle) {
          ForEach(NavigationStyle.allCases, id: \.self) { navigationStyleType in
            Text(navigationStyleType.name)
          }
        }
        .pickerStyle(.navigationLink)

        if UIApplication.shared.supportsAlternateIcons {
          Picker("Иконка приложения", selection: self.$currentAppIcon) {
            ForEach(AppIcon.allCases, id: \.self) { appIcon in
              Text(appIcon.name)
            }
          }
          .pickerStyle(.navigationLink)
          .onChange(of: self.currentAppIcon) { _, newValue in
            UIApplication.shared.setAlternateIconName(newValue.systemIdentifier)
          }
        }

        Picker("Адрес сайта", selection: self.$anime365BaseURL) {
          ForEach(Anime365BaseURL.ALL_KNOWN_ANIME_365_BASE_URLS, id: \.self) { anime365BaseURL in
            Text(anime365BaseURL.host()!)
          }
        }
        .pickerStyle(.navigationLink)
        .onChange(of: self.anime365BaseURL) { oldValue, newValue in
          let sharedCookieStorage = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: ServiceLocator.appGroup
          )

          let cookiesForOldBaseURL = sharedCookieStorage.cookies(for: oldValue)

          if let cookiesForOldBaseURL {
            sharedCookieStorage.setCookies(cookiesForOldBaseURL, for: newValue, mainDocumentURL: newValue)
          }
        }
      } header: {
        Text("Настройки приложения")
      } footer: {
        Text("Если приложение работает некорректно, попробуйте поменять адрес сайта.")
      }

      Section {
      } footer: {
        Text("\(self.appName) \(self.appVersion) (\(self.buildNumber)) \(self.buildConfiguration)")
      }
    }
    .listStyle(.grouped)
    .safeAreaPadding(.leading, 350)
    .overlay(alignment: .topLeading) {
      VStack {
        Circle()
          .foregroundStyle(Color(UIColor.systemGray))
          .overlay(
            AsyncImage(
              url: self.userAvatarURLPath != nil ? self.anime365BaseURL.appending(path: self.userAvatarURLPath!) : nil,
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

        Text(self.userName ?? "Гость")
          .font(.headline)
          .fontWeight(.bold)
      }
      .frame(width: 350 - 64)
    }
  }
}
