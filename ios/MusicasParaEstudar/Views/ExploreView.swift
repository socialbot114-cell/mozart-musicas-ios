import SwiftUI
import UIKit

struct ExploreView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @State private var selectedCategory: MusicCategory?

    private var filtered: [Track] {
        var tracks = model.approvedTracks
        if let category = selectedCategory {
            tracks = tracks.filter { $0.categoryKey == category.key }
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
                }
                ForEach(model.categories) { category in
                    chip(title: category.title, isSelected: selectedCategory?.key == category.key) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
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
