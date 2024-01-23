//
//  AuthenticationView.swift
//  ani365
//
//  Created by p.flaks on 23.01.2024.
//

import ScraperAPI
import SwiftUI

class AuthenticationViewModel: ObservableObject {
    private let scraperClient: ScraperClient

    @Published var userEmail: String = ""
    @Published var userPassword: String = ""
    @Published var showInvalidCredentialsAlert: Bool = false
    @Published var showUnknownErrorAlert: Bool = false
    @Published var isLoadingAuthentication: Bool = false
    @Published var baseUrlPreference: BaseUrlPreference = .init()

    init() {
        self.scraperClient = ScraperClient(scraperClient: ServiceLocator.getScraperAPIClient())
    }

    public func getProfileSettingsUrl() -> URL {
        return baseUrlPreference.url
            .appendingPathComponent("/users/profile")
    }

    public func getPasswordResetUrl() -> URL {
        return baseUrlPreference.url
            .appendingPathComponent("/users/forgotPassword")
    }

    public func performAuthentication() async {
        isLoadingAuthentication = true

        do {
            let user = try await scraperClient.startAuth(
                username: userEmail,
                password: userPassword
            )

            print(user)

        } catch ScraperAPI.APIClientError.invalidCredentials {
            print("invalidCredentials")

            showInvalidCredentialsAlert = true

        } catch {
            print(error)

            showUnknownErrorAlert = true
        }

        isLoadingAuthentication = false
    }
}

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel

    init() {
        viewModel = AuthenticationViewModel()
    }

    var body: some View {
        Form {
            Section {
                TextField("Почта", text: $viewModel.userEmail, prompt: Text("Адрес электронной почты"))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Пароль", text: $viewModel.userPassword, prompt: Text("Пароль"))
            } footer: {
                Text(
                    "Приложение не поддерживает авторизацию через социальные сети. Установите пароль в [настройках профиля](\(viewModel.getProfileSettingsUrl().absoluteString)) на сайте."
                )
            }

            Section {
                Picker("Адрес сайта", selection: $viewModel.baseUrlPreference.url) {
                    ForEach(BaseUrlPreference.getAllPossibleWebsiteBaseDomains(), id: \.self) { url in
                        Text(url.host()!).tag(url)
                    }
                }
            } footer: {
                Text(
                    "Попробуйте выбрать другой адрес, если испытываете проблемы с авторизацией, или если приложение работает некорректно."
                )
            }

            Section {
                Link("Восстановить пароль", destination: viewModel.getPasswordResetUrl())
            }
        }
        .alert(isPresented: $viewModel.showInvalidCredentialsAlert) {
            Alert(
                title: Text("Не удалось авторизоваться"),
                message: Text("Неправильный адрес электронной почты или пароль."),
                dismissButton: .cancel()
            )
        }
        .alert(isPresented: $viewModel.showUnknownErrorAlert) {
            Alert(
                title: Text("Не удалось авторизоваться"),
                message: Text("При авторизации что-то пошло не так. Если у вас включен VPN, попробуйте его выключить."),
                dismissButton: .cancel()
            )
        }
        .toolbar {
            Group {
                if viewModel.isLoadingAuthentication {
                    ProgressView()
                } else {
                    Button("Войти") {
                        Task {
                            await viewModel.performAuthentication()
                        }
                    }
                    .disabled(viewModel.userEmail.isEmpty || viewModel.userPassword.isEmpty)
                }
            }
        }
        .navigationTitle("Авторизация")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppPreview<Content: View>: View {
    @StateObject var scraperClient: ScraperClient = .init(scraperClient: ServiceLocator.getScraperAPIClient())
    @ViewBuilder var content: (_: ScraperClient) -> Content

    var body: some View {
        content(scraperClient).environmentObject(scraperClient)
    }
}

#Preview {
    AppPreview { client in
        NavigationStack {
            AuthenticationView()
        }
    }
}
