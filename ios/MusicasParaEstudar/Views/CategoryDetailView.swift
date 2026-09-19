import SwiftUI
import UIKit

struct CategoryDetailView: View {
    @ObservedObject var model: AppModel
    let category: MusicCategory

    var body: some View {
        let tracks = model.tracks(in: category)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    CategoryArtwork(category: category)
                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title).font(AppTheme.display(26, weight: .bold)).foregroundStyle(.white)
                        Text("\(tracks.count) obras licenciadas").font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(20)
                }
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.horizontal)

                if let first = tracks.first {
                    Button {
                        model.openPlayer(for: first)
                    } label: {
                        Label("Tocar categoria", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .accessibilityIdentifier("category.play")
                }

                LazyVStack(spacing: 10) {
                    ForEach(tracks) { track in
                        TrackRow(track: track) { model.openPlayer(for: track) }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
