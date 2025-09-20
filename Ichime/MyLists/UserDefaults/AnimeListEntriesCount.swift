import Foundation

struct AnimeListEntriesCount {
  struct UserDefaultsKey {
    static let WATCHING = "anime_list_entries_count:watching"
    static let COMPLETED = "anime_list_entries_count:completed"
    static let ON_HOLD = "anime_list_entries_count:on_hold"
    static let DROPPED = "anime_list_entries_count:dropped"
    static let PLANNED = "anime_list_entries_count:planned"
  }

  private let userDefaults: UserDefaults

  init() {
    self.userDefaults = .init()
  }

  func save(
    count: Int,
    category: AnimeListCategory
  ) -> Void {
    switch category {
    case .watching:
      self.userDefaults.set(count, forKey: Self.UserDefaultsKey.WATCHING)
    case .completed:
      self.userDefaults.set(count, forKey: Self.UserDefaultsKey.COMPLETED)
    case .onHold:
      self.userDefaults.set(count, forKey: Self.UserDefaultsKey.ON_HOLD)
    case .dropped:
      self.userDefaults.set(count, forKey: Self.UserDefaultsKey.DROPPED)
    case .planned:
      self.userDefaults.set(count, forKey: Self.UserDefaultsKey.PLANNED)
    }
  }

  func clear() -> Void {
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.WATCHING)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.COMPLETED)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.ON_HOLD)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.DROPPED)
    self.userDefaults.removeObject(forKey: Self.UserDefaultsKey.PLANNED)
  }
}
