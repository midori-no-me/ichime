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
        if Anime365Scraper.AuthManager.getCookie() != nil {
            parent.successHandler()
        }
    }
}

public struct Anime365ScraperAuth: UIViewRepresentable {
    let url: URL
    let successHandler: () -> Void
    
    public init(url: URL, onSuccess: @escaping () -> Void = {}) {
        self.url = url
        successHandler = onSuccess
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        // Создание экземпляра MessageHandler
        let messageHandler = MessageHandler(self)
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let userScript = WKUserScript(source: """
            var open = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function() {
                this.addEventListener("load", function() {
                    if (this.responseURL.includes('users/profile')) {
                            webkit.messageHandlers.handler.postMessage({ success: true });
                    }
                });
                open.apply(this, arguments);
            };
        """, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(messageHandler, name: "handler")
        config.userContentController = userContentController
        
        // Применение конфигурации к WKWebView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
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
               Anime365Scraper.AuthManager.getCookie() != nil
            {
                parent.successHandler()
            }
        }
        
        func webViewDidClose(_ webView: WKWebView) {}
    }
}
