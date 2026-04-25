import SwiftUI
import Combine

struct LightModeErrorView: View {
    let initialCountdown: Int
    var onComplete: () -> Void

    @State private var countdown: Int
    @State private var finished = false

    private let penaltyKey = "lmPenalty"
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let insult = "Congratulations. You found the light mode.\nUnfortunately, light mode is for people who\nwear sunglasses indoors and eat salad for fun.\nYou are clearly better than that.\n\nReturning you to civilisation..."

    init(initialCountdown: Int, onComplete: @escaping () -> Void) {
        self.initialCountdown = initialCountdown
        self.onComplete = onComplete
        _countdown = State(initialValue: max(initialCountdown, 1))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(.orange)
                }

                VStack(spacing: 12) {
                    Text("Light Mode Unavailable")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("Error 0x4C494748: BLINDING_LIGHT_DETECTED")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.gray.opacity(0.7))
                }

                Text(insult)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    Text("App closes in")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.gray)

                    ZStack {
                        Circle()
                            .stroke(Color.orange.opacity(0.2), lineWidth: 5)
                            .frame(width: 72, height: 72)

                        Circle()
                            .trim(from: 0, to: CGFloat(countdown) / CGFloat(initialCountdown))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: countdown)

                        Text("\(countdown)")
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }

                    Text("seconds")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.gray)
                }

                Spacer()

                // Force close button — adds 30 sec penalty then exits immediately
                Button(action: forceClose) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Force Close  (+30s next time)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.85))
                    )
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .onReceive(ticker) { _ in
            guard !finished else { return }
            if countdown > 1 {
                countdown -= 1
            } else {
                finished = true
                onComplete()
            }
        }
    }

    private func forceClose() {
        // Add 30 sec penalty to UserDefaults before killing the process
        let current = UserDefaults.standard.integer(forKey: penaltyKey)
        UserDefaults.standard.set(current + 30, forKey: penaltyKey)
        UserDefaults.standard.synchronize()
        exit(0)
    }
}
