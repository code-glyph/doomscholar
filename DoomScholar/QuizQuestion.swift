//
//  QuizQuestion.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//


import SwiftUI

struct QuizQuestion {
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String

    var correctAnswerText: String {
        guard choices.indices.contains(correctIndex) else { return "" }
        return choices[correctIndex]
    }

    static func sample() -> QuizQuestion {
        QuizQuestion(
            prompt: "Which sorting algorithm runs the fastest?",
            choices: ["Miracle Sort", "Stalin Sort", "Sleep Sort", "Bogo Sort"],
            correctIndex: 1,
            explanation: """
Stalin Sort runs in O(n) because it simply deletes any element that is out of order. While Miracle Sort waits for a cosmic miracle O(∞), Sleep Sort depends on thread delays, and Bogo Sort shuffles randomly O(n * n!), Stalin Sort is the only one that guarantees a 'sorted' (albeit decimated) list in a single pass.
"""
        )
    }
}

import SwiftUI

struct QuizGateView: View {
    let question: QuizQuestion
    let onSubmit: (Bool) -> Void      // call true only when done + unblock
    let onReview: () -> Void          // kept for later; not used for wrong in this version

    @State private var selectedIndex: Int? = nil
    @State private var hasSubmitted: Bool = false
    @State private var wasCorrect: Bool = false

    // ✅ New: reveal explanation only when user requests (wrong answer flow)
    @State private var showExplanation: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Check")
                        .font(.title2.bold())
                    Text(question.prompt)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                choicesList

                // ✅ Show explanation block:
                // - immediately if correct
                // - only after tapping "Show Explanation" if wrong
                if hasSubmitted && (wasCorrect || showExplanation) {
                    explanationBlock
                }

                Spacer()

                footerButtons
            }
            .padding(18)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 18, weight: .bold))
            Text("DoomScholar")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Spacer()
        }
        .foregroundStyle(.primary)
    }

    private var choicesList: some View {
        VStack(spacing: 10) {
            ForEach(question.choices.indices, id: \.self) { idx in
                ChoiceRow(
                    text: question.choices[idx],
                    isSelected: selectedIndex == idx,
                    state: rowState(for: idx)
                )
                .onTapGesture {
                    guard !hasSubmitted else { return }
                    selectedIndex = idx
                }
            }
        }
        .padding(.top, 6)
    }

    private func rowState(for idx: Int) -> ChoiceRow.State {
        guard hasSubmitted else { return .normal }

        if idx == question.correctIndex { return .correct }
        if selectedIndex == idx && idx != question.correctIndex { return .wrong }
        return .normal
    }

    private var explanationBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: wasCorrect ? "checkmark.seal.fill" : "info.circle.fill")
                    .foregroundStyle(wasCorrect ? .green : .blue)
                Text(wasCorrect ? "Correct — here’s why" : "Explanation")
                    .font(.headline)
            }

            HStack(alignment: .top, spacing: 10) {
                Text("Correct answer:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(question.choices[question.correctIndex])
                    .font(.subheadline.weight(.semibold))
            }

            if !question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(question.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((wasCorrect ? Color.green : Color.blue).opacity(0.35), lineWidth: 1)
        )
        .padding(.top, 6)
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            if hasSubmitted && wasCorrect {
                // ✅ Correct: show "Back to Scrolling"
                Button {
                    onSubmit(true)
                } label: {
                    Text("Back to Scrolling")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                // Submit (or Try Again)
                Button {
                    submit()
                } label: {
                    Text(hasSubmitted ? "Try Again" : "Submit")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedIndex == nil ? Color.gray : Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedIndex == nil)

                // ✅ Wrong answer controls
                if hasSubmitted && !wasCorrect {
                    HStack(spacing: 10) {
                        Button {
                            // ✅ Show explanation inline instead of opening review page
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showExplanation = true
                            }
                        } label: {
                            Text(showExplanation ? "Explanation Shown" : "Show Explanation")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(showExplanation)

                        Button {
                            // Reset for another attempt
                            hasSubmitted = false
                            wasCorrect = false
                            showExplanation = false
                            selectedIndex = nil
                        } label: {
                            Text("Reset")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
        }
    }

    private func submit() {
        guard let selectedIndex else { return }

        // If user taps "Try Again" after wrong, we reset selection (optional behavior)
        if hasSubmitted && !wasCorrect {
            hasSubmitted = false
            wasCorrect = false
            showExplanation = false
            self.selectedIndex = nil
            return
        }

        let correct = (selectedIndex == question.correctIndex)
        hasSubmitted = true
        wasCorrect = correct

        if correct {
            // ✅ show explanation immediately for correct flow
            showExplanation = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            // ✅ keep blocked; explanation hidden until user taps the button
            showExplanation = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - ChoiceRow

private struct ChoiceRow: View {
    enum State { case normal, correct, wrong }

    let text: String
    let isSelected: Bool
    let state: State

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(borderColor)
                        .frame(width: 12, height: 12)
                }
            }

            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if state == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if state == .wrong && isSelected {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var borderColor: Color {
        switch state {
        case .normal:
            return isSelected ? .purple : Color(.systemGray3)
        case .correct:
            return .green
        case .wrong:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:
            return Color(.secondarySystemBackground)
        case .correct:
            return Color.green.opacity(0.12)
        case .wrong:
            return (isSelected ? Color.red.opacity(0.12) : Color(.secondarySystemBackground))
        }
    }
}
