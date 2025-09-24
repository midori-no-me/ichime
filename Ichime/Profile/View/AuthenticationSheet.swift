import SwiftUI

@Observable
private class AuthenticationSheetViewModel {
  var email: String = ""
  var password: String = ""

  var showInvalidCredentialsAlert: Bool = false
  var showUnexpectedErrorAlert: Bool = false

  private let authenticationManager: AuthenticationManager

  init(
    authenticationManager: AuthenticationManager = ApplicationDependency.container.resolve()
  ) {
    self.authenticationManager = authenticationManager
  }

  func performAuthentication() async -> Bool {
    do {
      try await self.authenticationManager.authenticate(
        email: self.email,
        password: self.password
      )
    }
    catch {
      switch error {
      case .invalidCredentials:
        self.showInvalidCredentialsAlert = true
      case .unknown:
        self.showUnexpectedErrorAlert = true
      }

      return false
    }

    return true
  }
}

struct AuthenticationSheet: View {
  private static let LEFT_SIDEBAR_WIDTH: CGFloat = 900
  private static let LEFT_SIDEBAR_RIGHT_MARGIN: CGFloat = 64
  private static let LEFT_SIDEBAR_ICON_CONTAINER_WIDTH: CGFloat = 48
  private static let LEFT_SIDEBAR_LIST_ITEM_PADDING: CGFloat = 16

  @State private var viewModel: AuthenticationSheetViewModel = .init()
  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL
  @Environment(\.dismiss) private var dismissSheet

  var body: some View {
    Form {
      Section {
        TextField("Почта", text: self.$viewModel.email, prompt: Text("Адрес электронной почты"))
          .keyboardType(.emailAddress)
          .listRowBackground(Color.clear)
          .listRowInsets(.init())

        SecureField("Пароль", text: self.$viewModel.password, prompt: Text("Пароль"))
          .listRowBackground(Color.clear)
          .listRowInsets(.init())
      }

      Section {
        Picker("Адрес сайта", selection: self.$anime365BaseURL) {
          ForEach(Anime365BaseURL.ALL_KNOWN_ANIME_365_BASE_URLS, id: \.self) { anime365BaseURL in
            Text(anime365BaseURL.host()!)
          }
        }
        .pickerStyle(.navigationLink)
      }

      Section {
        Button("Войти") {
          Task {
            if await self.viewModel.performAuthentication() {
              self.dismissSheet()
            }
          }
        }
      }
    }
    .alert(
      "Некорректный адрес электронной почты или пароль",
      isPresented: self.$viewModel.showInvalidCredentialsAlert,
      actions: {
        Button(role: .cancel) {
          self.viewModel.showInvalidCredentialsAlert = false
        }
      }
    )
    .alert(
      "Произошла непредвиденная ошибка",
      isPresented: self.$viewModel.showUnexpectedErrorAlert,
      actions: {
        Button(role: .cancel) {
          self.viewModel.showUnexpectedErrorAlert = false
        }
      }
    )
    .safeAreaPadding(.leading, Self.LEFT_SIDEBAR_WIDTH)
    .navigationTitle("Авторизация")
    .overlay(alignment: .topLeading) {
      List {
        Group {
          Label("Ichime — приложение для просмотра сериалов с сайта Anime 365.", systemImage: "info.circle")

          Label(
            "Для использования приложения требуется активная платная подписка на сайте Anime 365.",
            systemImage: "wallet.bifold"
          )

          Label(
            "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в настройках профиля на сайте.",
            systemImage: "key"
          )
        }
        .labelReservedIconWidth(Self.LEFT_SIDEBAR_ICON_CONTAINER_WIDTH)
        .padding(.vertical, Self.LEFT_SIDEBAR_LIST_ITEM_PADDING)
      }
      .listStyle(.grouped)
      .frame(width: Self.LEFT_SIDEBAR_WIDTH - Self.LEFT_SIDEBAR_RIGHT_MARGIN)
    }
  }
}
