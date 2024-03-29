# Ichime

Нативное приложение для сайта Anime 365, созданное специально для iPhone и iPad.

## Скриншоты

<details>
<summary>iPhone</summary>
<img src="https://github.com/midori-no-me/ichime/assets/12474739/1b41d896-4695-415e-94a8-a49fc7a18ecb" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/95b50bf5-97f8-4aab-bcec-49cf6875d948" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/b3524b4c-1781-40e8-9e90-0f2d3d568457" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/4155ee84-dbbf-4229-943f-48125b3065d6" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/07eb2b25-54d7-444e-a62a-4137c3a52c62" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/5b632026-edc6-4888-81b5-49429c82868e" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/f2a9896a-677d-4ada-bfc9-dcd55f51811e" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/7261729d-56aa-4178-927f-e66fc873edef" width="280">
</details>

<details>
<summary>iPad</summary>
<img src="https://github.com/midori-no-me/ichime/assets/12474739/5799d8a6-23fe-4b00-adbf-581e5c803b6a" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/4e503525-bf94-4939-aeaf-8978bec15c8f" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/5fc61adb-6514-4145-a796-2cad84aafcbb" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/2d14d4a0-b772-4d1f-bdf4-d70e60de9444" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/b51f8fb2-9179-4a18-b561-5565e5be616f" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/f7618ac3-0e70-4bfa-a4d5-2dd43d6bfc1e" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/505bd649-da70-46d7-b6cc-489ca23cde05" width="280">
<img src="https://github.com/midori-no-me/ichime/assets/12474739/4518cf66-2684-458d-a91b-3b185c3fbcf7" width="280">
</details>

## Возможности приложения

Приложение покрывает все базовые сценарии пользования сайтом, касающиеся именно просмотра сериалов.

Плеер:

- Системный плеер — такой же, как в Safari и приложении "TV".
- Поддержка субтитров. Поддерживаются только субтитры в формате WebVTT.
- Поддержка AirPlay. Но без внешних субтитров.
- Внутри плеера отображается название сериала и номер серии.
- Если досмотреть серию до конца, то она автоматически будет отмечена просмотренной. Так же, как это сделано на сайте.

Ваша библиотека:

- Выводим список следующих серий к просмотру так же, как на сайте они выводятся в секции "Серии к просмотру".
- Раздел уведомлений с сайта, в котором отображается список вышедших недавно серий или сериалов. Но push-уведомления отправлять пока не умеем.
- Если перейти на страницу сериала, то его можно добавить в свой список.

Каталог сериалов:

- Список онгоингов.
- Поиск.
- Просмотр базовой информации о сериале.

## Как скачать

### iPhone и iPad

По понятным причинам приложения нет в App Store. Его можно установить можно через [AltStore](https://altstore.io), [Sideloadly](https://sideloadly.io) или аналогичный софт. Для этого вам потребуется компьютер на macOS или Windows.

#### Как установить через AltStore

Для установки потребуется macOS или Windows, а также устройство под управлением iOS или iPadOS версии 17.0 или новее. Ваши компьютер и мобильные устройства должны находиться в одной сети, например, быть подключены к одному домашнему Wi-Fi.

1. Скачайте файл с расширением `.ipa` у самого последнего релиза на странице [Releases](https://github.com/midori-no-me/ichime/releases) на iPhone или iPad.
2. Установите AltStore на компьютер по [официальной инструкции](https://faq.altstore.io). В этой же инструкции будет написано, как установить его на iPhone и iPad.
3. Откройте AltStore на вашем iPhone или iPad, в нижнем меню выберите вкладку "My Apps" (Мои Приложения).
4. В верхнем меню нажмите на кнопку "+" и выберите сохраненный ранее файл с расширением `.ipa`.
5. AltStore начнёт установку приложения на ваше устройство. Если потребуется, введите данные вашего Apple ID для подписи приложения.

Приложение установлено, но при его запуске вы увидите ошибку. Чтобы ее не было, нужно:

1. Заходим в приложение с настройками системы → "Основные" → "Управление устройством".
2. Находим ваш Apple ID в списке и нажимаем на него.
3. Нажимаем "Доверять" и подтверждаем.

Теперь приложение должно работать корректно.

> [!IMPORTANT]  
> Приложения, установленные через AltStore или любым другим аналогичным способом, нужно обновлять каждые 7 дней. Это ограничение Apple. Просто откройте AltStore и обновите приложения в разделе "Мои приложения". Во время этого процесса ваш компьютер и мобильные устройства должны находиться в одной сети, например, быть подключены к одному домашнему Wi-Fi, а на компьютере должен быть запущен AltStore. Приложение AltStore на вашем телефоне уведомит вас о том, что пора обновлять приложения. Вы также можете автоматизировать этот процесс через приложение "Команды" на вашем iPhone или iPad.

### macOS

Эта версия пока в разработке.

### tvOS

Эта версия пока в разработке.

## Архитектура

Приложение построено на SwiftUI и AVKit.

### Взаимодействие с сайтом

У сайта есть HTTP API, но там поддерживаются не все возможности — только read-only запросы.

Все запросы с сессией пользователя, а также запросы, мутирующие состояние сервера, выполняются не к API, а к самому сайту — так, будто бы это запросы из браузера. Это значит, что некоторые данные получаются путем парсинга HTML самого сайта.

### Субтитры

На сайте субтитры распространяются в формате `.vtt` ([WebVTT](https://en.wikipedia.org/wiki/WebVTT)), поэтому мы их передаем в видео-плеер как есть.

Так как WebVTT субтитры сайт генерирует автоматически на основе других субтитров (ASS или SRT), то в некоторых переводах, особенно где переводят надписи на экране, возможен не очень красивый рендеринг субтитров.
