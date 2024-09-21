# Ichime

Нативное приложение для сайта Anime 365, созданное специально для iPhone, iPad и Apple TV.

## Скриншоты

![Скриншоты с iPhone, iPad и Apple TV](https://github.com/midori-no-me/ichime/assets/12474739/ea171855-ca7f-4e8d-a85f-f4afcbc45810)

Больше скриншотов с iPhone, iPad и Apple TV можно найти на странице [Wiki → Скриншоты](https://github.com/midori-no-me/ichime/wiki/Скриншоты).

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

## Как установить

Способы установки описаны на странице [Wiki → Как установить приложение](https://github.com/midori-no-me/ichime/wiki/Как-установить-приложение).

## Как собрать приложение

Чтобы собрать приложение:

1. Склонируйте репозиторий.

2. Установите [XcodeGen](https://github.com/yonaskolb/XcodeGen).

3. В корне директории выполните команду:
  
   ```bash
   xcodegen generate
   ```

   Эта команда сгенерирует конфигурационные файлы для Xcode.

4. Откройте проект в Xcode.

5. Если необходимо подписать приложение, у всех таргетов во вкладке Signing & Capabilities выберите Team.

6. Соберите приложение через Xcode.