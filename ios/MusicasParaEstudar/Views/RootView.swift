import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var catalog: Catalog
    @Published private(set) var catalogLoadFailed = false
    @Published var selectedTrack: Track?
    @Published var showPlayer = false
    let playback = PlaybackService()
    private let repository: CatalogRepositoryProtocol

    init(repository: CatalogRepositoryProtocol) {
        self.repository = repository
        do {
            catalog = try repository.load()
        } catch {
            catalog = try! PreviewCatalogRepository().load()
            catalogLoadFailed = true
        }
    }

    var approvedTracks: [Track] { catalog.tracks.filter { $0.rightsStatus == "approved" } }

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
