import SwiftUI
import UIKit

struct ImmersivePlayerView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var playback: PlaybackService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var activeSheet: PlayerSheet?

    var body: some View {
        Group {
            if let track = model.selectedTrack {
                content(for: track)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note").font(.system(size: 44)).foregroundStyle(.secondary)
                    Text("Nenhuma faixa selecionada").font(.headline)
                    Text("Escolha uma obra em Explorar.").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .queue:
                PlayerQueueSheet(model: model)
            case .trackDetails(let track):
                TrackDetailsSheet(track: track)
            }
        }
    }

    private func content(for track: Track) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityIdentifier("player.dismiss")
                Spacer()
                Text("Tocando agora").font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Button {
                    model.toggleFavorite(track)
                } label: {
                    PlayerControlArtwork(assetName: "PlayerFavorite", selected: model.isFavorite(track), size: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.isFavorite(track) ? "Remover dos favoritos" : "Adicionar aos favoritos")
                .accessibilityValue(model.isFavorite(track) ? "Favorito" : "")
                .accessibilityIdentifier("player.favorite")
            }
            .padding(.horizontal)

            Spacer()

            TrackArtwork(track: track)
                .frame(width: artworkSide, height: artworkSide)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: track.category.colors[0].opacity(0.45), radius: 34, y: 20)

            VStack(spacing: 6) {
                Text(track.work)
                    .font(AppTheme.display(24, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                Text(track.composer).font(.subheadline).foregroundStyle(.secondary)
                Text(track.category.title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            VStack(spacing: 6) {
                Slider(value: progressBinding, in: 0...max(displayDuration(for: track), 1))
                    .tint(AppTheme.accent)
                HStack {
                    Text(Self.format(playback.currentTime)).monospacedDigit()
                    Spacer()
                    Text(track.durationText).monospacedDigit()
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            HStack(spacing: 8) {
                playerButton(assetName: "PlayerShuffle", title: "Aleatório", identifier: "player.shuffle", selected: model.shuffleEnabled) {
                    model.shuffleEnabled.toggle()
                }
                playerButton(assetName: "PlayerPrevious", title: "Faixa anterior", identifier: "player.previous") {
                    model.playPreviousTrack(from: track)
                }
                Button {
                    playback.toggle()
                } label: {
                    Image(playback.isPlaying ? "PlayerPause" : "PlayerPlay")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 62, height: 62)
                        .frame(width: 76, height: 76)
                        .background(AppTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playback.isPlaying ? "Pausar" : "Reproduzir")
                .accessibilityIdentifier("player.toggle")
                playerButton(assetName: "PlayerNext", title: "Próxima faixa", identifier: "player.next") {
                    model.playNextTrack(after: track)
                }
                playerButton(assetName: "PlayerRepeat", title: "Repetir faixa", identifier: "player.repeat", selected: playback.isRepeating) {
                    playback.toggleRepeat()
                }
            }
            .padding(.top, 24)

            HStack(spacing: 24) {
                playerButton(
                    assetName: "PlayerVolume",
                    title: playback.isMuted ? "Ativar volume" : "Silenciar",
                    identifier: "player.volume",
                    selected: playback.isMuted
                ) {
                    playback.toggleMute()
                }
                playerButton(
                    assetName: "PlayerAdd",
                    title: model.isQueued(track) ? "Remover da fila" : "Adicionar à fila",
                    identifier: "player.queue.add",
                    selected: model.isQueued(track)
                ) {
                    if model.isQueued(track) { model.removeFromQueue(track) }
                    else { model.enqueue(track) }
                }
                Menu {
                    Button {
                        activeSheet = .queue
                    } label: {
                        Label("Fila (\(model.queuedTracks.count))", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    Button {
                        activeSheet = .trackDetails(track)
                    } label: {
                        Label("Informações e créditos", systemImage: "info.circle")
                    }
                } label: {
                    PlayerControlArtwork(assetName: "PlayerMore", selected: false)
                }
                .accessibilityLabel("Mais opções")
                .accessibilityIdentifier("player.more")
            }
            .padding(.top, 12)

            Spacer()
        }
        .padding(.bottom, 20)
    }

    private var progressBinding: Binding<Double> {
        Binding(
            get: { playback.currentTime },
            set: { playback.seek(to: $0) }
        )
    }

    private var artworkSide: CGFloat {
        sizeClass == .regular ? 440 : 300
    }

    private func displayDuration(for track: Track) -> Double {
        if playback.duration > 0 { return playback.duration }
        return track.durationSeconds ?? 0
    }

    private static func format(_ seconds: Double) -> String {
        Track.format(seconds)
    }
}

private enum PlayerSheet: Identifiable {
    case queue
    case trackDetails(Track)

    var id: String {
        switch self {
        case .queue: "queue"
        case .trackDetails(let track): "track-\(track.id)"
        }
    }
}

private func playerButton(
    assetName: String,
    title: String,
    identifier: String,
    selected: Bool = false,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        PlayerControlArtwork(assetName: assetName, selected: selected)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityValue(selected ? "Ativado" : "")
    .accessibilityIdentifier(identifier)
}

private struct PlayerControlArtwork: View {
    let assetName: String
    let selected: Bool
    var size: CGFloat = 30

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .frame(width: 48, height: 48)
            .background(
                selected ? AppTheme.accent.opacity(0.16) : Color(.secondarySystemGroupedBackground),
                in: Circle()
            )
            .overlay(Circle().strokeBorder(.primary.opacity(0.05)))
            .contentShape(Circle())
    }
}

private struct PlayerQueueSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.queuedTracks.isEmpty {
                    ContentUnavailableView("Fila vazia", systemImage: "text.line.first.and.arrowtriangle.forward", description: Text("Adicione uma obra pelo botão + do player."))
                } else {
                    List {
                        ForEach(model.queuedTracks) { track in
                            Button {
                                model.select(track)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    TrackArtwork(track: track)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    VStack(alignment: .leading) {
                                        Text(track.work).font(.subheadline.weight(.semibold))
                                        Text(track.composer).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("queue.track.\(track.id)")
                            .swipeActions {
                                Button(role: .destructive) {
                                    model.removeFromQueue(track)
                                } label: {
                                    Label("Remover", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fila")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct TrackDetailsSheet: View {
    let track: Track
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Obra") {
                    LabeledContent("Título", value: track.work)
                    LabeledContent("Compositor", value: track.composer)
                }
                Section("Gravação e direitos") {
                    LabeledContent("Licença", value: track.license ?? "Não informada")
                    LabeledContent("Situação", value: track.rightsStatus == "approved" ? "Aprovada" : "Em revisão")
                    if let source = track.sourceUrl {
                        Link("Abrir fonte da gravação", destination: source)
                    }
                }
            }
            .navigationTitle("Informações da faixa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
