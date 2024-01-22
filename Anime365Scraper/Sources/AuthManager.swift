//
//  File.swift
//
//
//  Created by Nikita Nafranets on 10.01.2024.
//

import Foundation
import SwiftSoup

public extension Anime365Scraper {
    class AuthManager {
        public static let shared = AuthManager()
        let session = Types.Session(cookieStorage: HTTPCookieStorage.shared, domain: Anime365Scraper.domain)

        init() {
            self.user = UserManager.loadUserAuth()
        }

        private enum APIError: Error {
            case emptyResponse
            case invalidResponse
            case invalidURL
            case requestFailed
            case serverError
            case parseError
            case parseUserError
        }

        public func login(username: String, password: String) async throws -> Types.UserAuth {
            session.dropAll()
            let csrf = UUID().uuidString
            session.set(name: .csrf, value: csrf)

            guard let urlString = getUrl(method: .login), let url = URL(string: urlString) else {
                print("Invalid URL")
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(Anime365Scraper.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10

            // Constructing the request data from the dictionary
            let formData = [
                "csrf": csrf,
                "LoginForm[username]": username,
                "LoginForm[password]": password,
                "dynpage": "1",
                "yt0": "",
            ].map { key, value in
                "\(key)=\(value)"
            }.joined(separator: "&")

            print("construct formData", formData)
            request.httpBody = formData.data(using: .utf8)

            do {
                // Performing the asynchronous request
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let response = response as? HTTPURLResponse, (200 ..< 300).contains(response.statusCode),
                      let responseHTML = String(data: data, encoding: .utf8)
                else {
                    print("Invalid response", response)
                    throw APIError.invalidResponse
                }
                print("Response", response)

                guard let document = try? SwiftSoup.parseBodyFragment(responseHTML), let content = try? document.select("content").first() else {
                    print("Parse error")
                    throw APIError.parseError
                }

                guard let user = createUser(from: content) else {
                    print("User parse error")
                    throw APIError.parseUserError
                }

                print("User: \(user)")
                setUser(user)

                return user
            } catch {
                print("Error: \(error)")
                throw error
            }
        }

        public func logout() {
            print(session.cookieAsString())
            print("after \n")
            session.dropAll()
            UserManager.dropUserAuth()
            print(session.cookieAsString())
            user = nil
        }

        private var user: Types.UserAuth?

        private func createUser(from element: Element) -> Types.UserAuth? {
            guard let idString = try? element.text().firstMatch(of: #/ID аккаунта: (\d+)/#)?.output.1,
                  let id = Int(idString),
                  let avatarSrc = try? element.select(".card-image.hide-on-small-and-down img").first()?.attr("src"),
                  let baseURL = getUrl(method: .main),
                  let avatarURL = URL(string: baseURL + avatarSrc.dropFirst()),
                  let username = try? element.select(".m-small-title").first()?.text()
            else {
                return nil
            }

            return .init(id: id, username: username, avatarURL: avatarURL)
        }

        private func setUser(_ user: Types.UserAuth) {
            UserManager.saveUserAuth(user)
            self.user = user
        }

        public func getUser() -> Types.UserAuth? {
            user
        }
    }
}

enum Methods {
    case login
    case main
    case profile
    case notifications
    case userList(userId: Int, type: Anime365Scraper.Types.UserListCategoryType? = nil)
    case getAnimeStatus(id: String)
    case updateAnimeStatus(id: String)

    var value: String {
        switch self {
        case .login:
            return "users/login"
        case .main:
            return ""
        case .notifications:
            return "/notifications/index"
        case .profile:
            return "users/profile"
        case .userList(let userId, let type):
            var path = "/users/\(userId)/list"
            switch type {
            case .completed:
                path = path + "/completed"
            case .dropped:
                path = path + "/dropped"
            case .onHold:
                path = path + "/onhold"
            case .watching:
                path = path + "/watching"
            case .planned:
                path = path + "/planned"
            case .none:
                break
            }
            return path
        case .getAnimeStatus(let id):
            return "animelist/edit/\(id)"
        case .updateAnimeStatus(let id):
            return "animelist/edit/\(id)"
        }
    }
}

func getUrl(method: Methods, params: [String: String] = [String: String]()) -> String? {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = Anime365Scraper.domain
    urlComponents.path = "/\(method.value)"

    if !params.isEmpty {
        urlComponents.queryItems = []
        for (key, value) in params {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
    }

    return urlComponents.string
}

public extension Anime365Scraper.AuthManager {
    enum Types {
        public struct UserAuth: Codable {
            public let id: Int
            public let username: String
            public let avatarURL: URL
            public init(id: Int, username: String, avatarURL: URL) {
                self.id = id
                self.username = username
                self.avatarURL = avatarURL
            }
        }

        struct Session {
            let cookieStorage: HTTPCookieStorage
            let domain: String
            init(cookieStorage: HTTPCookieStorage, domain: String) {
                self.cookieStorage = cookieStorage
                self.domain = domain
            }

            enum Cookie: String {
                case csrf
                case phpsessid = "PHPSESSID"
                case token = "aaaa8ed0da05b797653c4bd51877d861"
                case guestId
                case fv
            }

            func set(name: Cookie, value: String) {
                if let cookie = HTTPCookie(properties: [
                    .name: name.rawValue,
                    .value: value,
                    .domain: domain,
                    .path: "/",
                ]) {
                    cookieStorage.setCookie(
                        cookie
                    )
                }
            }

            func get(name: Cookie) -> HTTPCookie? {
                cookieStorage.cookies?.first(where: { $0.name == name.rawValue })
            }

            func dropAll() {
                let cookies = [Cookie.csrf.rawValue, Cookie.phpsessid.rawValue, Cookie.token.rawValue]
                cookieStorage.cookies?.filter { cookie in cookies.contains(where: { cookie.name == $0 }) }.forEach {
                    cookieStorage.deleteCookie($0)
                }
            }

            func cookieAsString() -> String {
                return cookieStorage.cookies?.map { "\($0.name)=\($0.value)" }.joined(separator: "; ") ?? ""
            }
        }
    }
}

enum UserManager {
    // Сохранение UserAuth в UserDefaults
    static func saveUserAuth(_ userAuth: Anime365Scraper.AuthManager.Types.UserAuth) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userAuth)
            UserDefaults.standard.set(data, forKey: "userAuth")
        } catch {
            print("Failed to save UserAuth: \(error)")
        }
    }

    static func dropUserAuth() {
        UserDefaults.standard.removeObject(forKey: "userAuth")
    }

    // Загрузка UserAuth из UserDefaults
    static func loadUserAuth() -> Anime365Scraper.AuthManager.Types.UserAuth? {
        guard let data = UserDefaults.standard.data(forKey: "userAuth") else { return nil }

        do {
            let decoder = JSONDecoder()
            let userAuth = try decoder.decode(Anime365Scraper.AuthManager.Types.UserAuth.self, from: data)
            return userAuth
        } catch {
            print("Failed to load UserAuth: \(error)")
            return nil
        }
    }
}
