import SwiftUI

@Observable
class CurrentUserStore {
  var user: User? = nil

  func setUser(user: User?) -> Void {
    withAnimation {
      self.user = user
    }
  }
}
