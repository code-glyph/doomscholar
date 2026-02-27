//
//  InAppBrowserView.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//

import SwiftUI
import WebKit
import Foundation
import Combine

struct InAppBrowserView: View {
    @StateObject private var model: BrowserModel

    init(startURL: String) {
        _model = StateObject(wrappedValue: BrowserModel(startURL: startURL))
    }

    var body: some View {
        ZStack {
            // Full-screen website content
            WebView(
                request: $model.request,
                canGoBack: $model.canGoBack,
                canGoForward: $model.canGoForward,
                title: $model.pageTitle,
                currentURLString: $model.currentURLString,
                goBackTapped: $model.goBackTapped,
                goForwardTapped: $model.goForwardTapped,
                reloadTapped: $model.reloadTapped,
                jsToEvaluate: $model.jsToEvaluate
            )
            .ignoresSafeArea()

            // Optional: tiny status overlay (remove if you want *zero* UI)
            if model.examModeEnabled {
                VStack {
                    HStack {
                        Spacer()
                        Text("Exam Mode")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.75))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .padding(.trailing, 14)
                            .padding(.top, 12)
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
        }
//        .toolbar(.hidden, for: .navigationBar)  hides iOS navigation bar if pushed in NavigationStack
        .sheet(isPresented: $model.showQuiz) {
            QuizGateView(
                question: model.currentQuestion,
                onSubmit: { isCorrect in
                    model.handleQuizResult(isCorrect: isCorrect)
                },
                onReview: {
                    model.openReview()
                }
            )
        }
        .onAppear { model.start() }
    }
}

// MARK: - ViewModel

final class BrowserModel: ObservableObject {
    @Published var urlText: String
    @Published var request: URLRequest?

    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    @Published var pageTitle: String = ""
    @Published var currentURLString: String = ""

    @Published var examModeEnabled: Bool = true
    @Published var showQuiz: Bool = false

    @Published var goBackTapped: Bool = false
    @Published var goForwardTapped: Bool = false
    @Published var reloadTapped: Bool = false

    @Published var jsToEvaluate: String? = nil
    @Published var currentQuestion: QuizQuestion

    private var timer: Timer?
    private var secondsSpent: Int = 0
    private let triggerEverySeconds: Int = 25

    init(startURL: String = "https://www.instagram.com") {
        self.urlText = startURL
        self.currentQuestion = .sample()

        if let url = URL(string: startURL) {
            self.request = URLRequest(url: url)
            self.currentURLString = startURL
        } else {
            self.request = nil
            self.currentURLString = ""
        }
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard examModeEnabled else { return }
        secondsSpent += 1
        if secondsSpent % triggerEverySeconds == 0 {
            openQuizNow()
        }
    }

    func loadFromBar() {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text) else { return }
        request = URLRequest(url: url)
    }

    func openQuizNow() {
        injectHardBlockOverlay()
        currentQuestion = .sample()
        showQuiz = true
    }

    func handleQuizResult(isCorrect: Bool) {
        if isCorrect {
            removeHardBlockOverlay()
            secondsSpent = 0
            showQuiz = false
        } else {
            // keep blocked; user can review + retry
        }
    }

    func openReview() {
        urlText = "https://example.com/review"
        loadFromBar()
    }

    private func injectHardBlockOverlay() {
        jsToEvaluate = """
        (function() {
          if (document.getElementById('examBlockerOverlay')) return;
          var overlay = document.createElement('div');
          overlay.id = 'examBlockerOverlay';
          overlay.style.position = 'fixed';
          overlay.style.top = '0';
          overlay.style.left = '0';
          overlay.style.width = '100%';
          overlay.style.height = '100%';
          overlay.style.zIndex = '2147483647';
          overlay.style.background = 'rgba(0,0,0,0.75)';
          overlay.style.display = 'flex';
          overlay.style.alignItems = 'center';
          overlay.style.justifyContent = 'center';
          overlay.style.color = 'white';
          overlay.style.fontSize = '18px';
          overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
          overlay.innerText = 'Quiz time — answer in the app to continue';
          document.body.appendChild(overlay);
          document.documentElement.style.overflow = 'hidden';
          document.body.style.overflow = 'hidden';
        })();
        """
    }

    private func removeHardBlockOverlay() {
        jsToEvaluate = """
        (function() {
          var overlay = document.getElementById('examBlockerOverlay');
          if (overlay) overlay.remove();
          document.documentElement.style.overflow = '';
          document.body.style.overflow = '';
        })();
        """
    }
}
