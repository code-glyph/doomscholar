import SwiftUI

struct CanvasLoginView: View {
    @Environment(\.appTheme) private var theme

    private let canvasURL = "https://psu.instructure.com/"

    // ✅ Persist across app launches
    @AppStorage("canvasLoggedIn") private var canvasLoggedIn: Bool = false

    @State private var goToCanvas = false
    @State private var goToDashboard = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer(minLength: 14)

                    header
                    heroCard
                    loginCard

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            // ✅ If already logged in, skip this screen
            .onAppear {
                if canvasLoggedIn {
                    // jump straight to dashboard
                    goToDashboard = true
                }
            }

            // 1) Push Canvas web login
            .navigationDestination(isPresented: $goToCanvas) {
                InAppBrowserView(
                    startURL: canvasURL,
                    enableQuizTimer: false,
                    examModeEnabled: .constant(false),
                    autoReturnToAppOnCanvasDashboard: true,
                    onAutoReturnFromCanvas: {
                        DispatchQueue.main.async {
                            // ✅ mark logged in persistently
                            canvasLoggedIn = true

                            goToCanvas = false
                            goToDashboard = true
                        }
                    }
                )
                .toolbar(.hidden, for: .navigationBar)
            }

            // 2) After login, push DoomScholar dashboard
            .navigationDestination(isPresented: $goToDashboard) {
                DashboardView()
                    .appTheme(AppTheme())
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.brandGradient)
                    .frame(width: 68, height: 68)
                    .shadow(color: theme.shadow, radius: 16, x: 0, y: 10)

                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("DoomScholar")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text("Turn scroll time into study time.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.top, 6)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.brandGradient)
                .frame(height: 120)
                .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Connect Canvas")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Sign in to Penn State Canvas to import courses.\n(We’ll wire the API later.)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(3)
            }
            .padding(18)
        }
    }

    // MARK: - Login Card

    private var loginCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    iconBadge(systemName: "link", tint: .purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Canvas Domain")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)

                        Text("psu.instructure.com")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Button {
                    // If already logged in, skip opening Canvas again
                    if canvasLoggedIn {
                        goToDashboard = true
                    } else {
                        goToCanvas = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .bold))

                        Text(canvasLoggedIn ? "Continue to Dashboard" : "Continue with Canvas")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primaryButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: theme.shadow, radius: 14, x: 0, y: 10)
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.textSecondary)

                    Text(canvasLoggedIn
                         ? "Canvas is connected on this device."
                         : "You’ll sign in inside DoomScholar. After login we’ll return to your dashboard.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }

                // ✅ Optional: add a mock logout/reset for testing
                if canvasLoggedIn {
                    Button {
                        canvasLoggedIn = false
                    } label: {
                        Text("Disconnect Canvas")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
        }
    }

    // MARK: - UI Helpers

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
}

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
