import SwiftUI

struct FocusView: View {
    @StateObject private var store = FocusStore()
    @State private var minutes = 25
    @State private var remaining = 25 * 60
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack { VStack(spacing: 22) {
            Text("Foco").font(.largeTitle.bold())
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60)).font(.system(size: 56, weight: .light, design: .rounded)).monospacedDigit()
            Picker("Duração", selection: $minutes) { ForEach([25, 50, 90], id: \.self) { Text("\($0) min").tag($0) } }.pickerStyle(.segmented).onChange(of: minutes) { _, value in remaining = value * 60 }
            Button(running ? "Pausar" : "Começar") { running.toggle() }.buttonStyle(.borderedProminent)
            Text("\(store.completedMinutes) minutos estudados · \(store.sessions) sessões").foregroundStyle(.secondary)
        }.padding().navigationTitle("Foco").onReceive(timer) { _ in guard running else { return }; if remaining > 0 { remaining -= 1 } else { running = false; store.record(minutes: minutes) } } }
    }
}
