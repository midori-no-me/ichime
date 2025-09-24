import SwiftUI

struct AuthenticationRequiredContentUnavailableView: View {
  @State private var showAuthenticationSheet: Bool = false

  let onSuccessfulAuth: () -> Void

  var body: some View {
    ContentUnavailableView {
      Label("Нужно войти в аккаунт", systemImage: "person.badge.key.fill")
    } description: {
      Text("Для просмотра этой страницы нужно авторизоваться")
    } actions: {
      Button("Войти") {
        self.showAuthenticationSheet = true
      }
      .fullScreenCover(isPresented: self.$showAuthenticationSheet) {
        NavigationStack {
          AuthenticationSheet(onSuccessfulAuth: self.onSuccessfulAuth)
        }
        .background(.thickMaterial)
      }
    }
  }
}
