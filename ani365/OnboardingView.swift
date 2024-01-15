//
//  OnboardingView.swift
//  ani365
//
//  Created by p.flaks on 14.01.2024.
//

import Anime365Scraper
import SwiftUI

struct OnboardingView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isEmailValid: Bool = true
    @State private var isPasswordValid: Bool = true
    
    @EnvironmentObject var scraperManager: Anime365ScraperManager

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
                        }
                    
                    SecureField("Пароль", text: $password)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: password) {
                            isPasswordValid = isValidPassword(password)
                        }
                    
                    Button(action: {
                        // Ваш код для обработки авторизации
                        if isEmailValid, isPasswordValid {
                            Task {
                                do {
                                    let user = try await scraperManager.startAuth(username: email, password: password)
                                    print(user)
                                    
                                } catch {
                                    print("some error", error.localizedDescription)
                                }
                            }
                            // Добавьте код для сохранения данных в Keychain
                            saveToKeychain(service: Anime365Scraper.domain, email: email, password: password)
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
                .onAppear {
                    // Автозаполнение из Keychain
                    if let savedEmail = readFromKeychain(service: Anime365Scraper.domain, account: "email"),
                       let savedPassword = readFromKeychain(service: Anime365Scraper.domain, account: "password")
                    {
                        email = savedEmail
                        password = savedPassword
                    }
                }
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
        return password.count >= 6
    }
    
    private func saveToKeychain(service: String, email: String, password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "anime365.ru",
            kSecAttrAccount as String: "email",
            kSecValueData as String: email.data(using: .utf8)!
        ]
        let _ = SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "anime365.ru",
            kSecAttrAccount as String: "password",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        let _ = SecItemDelete(passwordQuery as CFDictionary)
        SecItemAdd(passwordQuery as CFDictionary, nil)
    }
    
    private func readFromKeychain(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let password = String(data: data, encoding: .utf8)
            {
                return password
            }
        }
        
        return nil
    }
}

struct UserAuthView: View {
    @EnvironmentObject var scraperManager: Anime365ScraperManager
    
    var userAuth: Anime365Scraper.AuthManager.Types.UserAuth
    
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

#Preview {
    AppPreview {
        OnboardingView()
    }
}

struct AppPreview<Content: View>: View {
    @StateObject var scraperManager: Anime365ScraperManager = .init()
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content().environmentObject(scraperManager)
    }
}
