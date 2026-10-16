import SwiftUI
import BrimletCore

struct TimerCard: View {
    @ObservedObject var module: TimerModule
    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle().stroke(BrimletTheme.surface, lineWidth: 4)
                    Circle().trim(from: 0, to: module.countdown.phase == .idle ? 0.22 : 1 - module.countdown.progress(at: module.now))
                        .stroke(BrimletTheme.mint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: module.countdown.phase == .finished ? "checkmark" : "timer")
                        .font(.system(size: 22, weight: .light)).foregroundStyle(BrimletTheme.mint)
                }.frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(timeText).font(.system(size: 36, weight: .light, design: .rounded)).monospacedDigit()
                    Text(status).font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                }
                Spacer()
                if module.countdown.phase != .idle {
                    IconButton(symbol: "arrow.counterclockwise", help: "Reset Timer") { module.reset() }
                }
            }
            .padding(.top, 4)

            if module.countdown.phase == .idle {
                HStack(spacing: 7) {
                    ForEach([5, 15, 25, 45], id: \.self) { minutes in
                        Button { module.selectedMinutes = minutes } label: {
                            Text("\(minutes) min").font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity).padding(.vertical, 7)
                                .foregroundStyle(module.selectedMinutes == minutes ? BrimletTheme.mint : BrimletTheme.secondary)
                                .background(module.selectedMinutes == minutes ? BrimletTheme.mint.opacity(0.12) : BrimletTheme.surface, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                Button("Start Timer") { module.start() }.buttonStyle(MintButtonStyle())
            } else if module.countdown.phase == .finished {
                Text("Take a breath. Start again when you’re ready.")
                    .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                Button("Start Again") { module.start() }.buttonStyle(MintButtonStyle())
            } else {
                Text("Your music keeps playing.")
                    .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).padding(.top, 3)
                Button(module.countdown.phase == .running ? "Pause" : "Resume") { module.togglePause() }
                    .buttonStyle(MintButtonStyle())
            }
        }
        .padding(.horizontal, 26)
    }

    private var timeText: String {
        module.countdown.phase == .idle ? Countdown.formatted(Double(module.selectedMinutes * 60)) : Countdown.formatted(module.countdown.remaining(at: module.now))
    }

    private var status: String {
        switch module.countdown.phase {
        case .idle: return String(localized: "Give yourself a little time.")
        case .running: return String(localized: "The clock is on your side.")
        case .paused: return String(localized: "Paused. No rush.")
        case .finished: return String(localized: "Time’s up.")
        }
    }
}
