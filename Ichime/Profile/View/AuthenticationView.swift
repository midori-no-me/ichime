import AuthenticationServices
import ScraperAPI
import SwiftUI

@Observable
private class AuthenticationViewModel {
  var userEmail = ""
  var userPassword = ""
  var showInvalidCredentialsAlert = false
  var showUnknownErrorAlert = false
  var isLoadingAuthentication = false
  var isSuccess = false
  var baseUrlPreference: BaseUrlPreference = .init()

  private let userManager: UserManager

  init(userManager: UserManager = ApplicationDependency.container.resolve()) {
    self.userManager = userManager
  }

  func performAuthentication() async {
    self.isLoadingAuthentication = true

    do {
      _ = try await self.userManager.startAuth(
        username: self.userEmail,
        password: self.userPassword
      )

      self.isSuccess = true
    }
    catch ScraperAPI.APIClientError.invalidCredentials {
      print("invalidCredentials")

      self.showInvalidCredentialsAlert = true
    }
    catch {
      print(error)

      self.showUnknownErrorAlert = true
    }

    self.isLoadingAuthentication = false
  }
}

struct AuthenticationView: View {
  @State private var viewModel: AuthenticationViewModel = .init()
  @Environment(\.authorizationController) private var authorizationController
  @State private var showManualSignInForm: Bool = false

  var body: some View {
    Form {
      Section {
        if self.showManualSignInForm {
          Button("Отмена") {
            withAnimation {
              self.showManualSignInForm = false
            }
          }
        }
        else {
          Button("Войти в аккаунт Anime 365") {
            Task {
              await self.openSignInScreen()
            }
          }
        }
      }

      if self.showManualSignInForm {
        Section {
          TextField("Почта", text: self.$viewModel.userEmail, prompt: Text("Адрес электронной почты"))
            .keyboardType(.emailAddress)
            .disableAutocorrection(true)

          SecureField("Пароль", text: self.$viewModel.userPassword, prompt: Text("Пароль"))
        }

        Section {
          Button("Войти") {
            Task {
              await self.viewModel.performAuthentication()
            }
          }
          .disabled(self.viewModel.userEmail.isEmpty || self.viewModel.userPassword.isEmpty)
        }
      }

      Section {
        Picker("Адрес сайта", selection: self.$viewModel.baseUrlPreference.url) {
          ForEach(BaseUrlPreference.allPossibleWebsiteBaseDomains, id: \.self) { url in
            Text(url.host()!).tag(url)
          }
        }
      } footer: {
        Text(
          "Попробуйте выбрать другой адрес, если испытываете проблемы с авторизацией, или если приложение работает некорректно."
        )
      }
    }
    .safeAreaPadding(.leading, 900)
    .navigationTitle("Авторизация")
    .overlay(alignment: .topLeading) {
      VStack(alignment: .leading, spacing: 16) {
        Group {
          Text("Ichime — приложение для просмотра сериалов с сайта Anime 365.")
          Text("Для использования приложения требуется активная платная подписка на сайте Anime 365.")
          Text(
            "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в настройках профиля на сайте."
          )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(width: 900 - 64)
    }
    .alert(
      "Не удалось авторизоваться",
      isPresented: self.$viewModel.showInvalidCredentialsAlert,
      actions: {
        Button(
          "Закрыть",
          role: .cancel,
          action: {
            self.viewModel.showInvalidCredentialsAlert.toggle()
          }
        )
      }
    ) {
      Text("Неправильный адрес электронной почты или пароль.")
    }
    .alert(
      "Не удалось авторизоваться",
      isPresented: self.$viewModel.showUnknownErrorAlert,
      actions: {
        Button(
          "Закрыть",
          role: .cancel,
          action: {
            self.viewModel.showUnknownErrorAlert.toggle()
          }
        )
      }
    ) {
      Text(
        "При авторизации что-то пошло не так. Если у вас включен VPN, попробуйте его выключить."
      )
    }
  }

  private func openSignInScreen() async -> Void {
    do {
      let result =
        try await authorizationController
        .performRequests(
          [
            ASAuthorizationPasswordProvider().createRequest()
          ],
          customMethods: [
            .other
          ]
        )

      switch result {
      case .password(let credential):
        self.viewModel.userEmail = credential.user
        self.viewModel.userPassword = credential.password

        await self.viewModel.performAuthentication()
      case .customMethod(let method):
        switch method {
        case .other:
          self.showManualSignInForm = true
        default:
          return
        }
      default:
        return
      }
    }
    catch {
      // code to handle the authorization error
    }
  }
}
