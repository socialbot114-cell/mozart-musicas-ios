import SwiftUI
import UIKit

struct ImmersivePlayerView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var playback: PlaybackService
    @Environment(\.dismiss) private var dismiss

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
                Image(systemName: "heart").font(.headline).foregroundStyle(.secondary).padding(12)
            }
            .padding(.horizontal)

            Spacer()

            CategoryArtwork(category: track.category)
                .frame(width: 300, height: 300)
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

            HStack(spacing: 52) {
                Image(systemName: "gobackward.15")
                Button {
                    playback.toggle()
                } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(AppTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("player.toggle")
                Image(systemName: "goforward.15")
            }
            .font(.title2)
            .foregroundStyle(.primary)
            .padding(.top, 24)

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

    private func displayDuration(for track: Track) -> Double {
        if playback.duration > 0 { return playback.duration }
        return track.durationSeconds ?? 0
    }

    private static func format(_ seconds: Double) -> String {
        Track.format(seconds)
    }
}
