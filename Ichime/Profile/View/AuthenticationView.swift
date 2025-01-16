import ScraperAPI
import SwiftUI

@Observable
class AuthenticationViewModel {
  private let userManager: UserManager

  var userEmail = ""
  var userPassword = ""
  var showInvalidCredentialsAlert = false
  var showUnknownErrorAlert = false
  var isLoadingAuthentication = false
  var isSuccess = false
  var baseUrlPreference: BaseUrlPreference = .init()

  init(userManager: UserManager = ApplicationDependency.container.resolve()) {
    self.userManager = userManager
  }

  public func getProfileSettingsUrl() -> URL {
    self.baseUrlPreference.url
      .appendingPathComponent("/users/profile")
  }

  public func getPasswordResetUrl() -> URL {
    self.baseUrlPreference.url
      .appendingPathComponent("/users/forgotPassword")
  }

  public func performAuthentication() async {
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
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Form {
      Section {
        TextField("Почта", text: self.$viewModel.userEmail, prompt: Text("Адрес электронной почты"))
          .keyboardType(.emailAddress)
          .disableAutocorrection(true)

        SecureField("Пароль", text: self.$viewModel.userPassword, prompt: Text("Пароль"))
      } footer: {
        Text(
          "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в [настройках профиля](\(self.viewModel.getProfileSettingsUrl().absoluteString)) на сайте."
        )
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
    .toolbar {
      Group {
        if self.viewModel.isLoadingAuthentication {
          ProgressView()
        }
        else {
          Button("Войти") {
            Task {
              await self.viewModel.performAuthentication()
            }
          }
          .disabled(self.viewModel.userEmail.isEmpty || self.viewModel.userPassword.isEmpty)
        }
      }
    }
    .onChange(of: self.viewModel.isSuccess) {
      if self.viewModel.isSuccess {
        self.dismiss()
      }
    }
    .navigationTitle("Авторизация")
  }
}

#Preview {
  NavigationStack {
    AuthenticationView()
  }
}
