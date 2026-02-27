//
//  DashboardView.swift
//  DoomScholar
//
//  Created by Matthew Pun on 2/27/26.
//


import SwiftUI

struct DashboardView: View {
    @Environment(\.appTheme) private var theme

    // Mock metrics (swap with real tracking later)
    @State private var minutesScrolled: Int = 42
    @State private var minutesLearning: Int = 18
    @State private var questionsToday: Int = 24
    @State private var dayStreak: Int = 7

    @State private var selectedURL: String? = nil
    @State private var showCoursesSheet: Bool = false
    @State private var showSettingsSheet: Bool = false

    private let courses = DashboardMockData.courses
    private let appLinks = DashboardMockData.appLinks

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        topBar

                        greetingCard

                        statsGrid

                        conversionCard

                        appLinksSection

                        startScrollingButton

                        bottomPills
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedURL) { url in
                // You already have this implemented; keep the signature the same.
                InAppBrowserView(startURL: url)
            }
            .sheet(isPresented: $showCoursesSheet) {
                CoursesSheetView(courses: courses)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
                    .appTheme(theme) // keeps colors consistent
            }
        }
    }

    // MARK: - UI Blocks

    private var topBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.brandGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.white)
            }

            Text("DoomScholar")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 8)
    }

    private var greetingCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.brandGradient)
                .frame(height: 120)
                .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Hey there! 👋")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Ready to turn your scroll time into study time?")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 18)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(
                icon: "clock",
                iconTint: Color.purple,
                value: "\(minutesScrolled)",
                label: "Minutes Scrolled"
            )

            StatCard(
                icon: "brain.head.profile",
                iconTint: Color.blue,
                value: "\(minutesLearning)",
                label: "Minutes Learning"
            )

            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconTint: Color.green,
                value: "\(questionsToday)",
                label: "Questions Today"
            )

            StatCard(
                icon: "book.closed",
                iconTint: Color.orange,
                value: "\(dayStreak)",
                label: "Day Streak"
            )
        }
    }

    private var conversionCard: some View {
        let pct = minutesScrolled == 0 ? 0 : Int((Double(minutesLearning) / Double(minutesScrolled)) * 100)

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Conversion")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(pct)%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }

                ProgressView(value: Double(minutesLearning), total: Double(max(minutesScrolled, 1)))
                    .tint(Color.purple)

                Text("You've converted \(minutesLearning) out of \(minutesScrolled) minutes into learning!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var appLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Apps & Sites")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                // Quick access to Courses from here too
                Button("Courses") { showCoursesSheet = true }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }

            // “Chip” style buttons (click to open web view)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(appLinks) { item in
                    Button {
                        selectedURL = item.url
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.systemIcon)
                                .frame(width: 26, height: 26)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                                Text(item.url.replacingOccurrences(of: "https://www.", with: ""))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textSecondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }

    private var startScrollingButton: some View {
        Button {
            // Choose default (or show a picker). For now: open Instagram.
            selectedURL = "https://www.instagram.com"
        } label: {
            Text("Start Scrolling")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.primaryButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)
        }
        .padding(.top, 6)
    }

    private var bottomPills: some View {
        HStack(spacing: 12) {
            PillButton(title: "Courses", systemIcon: "book") {
                showCoursesSheet = true
            }
            PillButton(title: "Settings", systemIcon: "gearshape") {
                showSettingsSheet = true
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Components

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

private struct StatCard: View {
    @Environment(\.appTheme) private var theme

    let icon: String
    let iconTint: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(iconTint)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        .shadow(color: theme.shadow, radius: 10, x: 0, y: 8)
    }
}

private struct PillButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let systemIcon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheets (Mock)

private struct CoursesSheetView: View {
    let courses: [DashboardCourse]

    var body: some View {
        NavigationStack {
            List {
                ForEach(courses) { c in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(c.code) • \(c.name)")
                            .font(.headline)
                        Text(c.instructor)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Courses")
        }
    }
}



// Allows NavigationDestination with String
extension String: Identifiable {
    public var id: String { self }
}
