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

    var onNavigationEvent: (String) -> Void

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
            // Avoid reloading same URL repeatedly
            if webView.url?.absoluteString != req.url?.absoluteString {
                webView.load(req)
            }
        }

        // Handle toolbar triggers
        if context.coordinator.consume(&context.coordinator.goBackTapped) {
            if webView.canGoBack { webView.goBack() }
        }
        if context.coordinator.consume(&context.coordinator.goForwardTapped) {
            if webView.canGoForward { webView.goForward() }
        }
        if context.coordinator.consume(&context.coordinator.reloadTapped) {
            webView.reload()
        }

        // Evaluate JS once
        if let js = jsToEvaluate {
            webView.evaluateJavaScript(js)
            DispatchQueue.main.async {
                self.jsToEvaluate = nil
            }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        // local copies for trigger consumption
        var goBackTapped: Bool = false
        var goForwardTapped: Bool = false
        var reloadTapped: Bool = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func consume(_ flag: inout Bool) -> Bool {
            // This coordinator method is used by updateUIView, but the flags are in parent model.
            // We'll mirror them below in navigation callbacks.
            return false
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onNavigationEvent("didStart")
            syncState(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onNavigationEvent("didFinish")
            syncState(webView)
            parent.title = webView.title ?? ""
            parent.currentURLString = webView.url?.absoluteString ?? ""
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