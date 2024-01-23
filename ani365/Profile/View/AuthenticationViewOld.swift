//
//  OnboardingView.swift
//  ani365
//
//  Created by p.flaks on 14.01.2024.
//

import ScraperAPI
import SwiftUI

struct OnboardingViewOld: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isEmailValid: Bool = true
    @State private var isPasswordValid: Bool = true
    @State private var invalidPassword = false

    @EnvironmentObject var scraperManager: ScraperClient

    var body: some View {
        Group {
            if let user = scraperManager.user {
                UserAuthView(userAuth: user)
            } else {
                VStack {
                    Text("Вход")
                        .font(.largeTitle)
                        .padding()

                    TextField("Email", text: $email)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: email) {
                            isEmailValid = isValidEmail(email)
                            invalidPassword = false
                        }

                    SecureField("Пароль", text: $password)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: password) {
                            isPasswordValid = isValidPassword(password)
                            invalidPassword = false
                        }

                    if invalidPassword {
                        Text("Неверный пароль или логин")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Color.red)
                    }
                    Button(action: {
                        // Ваш код для обработки авторизации
                        if isEmailValid, isPasswordValid {
                            Task {
                                do {
                                    let user = try await scraperManager.startAuth(username: email, password: password)
                                    print(user)
                                } catch ScraperAPI.APIClientError.invalidCredentials {
                                    invalidPassword.toggle()
                                } catch {
                                    print("some error", error.localizedDescription)
                                }
                            }
                        }
                    }) {
                        Text("Войти")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(!isEmailValid || !isPasswordValid || email.isEmpty || password.isEmpty)
                }
                .padding()
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Простая валидация email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // Простая валидация пароля
        return password.count >= 4
    }
}

struct UserAuthView: View {
    @EnvironmentObject var scraperManager: ScraperClient

    var userAuth: ScraperAPI.Types.User

    var body: some View {
        VStack {
            Text("Добро пожаловать, \(userAuth.username)!")
                .font(.title)
                .padding()

            AsyncImage(url: userAuth.avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .failure:
                    // Placeholder image or error handling
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .empty:
                    // Placeholder image or loading indicator
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                @unknown default:
                    // Placeholder image or loading indicator
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
            }

            Text("ID: \(String(userAuth.id))")
                .padding()

            Button(action: {
                // Ваш код для обработки авторизации
                scraperManager.dropAuth()
            }) {
                Text("Выйти")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            Spacer()
        }
    }
}

//#Preview {
//    AppPreview {
//        OnboardingViewOld()
//    }
//}
//
//struct AppPreview<Content: View>: View {
//    @StateObject var scraperManager: ScraperClient = .init(scraperClient: ServiceLocator.getScraperAPIClient())
//    @ViewBuilder var content: () -> Content
//
//    var body: some View {
//        content().environmentObject(scraperManager)
//    }
//}
