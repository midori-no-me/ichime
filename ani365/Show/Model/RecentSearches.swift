import SwiftData


@Model
final class RecentSearches {
    var searchQueries: [String]

    init(searchQueries: [String] = []) {
        self.searchQueries = searchQueries
    }
}
