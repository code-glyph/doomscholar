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
    let reviewSnippet: String

    static func sample() -> QuizQuestion {
        QuizQuestion(
            prompt: "What does TCP stand for?",
            choices: ["Transfer Control Protocol", "Transmission Control Protocol", "Transport Copy Process", "Trusted Connection Path"],
            correctIndex: 1,
            reviewSnippet: "TCP = Transmission Control Protocol. It's a core protocol of the Internet protocol suite..."
        )
    }
}

struct QuizGateView: View {
    let question: QuizQuestion
    let onSubmit: (Bool) -> Void
    let onReview: () -> Void

    @State private var selected: Int? = nil
    @State private var showWrong: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Quiz")
                    .font(.title2.weight(.bold))

                Text(question.prompt)
                    .font(.headline)

                VStack(spacing: 10) {
                    ForEach(question.choices.indices, id: \.self) { i in
                        Button {
                            selected = i
                        } label: {
                            HStack {
                                Text(question.choices[i])
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected == i {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }

                if showWrong {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review this section")
                            .font(.headline)
                        Text(question.reviewSnippet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Open Review") {
                            onReview()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 6)
                }

                Spacer()

                Button {
                    guard let selected else { return }
                    let correct = (selected == question.correctIndex)
                    if correct {
                        onSubmit(true)
                    } else {
                        showWrong = true
                        onSubmit(false) // keep blocked
                    }
                } label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected == nil)
            }
            .padding()
            .navigationTitle("Exam Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}