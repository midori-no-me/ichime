public enum Anime365Scraper {
    public class API {
        // MARK: API Structures

        public let userList: UserList

        init(userList: UserList) {
            self.userList = userList
        }
        
        public static func create(httpClient: HTTPClient) -> API {
            .init(userList: UserList(httpClient: httpClient))
        }
    }

    public enum Types {}
}
