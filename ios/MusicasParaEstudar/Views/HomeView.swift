import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if model.approvedTracks.isEmpty {
                    EmptyCatalogView(loadFailed: model.catalogLoadFailed)
                        .padding(.top, 120)
                } else {
                    header
                    hero
                    collectionsSection
                    if let current = model.selectedTrack {
                        continueListening(current)
                    }
                    allMusicSection
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Músicas para Estudar")
                    .font(AppTheme.display(27, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Curadoria clássica para foco e descanso")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var hero: some View {
        let category = MusicCategory.focoProfundo
        let tracks = model.tracks(in: category)
        return Group {
            if let first = tracks.first {
                Button {
                    model.openPlayer(for: first)
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        CategoryArtwork(category: category)
                        LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Em destaque").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.85)).textCase(.uppercase)
                            Text(category.title).font(AppTheme.display(26, weight: .bold)).foregroundStyle(.white)
                            Text(category.subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                            Label("Tocar · \(first.work)", systemImage: "play.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 9)
                                .background(.white.opacity(0.2), in: Capsule())
                        }
                        .padding(22)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("hero.play")
            }
        }
        .padding(.horizontal)
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Coleções em destaque")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ArtworkCatalog.collections) { collection in
                        NavigationLink {
                            ExploreView(
                                model: model,
                                initialCategoryKey: collection.categoryKey,
                                initialComposer: collection.composerSearchTerm
                            )
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                Image(collection.assetName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 178, height: 154)
                                    .clipped()
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.78)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                Image(collection.ornamentAsset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 34, height: 34)
                                    .opacity(0.55)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(10)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(collection.title)
                                        .font(AppTheme.display(16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(collection.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.82))
                                        .lineLimit(1)
                                }
                                .padding(12)
                            }
                            .frame(width: 178, height: 154)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.06))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("collection.\(collection.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func continueListening(_ track: Track) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Continuar ouvindo")
            TrackRow(track: track) { model.openPlayer(for: track) }
                .padding(.horizontal)
        }
    }

    private var allMusicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Todos os clássicos")
            LazyVStack(spacing: 10) {
                ForEach(Array(model.approvedTracks.prefix(8))) { track in
                    TrackRow(track: track) { model.openPlayer(for: track) }
                }
            }
            .padding(.horizontal)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.display(20, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal)
    }
}
