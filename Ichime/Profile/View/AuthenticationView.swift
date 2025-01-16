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
    baseUrlPreference.url
      .appendingPathComponent("/users/profile")
  }

  public func getPasswordResetUrl() -> URL {
    baseUrlPreference.url
      .appendingPathComponent("/users/forgotPassword")
  }

  public func performAuthentication() async {
    isLoadingAuthentication = true

    do {
      _ = try await userManager.startAuth(
        username: userEmail,
        password: userPassword
      )

      isSuccess = true
    }
    catch ScraperAPI.APIClientError.invalidCredentials {
      print("invalidCredentials")

      showInvalidCredentialsAlert = true

    }
    catch {
      print(error)

      showUnknownErrorAlert = true
    }

    isLoadingAuthentication = false
  }
}

struct AuthenticationView: View {
  @State private var viewModel: AuthenticationViewModel = .init()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Form {
      Section {
        TextField("Почта", text: $viewModel.userEmail, prompt: Text("Адрес электронной почты"))
          .keyboardType(.emailAddress)
          .disableAutocorrection(true)

        SecureField("Пароль", text: $viewModel.userPassword, prompt: Text("Пароль"))
      } footer: {
        Text(
          "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в [настройках профиля](\(viewModel.getProfileSettingsUrl().absoluteString)) на сайте."
        )
      }

      Section {
        Picker("Адрес сайта", selection: $viewModel.baseUrlPreference.url) {
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
      isPresented: $viewModel.showInvalidCredentialsAlert,
      actions: {
        Button(
          "Закрыть",
          role: .cancel,
          action: {
            viewModel.showInvalidCredentialsAlert.toggle()
          }
        )
      }
    ) {
      Text("Неправильный адрес электронной почты или пароль.")
    }
    .alert(
      "Не удалось авторизоваться",
      isPresented: $viewModel.showUnknownErrorAlert,
      actions: {
        Button(
          "Закрыть",
          role: .cancel,
          action: {
            viewModel.showUnknownErrorAlert.toggle()
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
        if viewModel.isLoadingAuthentication {
          ProgressView()
        }
        else {
          Button("Войти") {
            Task {
              await viewModel.performAuthentication()
            }
          }
          .disabled(viewModel.userEmail.isEmpty || viewModel.userPassword.isEmpty)
        }
      }
    }
    .onChange(of: viewModel.isSuccess) {
      if viewModel.isSuccess {
        dismiss()
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
