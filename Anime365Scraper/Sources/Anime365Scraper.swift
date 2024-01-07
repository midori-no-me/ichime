public enum Anime365Scraper {
    public class API {
        private let httpClient: API.HTTPClient

        // MARK: API Structures

        public let userList: UserList

        public init(accessCookie: String) {
            httpClient = API.HTTPClient(accessCookie)

            userList = UserList(httpClient: httpClient)
        }
    }

    public enum Types {}
}
