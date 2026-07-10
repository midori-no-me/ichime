import SwiftUI

@Observable
public class CurrentUserStore {
  public var user: User? = nil

  public init() {}

  public func setUser(user: User?) -> Void {
    withAnimation {
      self.user = user
    }
  }
}
