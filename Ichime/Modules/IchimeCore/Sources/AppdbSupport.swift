import AppdbSDK
import Foundation

enum AppdbSupport {
  static var isInstalledViaAppdb: Bool {
    appdb.isInstalledViaAppdb()
  }

  static var appGroupIdentifier: String? {
    guard isInstalledViaAppdb else {
      return nil
    }

    guard case let .success(identifier) = appdb.getAppleAppGroupIdentifier(), !identifier.isEmpty else {
      return nil
    }

    return identifier
  }

  private static var appdb: any AppdbProtocol {
    Appdb.shared
  }
}
