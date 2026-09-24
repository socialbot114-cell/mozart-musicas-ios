import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var catalog: Catalog
    @Published private(set) var catalogLoadFailed = false
    @Published var selectedTrack: Track?
    @Published var showPlayer = false
    @Published var shuffleEnabled = false
    @Published private(set) var favoriteTrackIDs: Set<String>
    @Published private(set) var queuedTrackIDs: [String] = []
    let playback = PlaybackService()
    private let repository: CatalogRepositoryProtocol

    init(repository: CatalogRepositoryProtocol) {
        self.repository = repository
        favoriteTrackIDs = Set(UserDefaults.standard.stringArray(forKey: Self.favoritesStorageKey) ?? [])
        do {
            catalog = try repository.load()
        } catch {
            catalog = try! PreviewCatalogRepository().load()
            catalogLoadFailed = true
        }
    }

    var approvedTracks: [Track] { catalog.tracks.filter { $0.rightsStatus == "approved" } }

    var favoriteTracks: [Track] { approvedTracks.filter { favoriteTrackIDs.contains($0.id) } }

    var queuedTracks: [Track] {
        queuedTrackIDs.compactMap { id in approvedTracks.first { $0.id == id } }
    }

    private static let favoritesStorageKey = "br.com.musicaspara.estudar.favoriteTrackIDs"

    var categories: [MusicCategory] {
        MusicCategory.all.filter { cat in approvedTracks.contains { $0.categoryKey == cat.key } }
    }

    func tracks(in category: MusicCategory) -> [Track] {
        approvedTracks.filter { $0.categoryKey == category.key }
    }

    func select(_ track: Track) {
        selectedTrack = track
        playback.play(track)
    }

    func openPlayer(for track: Track) {
        select(track)
        showPlayer = true
    }

    func isFavorite(_ track: Track) -> Bool { favoriteTrackIDs.contains(track.id) }

    func isQueued(_ track: Track) -> Bool { queuedTrackIDs.contains(track.id) }

    func toggleFavorite(_ track: Track) {
        if favoriteTrackIDs.contains(track.id) {
            favoriteTrackIDs.remove(track.id)
        } else {
            favoriteTrackIDs.insert(track.id)
        }
        UserDefaults.standard.set(favoriteTrackIDs.sorted(), forKey: Self.favoritesStorageKey)
    }

    func enqueue(_ track: Track) {
        guard !queuedTrackIDs.contains(track.id) else { return }
        queuedTrackIDs.append(track.id)
    }

    func removeFromQueue(_ track: Track) {
        queuedTrackIDs.removeAll { $0 == track.id }
    }

    func clearQueue() { queuedTrackIDs.removeAll() }

    func playPreviousTrack(from track: Track) {
        playAdjacentTrack(to: track, offset: -1)
    }

    func playNextTrack(after track: Track) {
        if let queuedTrack = queuedTracks.first {
            removeFromQueue(queuedTrack)
            select(queuedTrack)
            return
        }

        if shuffleEnabled {
            let alternatives = approvedTracks.filter { $0.id != track.id }
            if let randomTrack = alternatives.randomElement() {
                select(randomTrack)
                return
            }
        }
        playAdjacentTrack(to: track, offset: 1)
    }

    private func playAdjacentTrack(to track: Track, offset: Int) {
        let tracks = approvedTracks
        guard !tracks.isEmpty else { return }
        let currentIndex = tracks.firstIndex { $0.id == track.id } ?? 0
        let targetIndex = (currentIndex + offset + tracks.count) % tracks.count
        select(tracks[targetIndex])
    }
}

struct RootView: View {
    @StateObject private var model: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(repository: CatalogRepositoryProtocol = BundleCatalogRepository()) {
        _model = StateObject(wrappedValue: AppModel(repository: repository))
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                AdaptiveSplitView(model: model)
            } else {
                PhoneTabView(model: model)
            }
        }
        .fullScreenCover(isPresented: $model.showPlayer) {
            ImmersivePlayerView(model: model, playback: model.playback)
        }
    }
}

struct PhoneTabView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            NavigationStack { HomeView(model: model) }
                .tabItem { Label("Início", systemImage: "house.fill") }
            NavigationStack { ExploreView(model: model) }
                .tabItem { Label("Explorar", systemImage: "square.grid.2x2") }
            NavigationStack { FocusView() }
                .tabItem { Label("Foco", systemImage: "timer") }
            NavigationStack { LibraryView(model: model) }
                .tabItem { Label("Biblioteca", systemImage: "books.vertical.fill") }
        }
        .tint(AppTheme.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.selectedTrack != nil && !model.showPlayer {
                MiniPlayerView(model: model, playback: model.playback)
            }
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case home, explore, focus, library
    var id: String { rawValue }
}

struct AdaptiveSplitView: View {
    @ObservedObject var model: AppModel
    @State private var selection: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Início", systemImage: "house.fill").tag(SidebarItem.home)
                Label("Explorar", systemImage: "square.grid.2x2").tag(SidebarItem.explore)
                Label("Foco", systemImage: "timer").tag(SidebarItem.focus)
                Label("Biblioteca", systemImage: "books.vertical.fill").tag(SidebarItem.library)
            }
            .navigationTitle("Músicas para Estudar")
        } detail: {
            switch selection ?? .home {
            case .home: HomeView(model: model)
            case .explore: ExploreView(model: model)
            case .focus: FocusView()
            case .library: LibraryView(model: model)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.selectedTrack != nil && !model.showPlayer {
                MiniPlayerView(model: model, playback: model.playback)
            }
        }
    }
}
