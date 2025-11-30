import SwiftUI

@Observable @MainActor
private final class ProfileViewModel {
  private let authenticationManager: AuthenticationManager

  init(
    authenticationManager: AuthenticationManager = ApplicationDependency.container.resolve()
  ) {
    self.authenticationManager = authenticationManager
  }

  func logout(currentUserStore: CurrentUserStore) async -> Void {
    await self.authenticationManager.logout(currentUserStore: currentUserStore)
  }
}

struct ProfileView: View {
  @Environment(\.currentUserStore) private var currentUserStore

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  @AppStorage(NavigationStyle.UserDefaultsKey.STYLE) private var navigationStyle: NavigationStyle = .DEFAULT_STYLE

  @AppStorage(OngoingsVisibilityOna.UserDefaultsKey.VISIBILITY) private var ongoingsVisibilityOna:
    OngoingsVisibilityOna = .DEFAULT_VISIBILITY
  @AppStorage(OngoingsVisibilityOld.UserDefaultsKey.VISIBILITY) private var ongoingsVisibilityOld:
    OngoingsVisibilityOld = .DEFAULT_VISIBILITY

  @AppStorage(TranslationsRussianSubtitlesVisibility.UserDefaultsKey.VISIBILITY) private
    var translationsRussianSubtitlesVisibility: TranslationsRussianSubtitlesVisibility = .DEFAULT_VISIBILITY
  @AppStorage(TranslationsRussianVoiceoverVisibility.UserDefaultsKey.VISIBILITY) private
    var translationsRussianVoiceoverVisibility: TranslationsRussianVoiceoverVisibility = .DEFAULT_VISIBILITY
  @AppStorage(TranslationsEnglishSubtitlesVisibility.UserDefaultsKey.VISIBILITY) private
    var translationsEnglishSubtitlesVisibility: TranslationsEnglishSubtitlesVisibility = .DEFAULT_VISIBILITY
  @AppStorage(TranslationsEnglishVoiceoverVisibility.UserDefaultsKey.VISIBILITY) private
    var translationsEnglishVoiceoverVisibility: TranslationsEnglishVoiceoverVisibility = .DEFAULT_VISIBILITY
  @AppStorage(TranslationsJapaneseVisibility.UserDefaultsKey.VISIBILITY) private var translationsJapaneseVisibility:
    TranslationsJapaneseVisibility = .DEFAULT_VISIBILITY
  @AppStorage(TranslationsOtherVisibility.UserDefaultsKey.VISIBILITY) private var translationsOtherVisibility:
    TranslationsOtherVisibility = .DEFAULT_VISIBILITY

  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.WATCHING) private var animeListEntriesCountWatching: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.COMPLETED) private var animeListEntriesCountCompleted: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.ON_HOLD) private var animeListEntriesCountOnHold: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.DROPPED) private var animeListEntriesCountDropped: Int = 0
  @AppStorage(AnimeListEntriesCount.UserDefaultsKey.PLANNED) private var animeListEntriesCountPlanned: Int = 0
  @AppStorage(RevealHiddenAnime365Domains.UserDefaultsKey.VISIBILITY) private var revealHiddenAnime365Domains: Bool =
    false

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
      if let currentUser = self.currentUserStore.user {
        Section("Мой список") {
          NavigationLink(destination: AnimeListView(userId: currentUser.id, animeListCategory: .watching)) {
            HStack {
              Text(AnimeListCategory.watching.label)

              if self.animeListEntriesCountWatching > 0 {
                Spacer()

                Text(self.animeListEntriesCountWatching.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: currentUser.id, animeListCategory: .completed)) {
            HStack {
              Text(AnimeListCategory.completed.label)

              if self.animeListEntriesCountCompleted > 0 {
                Spacer()

                Text(self.animeListEntriesCountCompleted.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: currentUser.id, animeListCategory: .onHold)) {
            HStack {
              Text(AnimeListCategory.onHold.label)

              if self.animeListEntriesCountOnHold > 0 {
                Spacer()

                Text(self.animeListEntriesCountOnHold.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: currentUser.id, animeListCategory: .dropped)) {
            HStack {
              Text(AnimeListCategory.dropped.label)

              if self.animeListEntriesCountDropped > 0 {
                Spacer()

                Text(self.animeListEntriesCountDropped.formatted())
                  .foregroundStyle(.secondary)
              }
            }
          }

          NavigationLink(destination: AnimeListView(userId: currentUser.id, animeListCategory: .planned)) {
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
        if self.currentUserStore.user != nil {
          Button("Выйти из аккаунта", role: .destructive) {
            Task {
              await self.viewModel.logout(currentUserStore: self.currentUserStore)
            }
          }
        }
        else {
          Button("Войти") {
            self.showAuthenticationSheet = true
          }
          .fullScreenCover(isPresented: self.$showAuthenticationSheet) {
            NavigationStack {
              AuthenticationSheet(onSuccessfulAuth: nil)
            }
            .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
          }
        }
      }

      Section {
        Picker("Навигация", selection: self.$navigationStyle) {
          ForEach(NavigationStyle.allCases, id: \.self) { navigationStyleType in
            Text(navigationStyleType.name)
          }
        }
        .pickerStyle(.navigationLink)

        if UIApplication.shared.supportsAlternateIcons {
          Picker("Иконка приложения", selection: self.$currentAppIcon) {
            ForEach(AppIcon.allCases.filter({ self.revealHiddenAnime365Domains ? true : $0 != .hentai365 }), id: \.self)
            { appIcon in
              Text(appIcon.name)
            }
          }
          .pickerStyle(.navigationLink)
          .onChange(of: self.currentAppIcon) { _, newValue in
            UIApplication.shared.setAlternateIconName(newValue.systemIdentifier)
          }
        }

        Picker("Адрес сайта", selection: self.$anime365BaseURL) {
          ForEach(
            self.revealHiddenAnime365Domains
              ? Anime365BaseURL.ALL_KNOWN_ANIME_365_AND_HENTAI_365_BASE_URLS
              : Anime365BaseURL.ALL_KNOWN_ANIME_365_BASE_URLS,
            id: \.self
          ) { anime365BaseURL in
            Text(anime365BaseURL.host()!)
          }
        }
        .pickerStyle(.navigationLink)
        .contextMenu(menuItems: {
          if self.revealHiddenAnime365Domains {
            Button("Скрыть скрытые домены", systemImage: "eye.slash") {
              self.revealHiddenAnime365Domains = false
            }
          }
          else {
            Button("Показать скрытые домены", systemImage: "eye") {
              self.revealHiddenAnime365Domains = true
            }
          }

        })
      } header: {
        Text("Настройки приложения")
      } footer: {
        Text(
          "Если приложение работает некорректно, попробуйте поменять адрес сайта. Может потребоваться повторная авторизация."
        )
      }

      Section {
        Picker("ONA в списке онгоингов", selection: self.$ongoingsVisibilityOna) {
          ForEach(OngoingsVisibilityOna.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Старые онгоинги", selection: self.$ongoingsVisibilityOld) {
          ForEach(OngoingsVisibilityOld.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)
      } header: {
        Text("Онгоинги")
      }

      Section {
        Picker("Русские субтитры", selection: self.$translationsRussianSubtitlesVisibility) {
          ForEach(TranslationsRussianSubtitlesVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Русская озвучка", selection: self.$translationsRussianVoiceoverVisibility) {
          ForEach(TranslationsRussianVoiceoverVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Английские субтитры", selection: self.$translationsEnglishSubtitlesVisibility) {
          ForEach(TranslationsEnglishSubtitlesVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Английская озвучка", selection: self.$translationsEnglishVoiceoverVisibility) {
          ForEach(TranslationsEnglishVoiceoverVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Японский", selection: self.$translationsJapaneseVisibility) {
          ForEach(TranslationsJapaneseVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)

        Picker("Прочее", selection: self.$translationsOtherVisibility) {
          ForEach(TranslationsOtherVisibility.allCases, id: \.self) { visibility in
            Text(visibility.name)
          }
        }
        .pickerStyle(.navigationLink)
      } header: {
        Text("Переводы")
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
              url: self.currentUserStore.user?.avatar,
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

        Text(self.currentUserStore.user?.name ?? "Гость")
          .font(.headline)
          .fontWeight(.bold)
      }
      .frame(width: 350 - 64)
    }
  }
}
