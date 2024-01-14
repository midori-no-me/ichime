//
//  Anime365ScraperAuth.swift
//
//
//  Created by Nikita Nafranets on 09.01.2024.
//

import SwiftUI
import WebKit

class MessageHandler: NSObject, WKScriptMessageHandler {
    let parent: Anime365ScraperAuth
    
    init(_ parent: Anime365ScraperAuth) {
        self.parent = parent
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let cookieValue = Anime365Scraper.AuthManager.shared.getCookieValue(), let webView = message.webView {
            parseCookie(rawCookieValue: cookieValue, webView: webView) { result, _ in
                if let result {
                    Anime365Scraper.AuthManager.shared.setUser(id: result.id, username: result.username, cookieValue: cookieValue)
                    self.parent.successHandler()
                }
            }
        }
    }
}

public struct Anime365ScraperAuth: UIViewRepresentable {
    let successHandler: () -> Void
    
    public init(onSuccess: @escaping () -> Void = {}) {
        successHandler = onSuccess
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        // Создание экземпляра MessageHandler
        let messageHandler = MessageHandler(self)
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        if let filePath = Bundle.module.path(forResource: "inject", ofType: "js") {
            do {
                let javascriptCode = try String(contentsOfFile: filePath)
                let userScript = WKUserScript(source: javascriptCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                userContentController.addUserScript(userScript)
            } catch {
                print("Ошибка чтения файла: \(error)")
            }
        } else {
            print("Не смог найти файл из бандла")
        }
        userContentController.add(messageHandler, name: "handler")
        config.userContentController = userContentController
        
        // Применение конфигурации к WKWebView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://anime365.ru/users/login")!))
       
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        let parent: Anime365ScraperAuth
        
        init(_ parent: Anime365ScraperAuth) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString,
               url.contains("users/profile"),
               let cookieValue = Anime365Scraper.AuthManager.shared.getCookieValue()
            {
                parseCookie(rawCookieValue: cookieValue, webView: webView) { result, _ in
                    if let result {
                        Anime365Scraper.AuthManager.shared.setUser(id: result.id, username: result.username, cookieValue: cookieValue)
                        self.parent.successHandler()
                    }
                }
            }
        }
        
        func webViewDidClose(_ webView: WKWebView) {}
    }
}

struct ParsingError: Error {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

func parseCookie(rawCookieValue: String, webView: WKWebView, completionHandler: @escaping ((id: Int, username: String)?, Error?) -> Void) {
    let hashSize = 40
    if let clearedCookie = rawCookieValue.removingPercentEncoding {
        let valueWithoutHash = clearedCookie.dropFirst(hashSize)
        
        webView.evaluateJavaScript("phpDeserialize(`\(valueWithoutHash)`)", completionHandler: { result, error in
            guard let array = result as? [Any],
                  array.count >= 2,
                  let NSUserId = array[0] as? NSNumber,
                  let username = array[1] as? String
            else {
                completionHandler(nil, ParsingError(error?.localizedDescription ?? "Не удалось распарсить"))
                return
            }

            completionHandler((id: NSUserId.intValue, username: username), nil)
        })
    } else {
        completionHandler(nil, ParsingError("Не получилось очистить куку"))
    }
}
