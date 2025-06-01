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

  var body: some View {
    Form {
      Section {
        TextField("Почта", text: self.$viewModel.userEmail, prompt: Text("Адрес электронной почты"))
          .keyboardType(.emailAddress)

        SecureField("Пароль", text: self.$viewModel.userPassword, prompt: Text("Пароль"))
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

      Section {
        Button("Войти") {
          Task {
            await self.viewModel.performAuthentication()
          }
        }
        .disabled(self.viewModel.userEmail.isEmpty || self.viewModel.userPassword.isEmpty)
      }
    }
    .safeAreaPadding(.leading, 900)
    .navigationTitle("Авторизация")
    .overlay(alignment: .topLeading) {
      List {
        Group {
          Label {
            Text("Ichime — приложение для просмотра сериалов с сайта Anime 365.")
          } icon: {
            Image(systemName: "info.circle")
              .frame(width: 48, alignment: .center)
          }

          Label {
            Text("Для использования приложения требуется активная платная подписка на сайте Anime 365.")
          } icon: {
            Image(systemName: "wallet.bifold")
              .frame(width: 48, alignment: .center)
          }

          Label {
            Text(
              "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в настройках профиля на сайте."
            )
          } icon: {
            Image(systemName: "key")
              .frame(width: 48, alignment: .center)
          }
        }
        .padding(.vertical, 16)
      }
      .listStyle(.grouped)
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
}
