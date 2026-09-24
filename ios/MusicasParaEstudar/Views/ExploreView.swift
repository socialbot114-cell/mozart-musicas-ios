import SwiftUI
import UIKit

struct ExploreView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @State private var selectedCategory: MusicCategory?
    @State private var selectedComposer: String?

    private var filtered: [Track] {
        var tracks = model.approvedTracks
        if let category = selectedCategory {
            tracks = tracks.filter { $0.categoryKey == category.key }
        }
        if let selectedComposer {
            tracks = tracks.filter { $0.composer.localizedCaseInsensitiveContains(selectedComposer) }
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
                    composerSection
                }
                if filtered.isEmpty {
                    ContentUnavailableView("Nada encontrado", systemImage: "magnifyingglass", description: Text("Tente outro termo ou categoria."))
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
                }
                ForEach(model.categories) { category in
                    chip(title: category.title, isSelected: selectedCategory?.key == category.key) {
                        selectedCategory = category
                        selectedComposer = nil
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var composerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compositores")
                .font(AppTheme.display(20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeaturedComposer.all) { composer in
                        let isSelected = selectedComposer == composer.searchTerm
                        Button {
                            selectedComposer = isSelected ? nil : composer.searchTerm
                            selectedCategory = nil
                        } label: {
                            VStack(spacing: 0) {
                                ZStack(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [AppTheme.ink, AppTheme.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    Image(composer.artwork)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 112, height: 112, alignment: .bottom)
                                        .accessibilityHidden(true)
                                }
                                .frame(width: 112, height: 108)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                Text(composer.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .frame(width: 112)
                            .background(
                                Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Filtrar por \(composer.name)")
                        .accessibilityValue(isSelected ? "Selecionado" : "")
                        .accessibilityIdentifier("composer.\(composer.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
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

private struct FeaturedComposer: Identifiable {
    let name: String
    let searchTerm: String
    let artwork: String

    var id: String { searchTerm.lowercased() }

    static let all = [
        FeaturedComposer(name: "Bach", searchTerm: "Bach", artwork: "BachPortrait"),
        FeaturedComposer(name: "Chopin", searchTerm: "Chopin", artwork: "ChopinPortrait"),
        FeaturedComposer(name: "Mozart", searchTerm: "Mozart", artwork: "MozartPortrait"),
        FeaturedComposer(name: "Beethoven", searchTerm: "Beethoven", artwork: "BeethovenPortrait")
    ]
}
