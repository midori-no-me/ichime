import Foundation

struct CurrentUserInfo {
  struct UserDefaultsKey {
    static let ID = "current_user_info:id"
    static let NAME = "current_user_info:name"
    static let AVATAR_URL_PATH = "current_user_info:avatar_url_path"
  }

  private let userDefaults: UserDefaults

  init() {
    self.userDefaults = .init()
  }

  func save(id: Int, name: String, avatarURLPath: String) -> Void {
    self.userDefaults.setValuesForKeys([
      Self.UserDefaultsKey.ID: id,
      Self.UserDefaultsKey.NAME: name,
      Self.UserDefaultsKey.AVATAR_URL_PATH: avatarURLPath,
    ])
  }

  func clear() -> Void {
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.ID)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.NAME)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.AVATAR_URL_PATH)
  }
}
