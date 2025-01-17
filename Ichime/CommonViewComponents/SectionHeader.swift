import SwiftUI

struct SectionHeaderRaw: View {
  let title: String
  let subtitle: String?

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(self.title)
        .font(.title3)
        .fontWeight(.bold)

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.headline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .focusSection()
  }
}

struct SectionHeader<Content: View>: View {
  let title: String
  let subtitle: String?
  @ViewBuilder let destination: Content

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      NavigationLink(destination: self.destination) {
        Text(self.title)
          .font(.title3)
          .fontWeight(.bold)
      }
      .buttonStyle(.plain)

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.headline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .focusSection()
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      VStack(spacing: 30) {
        SectionHeader(
          title: "Title",
          subtitle: "Subtitle"
        ) {
          Text("destination")
        }

        SectionHeader(
          title: "Title without subtitle",
          subtitle: nil
        ) {
          Text("destination")
        }
      }
    }
  }
}
