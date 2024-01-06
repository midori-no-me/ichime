//
//  AuthenticationView.swift
//  ichime
//
//  Created by p.flaks on 23.01.2024.
//

import ScraperAPI
import SwiftUI

@Observable
class AuthenticationViewModel {
    private let userManager: UserManager

    var userEmail: String = ""
    var userPassword: String = ""
    var showInvalidCredentialsAlert: Bool = false
    var showUnknownErrorAlert: Bool = false
    var isLoadingAuthentication: Bool = false
    var isSuccess = false
    var baseUrlPreference: BaseUrlPreference = .init()

    init(userManager: UserManager = ApplicationDependency.container.resolve()) {
        self.userManager = userManager
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
            _ = try await userManager.startAuth(
                username: userEmail,
                password: userPassword
            )

            isSuccess = true
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
    @State private var viewModel: AuthenticationViewModel = .init()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(macOS)
            Spacer()
        #endif
        HStack {
            #if os(macOS)
                Spacer()
            #endif
            Form {
                Section {
                    TextField("Почта", text: $viewModel.userEmail, prompt: Text("Адрес электронной почты"))
                        .disableAutocorrection(true)
                    #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    #endif

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
            #if os(macOS)
            .padding(.all)
            #endif
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
                    message: Text(
                        "При авторизации что-то пошло не так. Если у вас включен VPN, попробуйте его выключить."
                    ),
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
            .onChange(of: viewModel.isSuccess) {
                if viewModel.isSuccess {
                    dismiss()
                }
            }
            .navigationTitle("Авторизация")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(macOS)
            Spacer()
        #endif
    }
}

#Preview {
    NavigationStack {
        AuthenticationView()
    }
}
