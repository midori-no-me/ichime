import SwiftUI

struct SectionWithCards<Content: View>: View {
  let title: String

  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text(self.title)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        self.content
      }
    }
    #if os(tvOS)
    .focusSection()
    #endif
  }
}
