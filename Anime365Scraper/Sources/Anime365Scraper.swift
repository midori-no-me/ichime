public enum Anime365Scraper {
    /**
     Корневой класс пакета, хранит в себе весь апи для работы с сайтом anime365.ru
     */
    public class API {
        // MARK: API Structures

        /**
         Структура для запросов пользовательских списков аниме
         */
        public let userList: UserList
        /**
         Структура для запросов к разделу уведомлений
         */
        public let notificationList: NotificationList
        /**
         Структура для запросов к профилю
         */
        public let profile: Profile
        public init(userList: UserList, notificationList: NotificationList, profile: Profile) {
            self.userList = userList
            self.notificationList = notificationList
            self.profile = profile
        }

        public static func create(httpClient: HTTPClient) -> API {
            .init(userList: UserList(httpClient: httpClient), notificationList: NotificationList(httpClient: httpClient), profile: Profile(httpClient: httpClient))
        }
    }

    /**
     Неймспейс для типов пакета
     */
    public enum Types {}
}
