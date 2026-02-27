//
//  WebView.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var request: URLRequest?

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    @Binding var currentURLString: String

    // Toolbar triggers from SwiftUI
    @Binding var goBackTapped: Bool
    @Binding var goForwardTapped: Bool
    @Binding var reloadTapped: Bool

    // Optional navigation event callback
    var onNavigationEvent: (String) -> Void = { _ in }

    // One-shot JS to evaluate
    @Binding var jsToEvaluate: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load new request if changed
        if let req = request {
            if webView.url?.absoluteString != req.url?.absoluteString {
                webView.load(req)
            }
        }

        // Handle toolbar triggers (consume + reset)
        if goBackTapped {
            DispatchQueue.main.async { self.goBackTapped = false }
            if webView.canGoBack { webView.goBack() }
        }

        if goForwardTapped {
            DispatchQueue.main.async { self.goForwardTapped = false }
            if webView.canGoForward { webView.goForward() }
        }

        if reloadTapped {
            DispatchQueue.main.async { self.reloadTapped = false }
            webView.reload()
        }

        // Evaluate JS once
        if let js = jsToEvaluate {
            webView.evaluateJavaScript(js)
            DispatchQueue.main.async { self.jsToEvaluate = nil }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onNavigationEvent("didStart")
            syncState(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onNavigationEvent("didFinish")
            syncState(webView)

            DispatchQueue.main.async {
                self.parent.title = webView.title ?? ""
                self.parent.currentURLString = webView.url?.absoluteString ?? ""
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onNavigationEvent("didFail: \(error.localizedDescription)")
            syncState(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        private func syncState(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.currentURLString = webView.url?.absoluteString ?? self.parent.currentURLString
            }
        }
    }
}
