import SwiftUI

private struct TapRipple: Identifiable {
    let id = UUID()
}

private struct RippleRingView: View {
    let accentColor: Color
    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(accentColor.opacity(expanded ? 0.0 : 0.45), lineWidth: expanded ? 1.5 : 3.0)
            .scaleEffect(expanded ? 1.24 : 0.94)
            .onAppear {
                withAnimation(.easeOut(duration: 0.42)) {
                    expanded = true
                }
            }
            .allowsHitTesting(false)
    }
}

private struct TasbihPadButtonStyle: ButtonStyle {
    let isDark: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .scaleEffect(pressed ? 0.945 : 1.0)
            .brightness(pressed ? (isDark ? 0.04 : -0.03) : 0.0)
            .shadow(
                color: accent.opacity(pressed ? 0.34 : (isDark ? 0.20 : 0.16)),
                radius: pressed ? 26 : 18,
                x: 0,
                y: pressed ? 4 : 10
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.68), value: pressed)
    }
}

struct TasbihButton: View {
    let cycleProgress: Double
    let isDark: Bool
    let onTap: () -> Void

    @State private var ripples: [TapRipple] = []

    private let buttonSize: CGFloat = 224
    private let ringSize: CGFloat = 248

    private var emeraldAccent: Color {
        isDark
            ? Color(red: 0.16, green: 0.80, blue: 0.54)
            : Color(red: 0.06, green: 0.56, blue: 0.38)
    }

    private var goldAccent: Color {
        Color(red: 0.84, green: 0.68, blue: 0.32)
    }

    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                RippleRingView(accentColor: emeraldAccent)
                    .frame(width: buttonSize, height: buttonSize)
                    .id(ripple.id)
            }

            // Subtle outer 33-bead track
            Circle()
                .stroke(
                    isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07),
                    lineWidth: 5
                )
                .frame(width: ringSize, height: ringSize)

            // Active 33-bead progress arc
            Circle()
                .trim(from: 0, to: cycleProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [emeraldAccent, goldAccent, emeraldAccent]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
                .animation(.spring(response: 0.25, dampingFraction: 0.82), value: cycleProgress)

            Button {
                triggerRipple()
                onTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(padGradient)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isDark ? 0.22 : 0.85),
                                            emeraldAccent.opacity(isDark ? 0.25 : 0.22),
                                            Color.black.opacity(isDark ? 0.35 : 0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    // Inner tactile groove ring
                    Circle()
                        .stroke(
                            emeraldAccent.opacity(isDark ? 0.24 : 0.18),
                            lineWidth: 1.2
                        )
                        .frame(width: 146, height: 146)

                    VStack(spacing: 12) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [goldAccent, emeraldAccent],
                                    center: .topLeading,
                                    startRadius: 1,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 16, height: 16)
                            .shadow(color: emeraldAccent.opacity(0.5), radius: 6)

                        Text("سبّح")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                isDark
                                    ? Color.white.opacity(0.76)
                                    : Color(red: 0.08, green: 0.24, blue: 0.18).opacity(0.78)
                            )
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(Circle())
            }
            .buttonStyle(TasbihPadButtonStyle(isDark: isDark, accent: emeraldAccent))
            .accessibilityLabel("زر التسبيح")
            .accessibilityHint("اضغط لزيادة العداد بواحد")
        }
        .frame(width: ringSize + 40, height: ringSize + 40)
    }

    private var padGradient: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.20, blue: 0.16),
                    Color(red: 0.04, green: 0.11, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.91, green: 0.95, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func triggerRipple() {
        let ripple = TapRipple()
        if ripples.count >= 4 {
            ripples.removeFirst()
        }
        ripples.append(ripple)

        let targetID = ripple.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            ripples.removeAll { $0.id == targetID }
        }
    }
}
