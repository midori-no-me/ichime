# Anime365Scraper

Пакет для парсинга данных с сайта anime365.ru

## Пример использования

```swift
let client = Anime365Scraper.API.HTTPClient(accessCookie: "auth-cookie") // которую получили из браузера
// создаем апи
let api = Anime365Scraper.API.create(httpClient: client);
// или так
let api = Anime365Scraper.API(userList: Anime365Scraper.UserList(httpClient: client), notificationList: Anime365Scraper.NotificationList(httpClient: client))
// дергаем апи
let result = try await api.userList.nextToWatch()
```


## Получение куки авторизации

```swift
                    Anime365ScraperAuth(url: URL(string: "https://anime365.ru/users/login")!) {
                        print("get cookie \(Anime365Scraper.AuthManager.getCookie()!)")
                    }
```

## Типы

`Anime365Scraper.Types.*`
