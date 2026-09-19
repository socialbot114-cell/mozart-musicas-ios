import SwiftUI

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = FocusStore()
    @AppStorage("focus.endDate") private var endDateInterval = 0.0
    @AppStorage("focus.durationMinutes") private var minutes = 25
    @State private var remaining = 25 * 60
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack { VStack(spacing: 22) {
            Text("Foco").font(.largeTitle.bold())
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60)).font(.system(size: 56, weight: .light, design: .rounded)).monospacedDigit().accessibilityLabel("Tempo restante: \(remaining / 60) minutos e \(remaining % 60) segundos")
            Picker("Duração da sessão", selection: $minutes) { ForEach([25, 50, 90], id: \.self) { Text("\($0) min").tag($0) } }.pickerStyle(.segmented).disabled(running).onChange(of: minutes) { _, value in remaining = value * 60 }
            Button(running ? "Pausar" : "Começar") { toggleTimer() }.buttonStyle(.borderedProminent).accessibilityHint(running ? "Pausa a contagem regressiva" : "Inicia a contagem regressiva")
            Text("\(store.completedMinutes) minutos estudados · \(store.sessions) sessões").foregroundStyle(.secondary)
        }.padding().navigationTitle("Foco")
            .onAppear { restoreTimer() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { restoreTimer() } }
            .onReceive(timer) { now in if running { updateRemaining(at: now) } }
        }
    }

    private func toggleTimer() {
        if running {
            updateRemaining(at: Date())
            running = false
            endDateInterval = 0
        } else {
            endDateInterval = Date().addingTimeInterval(TimeInterval(remaining)).timeIntervalSince1970
            running = true
        }
    }

    private func restoreTimer() {
        guard endDateInterval > 0 else { return }
        running = true
        updateRemaining(at: Date())
    }

    private func updateRemaining(at date: Date) {
        guard endDateInterval > 0 else { return }
        remaining = max(0, Int(ceil(endDateInterval - date.timeIntervalSince1970)))
        if remaining == 0 {
            endDateInterval = 0
            running = false
            store.record(minutes: minutes)
            remaining = minutes * 60
        }
    }
}
