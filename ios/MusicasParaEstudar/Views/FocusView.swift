import SwiftUI

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = FocusStore()
    @AppStorage("focus.endDate") private var endDateInterval = 0.0
    @AppStorage("focus.durationMinutes") private var minutes = 25
    @AppStorage("focus.studyObject") private var selectedStudyObject = "BooksStack"
    @State private var remaining = 25 * 60
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentStudyObject: StudyObjectArtwork {
        ArtworkCatalog.studyObjects.first { $0.assetName == selectedStudyObject } ?? ArtworkCatalog.studyObjects[0]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Foco")
                        .font(.largeTitle.bold())
                    Text("Prepare seu espaço e comece com calma")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.ink, AppTheme.accent.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image("LeafBranch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .opacity(0.16)
                        .rotationEffect(.degrees(-16))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(4)
                        .accessibilityHidden(true)
                    Image("BlackBow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 68)
                        .opacity(0.28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                        .accessibilityHidden(true)
                    Image(currentStudyObject.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 142)
                        .accessibilityHidden(true)
                }
                .frame(height: 166)

                Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("Tempo restante: \(remaining / 60) minutos e \(remaining % 60) segundos")

                Picker("Duração da sessão", selection: $minutes) {
                    ForEach([25, 50, 90], id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(running)
                .onChange(of: minutes) { _, value in remaining = value * 60 }

                Button(running ? "Pausar" : "Começar") { toggleTimer() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .accessibilityHint(running ? "Pausa a contagem regressiva" : "Inicia a contagem regressiva")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image("Quill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .accessibilityHidden(true)
                        Text("Escolha um detalhe para estudar")
                            .font(.headline)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(ArtworkCatalog.studyObjects) { item in
                                let isSelected = selectedStudyObject == item.assetName
                                Button {
                                    selectedStudyObject = item.assetName
                                } label: {
                                    VStack(spacing: 5) {
                                        Image(item.assetName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .accessibilityHidden(true)
                                        Text(item.name)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 78, height: 88)
                                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 2)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Selecionar \(item.name)")
                                .accessibilityValue(isSelected ? "Selecionado" : "")
                                .accessibilityIdentifier("focus.object.\(item.id)")
                            }
                        }
                    }
                }

                Image("GoldDivider")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .accessibilityHidden(true)

                Text("\(store.completedMinutes) minutos estudados · \(store.sessions) sessões")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 560)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Foco")
            .onAppear { restoreTimer() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { restoreTimer() } }
            .onReceive(timer) { now in if running { updateRemaining(at: now) } }
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
