//
//  InAppBrowserView.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//

import Foundation
import SwiftUI
import WebKit
import Combine

struct InAppBrowserView: View {
    @StateObject private var model = BrowserModel()

    var body: some View {
        VStack(spacing: 0) {
            // URL bar
            HStack(spacing: 8) {
                TextField("Enter URL", text: $model.urlText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.loadFromBar() }

                Button("Go") { model.loadFromBar() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // WebView
            WebView(
                request: $model.request,
                canGoBack: $model.canGoBack,
                canGoForward: $model.canGoForward,
                title: $model.pageTitle,
                currentURLString: $model.currentURLString,
                onNavigationEvent: { event in
                    // You can log events or start tracking scrolling here
                    // print("Nav event: \(event)")
                },
                jsToEvaluate: $model.jsToEvaluate
            )
            .overlay(alignment: .topTrailing) {
                // Small exam-mode badge
                if model.examModeEnabled {
                    Text("Exam Mode")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.75))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(10)
                }
            }

            Divider()

            // Toolbar
            HStack(spacing: 16) {
                Button {
                    model.goBackTapped.toggle()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoBack)

                Button {
                    model.goForwardTapped.toggle()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoForward)

                Button {
                    model.reloadTapped.toggle()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Toggle("Exam Mode", isOn: $model.examModeEnabled)
                    .labelsHidden()

                Button {
                    model.openQuizNow()
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("Quiz now")
            }
            .padding()
        }
        .navigationTitle(model.pageTitle.isEmpty ? "Browser" : model.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
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
            model.start()
        }
        .onChange(of: model.currentURLString) { _, newURL in
            // Keep URL bar synced
            model.urlText = newURL
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

    // ✅ Explicit initializer fixes "no initializers"
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
