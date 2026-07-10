import SwiftUI

@Observable
public class CurrentUserStore {
  // MARK: Properties

  public var user: User? = nil

  // MARK: Lifecycle

  public init() {}

  // MARK: Functions

  public func setUser(user: User?) -> Void {
    withAnimation {
      self.user = user
    }
  }
}
