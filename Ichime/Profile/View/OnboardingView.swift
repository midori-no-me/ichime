//
//  OnboardingView.swift
//  ichime
//
//  Created by p.flaks on 22.01.2024.
//

import SwiftUI

struct OnboardingView: View {
    @State var showAuth = false

    var body: some View {
        ScrollView([.vertical]) {
            AuthenticationTextParagraph(text: "Привет!")

            AuthenticationTextParagraph(
                text: "Это неофициальное приложение для просмотра сериалов с сайта Anime 365. Приложение бесплатное, но для просмотра видео требуется активная подписка на сайте."
            )

            AuthenticationAppFeatureSectionTitle(title: "Приложение")

            AuthenticationAppFeature(
                systemImage: "doc",
                title: "Открытый исходный код",
                description: "Весь код приложения есть на [GitHub](https://github.com/midori-no-me/ichime). Будем рады вашей помощи 👉👈"
            )

            AuthenticationAppFeature(
                systemImage: "sparkles",
                title: "Нативное приложение",
                description: "Постарались сделать красиво и удобно — на Swift и SwiftUI"
            )

            AuthenticationAppFeatureSectionTitle(title: "Что умеет")

            AuthenticationAppFeature(
                systemImage: "list.and.film",
                title: "Мой список",
                description: "Добавляйте сериалы в списки прямо через приложение"
            )

            AuthenticationAppFeature(
                systemImage: "film.stack",
                title: "Я смотрю",
                description: "Показываем серии, которые вы ещё не посмотрели"
            )

            AuthenticationAppFeature(
                systemImage: "bell.badge",
                title: "Уведомления",
                description: "Выводим ваши уведомления на видном месте"
            )

            AuthenticationAppFeature(
                systemImage: "magnifyingglass",
                title: "Поиск",
                description: "Поддержали поиск сериалов внутри приложения"
            )

            AuthenticationAppFeatureSectionTitle(title: "Плеер")

            AuthenticationAppFeature(
                systemImage: "play.rectangle",
                title: "Системный плеер",
                description: "Такой же используется в Safari, TV и других приложениях Apple"
            )

            AuthenticationAppFeature(
                systemImage: "airplayvideo",
                title: "AirPlay",
                description: "Видео можно вывести на телевизор или компьютер на macOS"
            )

            AuthenticationAppFeature(
                systemImage: "pip",
                title: "Picture-in-Picture",
                description: "Плеер можно свернуть в миниатюру, плавающую поверх других приложений"
            )

            AuthenticationAppFeature(
                systemImage: "captions.bubble",
                title: "Субтитры",
                description: "Умеем проигрывать видео с софтсабом, но пока что без AirPlay 😭"
            )

            AuthenticationAppFeature(
                systemImage: "plus.app",
                title: "Счетчик серий",
                description: "После просмотра серии уведомим сайт о том, что вы её посмотрели"
            )

            Button(action: { showAuth = true }, label: {
                Text("Войти в аккаунт")
            })
            .buttonStyle(.borderedProminent)
            .scenePadding(.bottom)
            .padding(.top)
        }
        .sheet(isPresented: $showAuth, content: {
            NavigationStack {
                AuthenticationView()
            }
        })
        .navigationTitle("Ichime")
        .toolbar {
            Button(action: { showAuth = true }, label: {
                Text("Вход")
            })
        }
        #if os(iOS)
        .toolbarTitleDisplayMode(.large)
        #endif
    }
}

struct AuthenticationAppFeature: View {
    let systemImage: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            Text(description)
                .foregroundStyle(Color.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all)
        #if os(macOS)
            .background(Color.primary.blendMode(.overlay), in: RoundedRectangle(cornerRadius: 12))
        #endif
        #if !os(tvOS)
            .background(Color(uiColor: UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        #endif

            .scenePadding(.horizontal)
    }
}

struct AuthenticationAppFeatureSectionTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.title)
            .fontWeight(.bold)
            .scenePadding(.horizontal)
            .padding(.top)
    }
}

struct AuthenticationTextParagraph: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .scenePadding(.horizontal)
            .padding(.top)
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
    }
}
