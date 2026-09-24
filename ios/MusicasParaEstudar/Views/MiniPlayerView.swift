import SwiftUI
import UIKit

struct MiniPlayerView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var playback: PlaybackService

    var body: some View {
        Group {
            if let track = model.selectedTrack {
                HStack(spacing: 12) {
                    Button {
                        model.showPlayer = true
                    } label: {
                        HStack(spacing: 12) {
                            TrackArtwork(track: track)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.work).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                                Text(track.composer).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("miniplayer.open")

                    Spacer()

                    Button {
                        playback.toggle()
                    } label: {
                        Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.accent, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("miniplayer.toggle")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.primary.opacity(0.06)))
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
    }
}
