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

    /// ✅ Exam Mode is now owned by the view (or parent) instead of BrowserModel.
    @Binding private var examModeEnabled: Bool

    private let enableQuizTimer: Bool

    // Convenience init when caller doesn’t care (defaults ON)
    init(startURL: String, enableQuizTimer: Bool = true) {
        self._examModeEnabled = .constant(enableQuizTimer) // default ON for scrolling, OFF for canvas
        self.enableQuizTimer = enableQuizTimer
        _model = StateObject(wrappedValue: BrowserModel(startURL: startURL, enableQuizTimer: enableQuizTimer))
    }

    // Full init when caller wants to control examMode externally
    init(startURL: String, enableQuizTimer: Bool = true, examModeEnabled: Binding<Bool>) {
        self._examModeEnabled = examModeEnabled
        self.enableQuizTimer = enableQuizTimer
        _model = StateObject(wrappedValue: BrowserModel(startURL: startURL, enableQuizTimer: enableQuizTimer))
    }

    var body: some View {
        ZStack {
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

            if examModeEnabled {
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
        .onAppear {
            // ✅ Only start timer if this screen is allowed to quiz AND exam mode is on
            if enableQuizTimer && examModeEnabled {
                model.start()
            } else {
                model.stopTimer()
            }
        }
        .onChange(of: examModeEnabled) { _, newValue in
            // ✅ If user toggles exam mode, start/stop timer live
            guard enableQuizTimer else { return } // Canvas login never quizzes
            if newValue {
                model.start()
            } else {
                model.stopTimer()
                model.clearBlockOverlayIfNeeded()
            }
        }
        .onDisappear {
            model.stopTimer()
        }
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

    @Published var showQuiz: Bool = false

    @Published var goBackTapped: Bool = false
    @Published var goForwardTapped: Bool = false
    @Published var reloadTapped: Bool = false

    @Published var jsToEvaluate: String? = nil
    @Published var currentQuestion: QuizQuestion

    private let enableQuizTimer: Bool

    private var timer: Timer?
    private var secondsSpent: Int = 0
    private let triggerEverySeconds: Int = 25

    init(startURL: String = "https://www.instagram.com", enableQuizTimer: Bool = true) {
        self.urlText = startURL
        self.currentQuestion = .sample()
        self.enableQuizTimer = enableQuizTimer

        if let url = URL(string: startURL) {
            self.request = URLRequest(url: url)
            self.currentURLString = startURL
        } else {
            self.request = nil
            self.currentURLString = ""
        }
    }

    deinit { stopTimer() }

    func start() {
        stopTimer()
        guard enableQuizTimer else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard enableQuizTimer else { return }
        secondsSpent += 1
        if secondsSpent % triggerEverySeconds == 0 {
            openQuizNow()
        }
    }

    func openQuizNow() {
        guard enableQuizTimer else { return }
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

    func loadFromBar() {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text) else { return }
        request = URLRequest(url: url)
    }

    // ✅ Called when exam mode is toggled OFF to ensure we don’t leave page blocked.
    func clearBlockOverlayIfNeeded() {
        removeHardBlockOverlay()
        showQuiz = false
        secondsSpent = 0
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
