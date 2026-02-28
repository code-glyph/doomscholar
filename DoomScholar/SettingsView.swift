//
//  SettingsView.swift
//  DoomScholar
//
//  Created by Matthew Pun on 2/27/26.
//


import SwiftUI

struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    // Persisted (works great for hackathon)
    @AppStorage("qs_questionsPerInterrupt") private var questionsPerInterrupt: Int = 3
    @AppStorage("qs_frequencyMinutes") private var frequencyMinutes: Int = 10

    // UI state
    @State private var didSave = false

    private let questionOptions = [1, 3, 5]
    private let frequencyOptions = [5, 10, 15]

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    Text("Quiz Settings")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 16)

                    Card {
                        VStack(alignment: .leading, spacing: 18) {

                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    iconBadge(systemName: "questionmark.circle", tint: .purple)
                                    Text("Questions Per Interruption")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }

                                OptionPills(
                                    options: questionOptions.map { "\($0)" },
                                    selectedIndex: questionOptions.firstIndex(of: questionsPerInterrupt) ?? 1,
                                    selectedGradient: theme.brandGradient
                                ) { idx in
                                    questionsPerInterrupt = questionOptions[idx]
                                }

                                Text("Number of questions you’ll answer before continuing to scroll")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                            }

                            Divider().opacity(0.35)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    iconBadge(systemName: "clock", tint: .blue)
                                    Text("Quiz Frequency")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }

                                OptionPills(
                                    options: frequencyOptions.map { "\($0)m" },
                                    selectedIndex: frequencyOptions.firstIndex(of: frequencyMinutes) ?? 1,
                                    selectedGradient: theme.brandGradient
                                ) { idx in
                                    frequencyMinutes = frequencyOptions[idx]
                                }

                                Text("How often quiz interruptions appear while scrolling")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    impactCard
                        .padding(.horizontal, 16)
//
//                    quickPresets
//                        .padding(.horizontal, 16)

                    Button {
                        // mock save (AppStorage already persists)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            didSave = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            didSave = false
                        }
                    } label: {
                        Text(didSave ? "Saved ✓" : "Save Settings")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.primaryButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                    Spacer(minLength: 18)
                }
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Impact

    private var impactCard: some View {
        // questions per hour = (60 / freq) * questions
        let qph = Int((60.0 / Double(max(frequencyMinutes, 1))) * Double(questionsPerInterrupt))

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.brandGradient)
                .frame(height: 170)
                .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.white)
                    Text("Your Study Impact")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("With your current settings, you’ll answer approximately:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.18))
                    .frame(height: 62)
                    .overlay(
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(qph)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("questions per hour of scrolling")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(.horizontal, 16),
                        alignment: .leading
                    )
            }
            .padding(18)
        }
    }

    // MARK: - Presets

    private var quickPresets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            HStack(spacing: 12) {
                presetCard(
                    title: "Intense",
                    subtitle: "5q / 5m",
                    border: .red.opacity(0.45),
                    onTap: {
                        questionsPerInterrupt = 5
                        frequencyMinutes = 5
                    }
                )

                presetCard(
                    title: "Balanced",
                    subtitle: "3q / 10m",
                    border: .yellow.opacity(0.55),
                    onTap: {
                        questionsPerInterrupt = 3
                        frequencyMinutes = 10
                    }
                )

                presetCard(
                    title: "Light",
                    subtitle: "1q / 15m",
                    border: .green.opacity(0.45),
                    onTap: {
                        questionsPerInterrupt = 1
                        frequencyMinutes = 15
                    }
                )
            }
        }
    }

    // MARK: - Components

    private func iconBadge(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: systemName)
                .foregroundStyle(tint)
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private func presetCard(title: String, subtitle: String, border: Color, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(border, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable UI

private struct Card<Content: View>: View {
    @Environment(\.appTheme) private var theme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
            .shadow(color: theme.shadow, radius: 10, x: 0, y: 8)
    }
}

/// Pill selector like the screenshot (1 / 3 / 5, 5m / 10m / 15m)
private struct OptionPills: View {
    @Environment(\.appTheme) private var theme

    let options: [String]
    let selectedIndex: Int
    let selectedGradient: LinearGradient
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    onSelect(idx)
                } label: {
                    Text(options[idx])
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(idx == selectedIndex ? Color.white : theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Group {
                                if idx == selectedIndex {
                                    selectedGradient
                                } else {
                                    Color(.systemGray6)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
