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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: BrowserModel

    // Settings (persisted)
    @AppStorage("qs_questionsPerInterrupt") private var questionsPerInterrupt: Int = 3
    @AppStorage("qs_frequencySeconds") private var frequencySeconds: Int = 10   // UI currently shows "10s", so treat as seconds

    /// Exam Mode is owned by the view (or parent) instead of BrowserModel.
    @Binding private var examModeEnabled: Bool

    private let enableQuizTimer: Bool

    // Canvas auto-return
    private let autoReturnToAppOnCanvasDashboard: Bool
    private let onAutoReturnFromCanvas: (() -> Void)?
    @State private var didAutoReturn = false

    // Convenience init when caller doesn’t care (defaults ON)
    init(
        startURL: String,
        enableQuizTimer: Bool = true,
        autoReturnToAppOnCanvasDashboard: Bool = false,
        onAutoReturnFromCanvas: (() -> Void)? = nil
    ) {
        self._examModeEnabled = .constant(enableQuizTimer) // ON for scrolling, OFF for canvas
        self.enableQuizTimer = enableQuizTimer
        self.autoReturnToAppOnCanvasDashboard = autoReturnToAppOnCanvasDashboard
        self.onAutoReturnFromCanvas = onAutoReturnFromCanvas
        _model = StateObject(
            wrappedValue: BrowserModel(
                startURL: startURL,
                enableQuizTimer: enableQuizTimer
            )
        )
    }

    // Full init when caller wants to control examMode externally
    init(
        startURL: String,
        enableQuizTimer: Bool = true,
        examModeEnabled: Binding<Bool>,
        autoReturnToAppOnCanvasDashboard: Bool = false,
        onAutoReturnFromCanvas: (() -> Void)? = nil
    ) {
        self._examModeEnabled = examModeEnabled
        self.enableQuizTimer = enableQuizTimer
        self.autoReturnToAppOnCanvasDashboard = autoReturnToAppOnCanvasDashboard
        self.onAutoReturnFromCanvas = onAutoReturnFromCanvas
        _model = StateObject(
            wrappedValue: BrowserModel(
                startURL: startURL,
                enableQuizTimer: enableQuizTimer
            )
        )
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
                    // ✅ Settings-driven multi-question interruption
                    if isCorrect {
                        model.markOneQuestionCorrect()
                    } else {
                        // keep blocked; do nothing (QuizGateView handles explanation UI)
                        model.handleQuizResult(isCorrect: false)
                    }
                },
                onReview: {
                    // your QuizGateView now shows explanation inline on wrong;
                    // leaving this hook for later deep review
                    model.openReview()
                }
            )
        }
        .onAppear {
            // ✅ Apply settings immediately
            model.updateSettings(
                questionsPerInterrupt: questionsPerInterrupt,
                frequencySeconds: frequencySeconds
            )

            // Only start timers if allowed AND exam mode is on
            if enableQuizTimer && examModeEnabled {
                model.start()
            } else {
                model.stopTimer()
            }
        }
        // ✅ If user changes settings while browsing, apply live
        .onChange(of: questionsPerInterrupt) { _, newVal in
            model.updateSettings(
                questionsPerInterrupt: newVal,
                frequencySeconds: frequencySeconds
            )
        }
        .onChange(of: frequencySeconds) { _, newVal in
            model.updateSettings(
                questionsPerInterrupt: questionsPerInterrupt,
                frequencySeconds: newVal
            )
        }
        .onChange(of: examModeEnabled) { _, newValue in
            // If user toggles exam mode, start/stop timers live
            guard enableQuizTimer else { return } // Canvas login never quizzes
            if newValue {
                model.start()
            } else {
                model.stopTimer()
                model.clearBlockOverlayIfNeeded()
            }
        }
        // Canvas: auto-return once user hits the Canvas dashboard
        .onChange(of: model.currentURLString) { _, newURL in
            guard autoReturnToAppOnCanvasDashboard else { return }
            guard !didAutoReturn else { return }

            if isCanvasLoggedInLanding(urlString: newURL, pageTitle: model.pageTitle) {
                didAutoReturn = true
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    onAutoReturnFromCanvas?()
                }
            }
        }
        .onDisappear {
            model.stopTimer()
        }
    }

    private func isCanvasLoggedInLanding(urlString: String, pageTitle: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard let host = url.host?.lowercased(), host.contains("instructure.com") else { return false }

        let path = url.path.lowercased()
        let full = urlString.lowercased()
        let title = pageTitle.lowercased()

        if path.contains("/dashboard") { return true }
        if path.contains("/courses") { return true }
        if path.contains("/profile") { return true }
        if title.contains("dashboard") { return true }
        if full.contains("dashboard") { return true }

        return false
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

    // ✅ settings-driven: how many remain in current interruption
    @Published var remainingQuestions: Int = 1

    private let enableQuizTimer: Bool

    // Quiz interrupt timer
    private var quizTimer: Timer?
    private var secondsSpent: Int = 0

    // ✅ Settings-driven controls
    private var quizIntervalSeconds: Int = 10
    private var configuredQuestionsPerInterrupt: Int = 3

    // Question fetch polling
    private var fetchTimer: Timer?
    private var isFetching: Bool = false
    private let fetchEverySeconds: Int = 15
    private let questionsEndpoint = URL(string: "https://doomscholar-production.up.railway.app/questions")!

    // Buffer incoming question while user is answering
    private var pendingQuestion: QuizQuestion? = nil

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

    deinit { stopAll() }

    // ✅ Apply SettingsView values
    func updateSettings(questionsPerInterrupt: Int, frequencySeconds: Int) {
        configuredQuestionsPerInterrupt = max(1, questionsPerInterrupt)

        // If you later interpret the UI as minutes, do:
        // quizIntervalSeconds = max(5, frequencyMinutes * 60)
        quizIntervalSeconds = max(5, frequencySeconds)

        // Reset cadence so new settings take effect quickly
        secondsSpent = 0
    }

    func start() {
        stopAll()
        guard enableQuizTimer else { return }

        quizTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickQuiz()
        }

        fetchLatestQuestion()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(fetchEverySeconds), repeats: true) { [weak self] _ in
            self?.fetchLatestQuestion()
        }
    }

    func stopTimer() { stopAll() }

    private func stopAll() {
        quizTimer?.invalidate()
        quizTimer = nil
        fetchTimer?.invalidate()
        fetchTimer = nil
        isFetching = false
    }

    private func tickQuiz() {
        guard enableQuizTimer else { return }
        if showQuiz { return } // don’t spawn another popup while answering

        secondsSpent += 1
        if secondsSpent % quizIntervalSeconds == 0 {
            openQuizNow()
        }
    }

    func openQuizNow() {
        guard enableQuizTimer else { return }
        guard !showQuiz else { return }

        // Use the newest pending question, if available
        if let pending = pendingQuestion {
            currentQuestion = pending
            pendingQuestion = nil
        }

        remainingQuestions = configuredQuestionsPerInterrupt
        injectHardBlockOverlay()
        showQuiz = true
    }

    // ✅ Called when the user answers ONE question correctly.
    // If more remain, keep the sheet open and swap to the next question.
    func markOneQuestionCorrect() {
        guard showQuiz else { return }

        remainingQuestions = max(0, remainingQuestions - 1)

        if remainingQuestions == 0 {
            // done with this interruption
            removeHardBlockOverlay()
            secondsSpent = 0
            showQuiz = false

            // if we got a new question mid-quiz, apply it for next time
            if let pending = pendingQuestion {
                currentQuestion = pending
                pendingQuestion = nil
            }
            return
        }

        // Still need more correct answers in this interruption:
        // Move to next question if we have one buffered; otherwise keep current (or fallback)
        if let pending = pendingQuestion {
            currentQuestion = pending
            pendingQuestion = nil
        }
        // else: keep the same question until next fetch arrives (no jarring refresh)
    }

    // Keep this for wrong answers (no dismiss)
    func handleQuizResult(isCorrect: Bool) {
        if isCorrect {
            // If any code path still calls this, treat it as a single-correct step.
            markOneQuestionCorrect()
        } else {
            // keep blocked; QuizGateView shows explanation UI
        }
    }

    private func fetchLatestQuestion() {
        guard enableQuizTimer else { return }
        guard !isFetching else { return }
        isFetching = true

        var req = URLRequest(url: questionsEndpoint)
        req.httpMethod = "GET"
        req.timeoutInterval = 15

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            defer { self?.isFetching = false }
            guard let self else { return }
            guard error == nil, let data else { return }

            do {
                let decoded = try JSONDecoder().decode(QuestionAPIResponse.self, from: data)
                let newQuestion = QuizQuestion.fromAPI(decoded)

                DispatchQueue.main.async {
                    // Don’t refresh while answering — buffer it
                    if self.showQuiz {
                        self.pendingQuestion = newQuestion
                    } else {
                        self.currentQuestion = newQuestion
                    }
                }
            } catch {
                // optional: print("Decode error:", error)
            }
        }.resume()
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

    func clearBlockOverlayIfNeeded() {
        removeHardBlockOverlay()
        showQuiz = false
        secondsSpent = 0
        // keep pendingQuestion for next time
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
