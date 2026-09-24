import SwiftUI
import UIKit

struct ExploreView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @State private var selectedCategory: MusicCategory?
    @State private var selectedComposer: String?
    @State private var selectedInstrument: String?
    @State private var artworkShowcase: ArtworkShowcase = .composers

    init(model: AppModel, initialCategoryKey: String? = nil, initialComposer: String? = nil) {
        _model = ObservedObject(wrappedValue: model)
        _selectedCategory = State(initialValue: initialCategoryKey.map(MusicCategory.forKey))
        _selectedComposer = State(initialValue: initialComposer)
    }

    private var filtered: [Track] {
        var tracks = model.approvedTracks
        if let category = selectedCategory {
            tracks = tracks.filter { $0.categoryKey == category.key }
        }
        if let selectedComposer {
            tracks = tracks.filter { $0.composer.localizedCaseInsensitiveContains(selectedComposer) }
        }
        if let selectedInstrument,
           let instrument = ArtworkCatalog.instruments.first(where: { $0.id == selectedInstrument }) {
            tracks = tracks.filter(instrument.matches)
        }
        if !query.isEmpty {
            tracks = tracks.filter {
                $0.work.localizedCaseInsensitiveContains(query) ||
                $0.composer.localizedCaseInsensitiveContains(query)
            }
        }
        return tracks
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                categoryChips
                if query.isEmpty {
                    artworkDiscoverySection
                }
                if filtered.isEmpty {
                    ContentUnavailableView("Nada encontrado", systemImage: "magnifyingglass", description: Text(emptyDescription))
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                        ForEach(filtered) { track in
                            Button {
                                model.openPlayer(for: track)
                            } label: {
                                TrackCard(track: track)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("track.\(track.id)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Explorar")
        .searchable(text: $query, prompt: "Obras ou compositores")
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Todos", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                    selectedComposer = nil
                    selectedInstrument = nil
                }
                ForEach(model.categories) { category in
                    chip(title: category.title, isSelected: selectedCategory?.key == category.key) {
                        selectedCategory = category
                        selectedComposer = nil
                        selectedInstrument = nil
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var artworkDiscoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Arte para explorar", selection: $artworkShowcase) {
                Text("Compositores").tag(ArtworkShowcase.composers)
                Text("Instrumentos").tag(ArtworkShowcase.instruments)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityIdentifier("explore.artwork.mode")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    if artworkShowcase == .composers {
                        ForEach(ArtworkCatalog.composers) { composer in
                            composerCard(composer)
                        }
                    } else {
                        ForEach(ArtworkCatalog.instruments) { instrument in
                            instrumentCard(instrument)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func composerCard(_ composer: ComposerArtwork) -> some View {
        let isSelected = selectedComposer == composer.searchTerm
        let trackCount = model.approvedTracks.filter {
            $0.composer.localizedCaseInsensitiveContains(composer.searchTerm)
        }.count
        return Button {
            selectedComposer = isSelected ? nil : composer.searchTerm
            selectedCategory = nil
            selectedInstrument = nil
        } label: {
            VStack(spacing: 0) {
                portraitArt(composer.assetName)
                Text(composer.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                Text(trackCount == 0 ? "Em breve" : (trackCount == 1 ? "1 obra" : "\(trackCount) obras"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .frame(width: 112)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(trackCount == 0)
        .accessibilityLabel(trackCount == 0 ? "\(composer.name), sem faixas no catálogo" : "Filtrar por \(composer.name)")
        .accessibilityValue(isSelected ? "Selecionado" : "\(trackCount) obras")
        .accessibilityIdentifier("composer.\(composer.id)")
    }

    private func instrumentCard(_ instrument: InstrumentArtwork) -> some View {
        let isSelected = selectedInstrument == instrument.id
        let trackCount = model.approvedTracks.filter(instrument.matches).count
        return Button {
            selectedInstrument = isSelected ? nil : instrument.id
            selectedCategory = nil
            selectedComposer = nil
        } label: {
            VStack(spacing: 0) {
                portraitArt(instrument.assetName)
                Text(instrument.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                Text(trackCount == 0 ? "Em breve" : (trackCount == 1 ? "1 obra" : "\(trackCount) obras"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .frame(width: 112)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(trackCount == 0)
        .accessibilityLabel(trackCount == 0 ? "\(instrument.name), sem faixas no catálogo" : "Filtrar por \(instrument.name)")
        .accessibilityValue(isSelected ? "Selecionado" : "\(trackCount) obras")
        .accessibilityIdentifier("instrument.\(instrument.id)")
    }

    private func portraitArt(_ assetName: String) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [AppTheme.ink, AppTheme.accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112, alignment: .bottom)
                .accessibilityHidden(true)
        }
        .frame(width: 112, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyDescription: String {
        if let selectedComposer {
            return "Ainda não há faixas licenciadas para \(selectedComposer)."
        }
        if let selectedInstrument,
           let instrument = ArtworkCatalog.instruments.first(where: { $0.id == selectedInstrument }) {
            return "Ainda não há faixas licenciadas catalogadas para \(instrument.name.lowercased())."
        }
        return "Tente outro termo ou categoria."
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("chip.\(title)")
    }
}

private enum ArtworkShowcase: Hashable {
    case composers
    case instruments
}
