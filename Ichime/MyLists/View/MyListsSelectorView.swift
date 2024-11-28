import SwiftUI
import ScraperAPI

struct MyListsSelectorView: View {
  @Environment(\.modelContext) private var modelContext
  
  var body: some View {
    List {
      ForEach(ScraperAPI.Types.ListCategoryType.allCases, id: \.rawValue) { category in
        NavigationLink(destination: {
          MyListsView(categoryType: category, modelContext: modelContext)
        }) {
          Label(category.rawValue, systemImage: UIDevice.current.userInterfaceIdiom == .tv
                ? category.imageInToolbarNotFilled
                : category.imageInDropdown
          )
        }
      }
    }
    .navigationTitle("Мой список")
    #if !os(tvOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    #if os(tvOS)
          .listStyle(.grouped)
    #endif
  }
}
