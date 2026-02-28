//
//  WebView.swift
//  DoomScholar
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var request: URLRequest?

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var title: String
    @Binding var currentURLString: String

    @Binding var goBackTapped: Bool
    @Binding var goForwardTapped: Bool
    @Binding var reloadTapped: Bool

    var onNavigationEvent: (String) -> Void = { _ in }

    @Binding var jsToEvaluate: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // ✅ Only load when *our binding* changes (prevents redirect reload loops)
        if let req = request, let reqURL = req.url {
            if context.coordinator.lastExternallyLoadedURL != reqURL {
                context.coordinator.lastExternallyLoadedURL = reqURL
                onNavigationEvent("externalLoad: \(reqURL.absoluteString)")
                webView.load(req)
            }
        }

        // Toolbar triggers
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

        // One-shot JS
        if let js = jsToEvaluate {
            webView.evaluateJavaScript(js)
            DispatchQueue.main.async { self.jsToEvaluate = nil }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastExternallyLoadedURL: URL? = nil

        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onNavigationEvent("didStart")
            sync(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onNavigationEvent("didFinish")
            sync(webView)
            DispatchQueue.main.async {
                self.parent.title = webView.title ?? ""
                self.parent.currentURLString = webView.url?.absoluteString ?? ""
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onNavigationEvent("didFail: \(error.localizedDescription)")
            sync(webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onNavigationEvent("didFailProvisional: \(error.localizedDescription)")
            sync(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        private func sync(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.currentURLString = webView.url?.absoluteString ?? self.parent.currentURLString
            }
        }
    }
}
