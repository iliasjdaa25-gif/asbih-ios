import SwiftUI

@MainActor
final class TasbihViewModel: ObservableObject {
    private enum Keys {
        static let countDigits = "tasbih_count_digits"
        static let hapticEnabled = "tasbih_haptic_enabled"
        static let soundEnabled = "tasbih_sound_enabled"
        static let isDarkMode = "tasbih_dark_mode"
    }

    @Published private(set) var counter: BigCounter
    @Published var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: Keys.hapticEnabled) }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    @Published var isDarkMode: Bool {
        didSet { defaults.set(isDarkMode, forKey: Keys.isDarkMode) }
    }

    private let defaults: UserDefaults
    private let feedback = FeedbackEngine()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedDigits = defaults.string(forKey: Keys.countDigits) ?? "0"
        self.counter = BigCounter(savedDigits)
        self.hapticEnabled = defaults.object(forKey: Keys.hapticEnabled) as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.isDarkMode = defaults.object(forKey: Keys.isDarkMode) as? Bool ?? true
    }

    func increment() {
        counter.increment()
        defaults.set(counter.rawDigits, forKey: Keys.countDigits)
        feedback.triggerTap(
            hapticEnabled: hapticEnabled,
            soundEnabled: soundEnabled,
            isMilestone: counter.isHundredMilestone
        )
    }

    func decrement() {
        guard !counter.isZero else { return }
        counter.decrement()
        defaults.set(counter.rawDigits, forKey: Keys.countDigits)
        feedback.triggerTap(
            hapticEnabled: hapticEnabled,
            soundEnabled: false,
            isMilestone: false
        )
    }

    func reset() {
        counter.reset()
        defaults.set(counter.rawDigits, forKey: Keys.countDigits)
    }

    func prepareFeedback() {
        feedback.prepare()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TasbihViewModel()
    @State private var showResetConfirmation = false
    @State private var numberBump = false
    @State private var bumpGeneration = 0

    private var emeraldAccent: Color {
        viewModel.isDarkMode
            ? Color(red: 0.16, green: 0.80, blue: 0.54)
            : Color(red: 0.06, green: 0.56, blue: 0.38)
    }

    private var primaryText: Color {
        viewModel.isDarkMode
            ? Color.white
            : Color(red: 0.07, green: 0.14, blue: 0.11)
    }

    private var secondaryText: Color {
        viewModel.isDarkMode
            ? Color.white.opacity(0.56)
            : Color(red: 0.15, green: 0.26, blue: 0.21).opacity(0.62)
    }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 22)
                    .padding(.top, 12)

                Spacer(minLength: 20)

                counterDisplay
                    .padding(.horizontal, 24)

                Spacer(minLength: 20)

                TasbihButton(
                    cycleProgress: viewModel.counter.cycleProgress33,
                    isDark: viewModel.isDarkMode
                ) {
                    viewModel.increment()
                    triggerNumberBump()
                }

                Spacer(minLength: 20)

                bottomBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 22)
            }
        }
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .onAppear {
            viewModel.prepareFeedback()
        }
        .alert("تصفير العداد؟", isPresented: $showResetConfirmation) {
            Button("إلغاء", role: .cancel) {}
            Button("تصفير", role: .destructive) {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.reset()
                }
            }
        } message: {
            Text("سيتم إرجاع العداد إلى 0 ولا يمكن التراجع عن ذلك.")
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            if viewModel.isDarkMode {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.07, blue: 0.05),
                        Color(red: 0.03, green: 0.09, blue: 0.07),
                        Color(red: 0.01, green: 0.04, blue: 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        emeraldAccent.opacity(0.14),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.56),
                    startRadius: 20,
                    endRadius: 340
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.98, blue: 0.97),
                        Color(red: 0.92, green: 0.95, blue: 0.93)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        emeraldAccent.opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.56),
                    startRadius: 20,
                    endRadius: 320
                )
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("مسبحة")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text("عدّاد لا نهائي ∞")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            HStack(spacing: 10) {
                ControlPillButton(
                    systemImage: viewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isActive: viewModel.soundEnabled,
                    isDark: viewModel.isDarkMode,
                    accent: emeraldAccent,
                    accessibilityLabel: viewModel.soundEnabled ? "إيقاف الصوت" : "تشغيل الصوت"
                ) {
                    viewModel.soundEnabled.toggle()
                }

                ControlPillButton(
                    systemImage: viewModel.hapticEnabled ? "iphone.radiowaves.left.and.right" : "hand.tap",
                    isActive: viewModel.hapticEnabled,
                    isDark: viewModel.isDarkMode,
                    accent: emeraldAccent,
                    accessibilityLabel: viewModel.hapticEnabled ? "إيقاف الاهتزاز" : "تشغيل الاهتزاز"
                ) {
                    viewModel.hapticEnabled.toggle()
                }

                ControlPillButton(
                    systemImage: viewModel.isDarkMode ? "sun.max.fill" : "moon.fill",
                    isActive: false,
                    isDark: viewModel.isDarkMode,
                    accent: emeraldAccent,
                    accessibilityLabel: viewModel.isDarkMode ? "الوضع النهاري" : "الوضع الليلي"
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.isDarkMode.toggle()
                    }
                }
            }
        }
    }

    private var counterDisplay: some View {
        let formatted = viewModel.counter.formatted
        let isVeryLong = formatted.count > 16
        let cycleStep = viewModel.counter.isZero
            ? 0
            : (viewModel.counter.remainder(modulo: 33) == 0 ? 33 : viewModel.counter.remainder(modulo: 33))

        return VStack(spacing: 12) {
            Text(formatted)
                .font(.system(size: isVeryLong ? 42 : 70, weight: .bold, design: .rounded))
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(isVeryLong ? 3 : 1)
                .minimumScaleFactor(isVeryLong ? 0.45 : 0.28)
                .scaleEffect(numberBump ? 1.04 : 1.0)
                .animation(.spring(response: 0.16, dampingFraction: 0.65), value: numberBump)
                .accessibilityLabel("العدد الحالي \(formatted)")

            HStack(spacing: 6) {
                Circle()
                    .fill(emeraldAccent)
                    .frame(width: 6, height: 6)
                Text("الدورة: \(cycleStep) / 33")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
            )
            .opacity(viewModel.counter.isZero ? 0.45 : 1.0)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                viewModel.decrement()
            } label: {
                Label("تراجع", systemImage: "minus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(viewModel.counter.isZero ? secondaryText.opacity(0.45) : primaryText.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(viewModel.isDarkMode ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                    )
            }
            .disabled(viewModel.counter.isZero)
            .accessibilityLabel("إنقاص بواحد")

            Spacer()

            Button {
                showResetConfirmation = true
            } label: {
                Label("تصفير", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(viewModel.counter.isZero ? secondaryText.opacity(0.45) : primaryText.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(viewModel.isDarkMode ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                    )
            }
            .disabled(viewModel.counter.isZero)
            .accessibilityLabel("تصفير العداد")
        }
    }

    private func triggerNumberBump() {
        bumpGeneration += 1
        let current = bumpGeneration
        numberBump = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if bumpGeneration == current {
                numberBump = false
            }
        }
    }
}

private struct ControlPillButton: View {
    let systemImage: String
    let isActive: Bool
    let isDark: Bool
    let accent: Color
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    isActive
                        ? accent
                        : (isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.60))
                )
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            isActive
                                ? accent.opacity(isDark ? 0.18 : 0.14)
                                : (isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isActive ? accent.opacity(0.35) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
