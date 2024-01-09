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

        public init(userList: UserList, notificationList: NotificationList) {
            self.userList = userList
            self.notificationList = notificationList
        }

        public static func create(httpClient: HTTPClient) -> API {
            .init(userList: UserList(httpClient: httpClient), notificationList: NotificationList(httpClient: httpClient))
        }
    }

    /**
     Неймспейс для типов пакета
     */
    public enum Types {}
}
