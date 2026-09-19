import SwiftUI

struct RootView: View {
    @StateObject private var model: AppModel

    init(repository: CatalogRepositoryProtocol = BundleCatalogRepository()) {
        _model = StateObject(wrappedValue: AppModel(repository: repository))
    }

    var body: some View {
        TabView {
            HomeView(model: model).tabItem { Label("Inicio", systemImage: "house") }
            ExploreView(model: model).tabItem { Label("Explorar", systemImage: "magnifyingglass") }
            PlayerView(model: model).tabItem { Label("Player", systemImage: "play.circle") }
            FocusView().tabItem { Label("Foco", systemImage: "timer") }
            LibraryView(model: model).tabItem { Label("Biblioteca", systemImage: "books.vertical") }
        }
        .tint(.indigo)
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var catalog: Catalog
    @Published private(set) var catalogLoadFailed = false
    @Published var selectedTrack: Track?
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
}

struct EmptyCatalogView: View {
    let loadFailed: Bool

    var body: some View {
        if loadFailed {
            ContentUnavailableView("Catálogo indisponível", systemImage: "exclamationmark.triangle", description: Text("Não foi possível abrir o catálogo incluído no aplicativo."))
        } else {
            ContentUnavailableView("Nenhuma faixa licenciada", systemImage: "music.note.list", description: Text("As gravações encontradas ainda aguardam comprovação de licença para distribuição. Por isso, elas não podem ser ouvidas neste aplicativo."))
        }
    }
}

struct HomeView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        NavigationStack { VStack(alignment: .leading, spacing: 20) {
            Text("Músicas para estudar").font(.largeTitle.bold())
            Text("Sessões calmas, com uma curadoria que só publica gravações verificadas.").foregroundStyle(.secondary)
            if model.approvedTracks.isEmpty { EmptyCatalogView(loadFailed: model.catalogLoadFailed) }
            else { Text("\(model.approvedTracks.count) gravações licenciadas disponíveis").font(.headline) }
        }.padding().navigationTitle("Inicio") }
    }
}

struct ExploreView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { Group { if model.approvedTracks.isEmpty { EmptyCatalogView(loadFailed: model.catalogLoadFailed) } else { List(model.approvedTracks) { track in Button { model.selectedTrack = track; model.playback.play(track) } label: { VStack(alignment: .leading) { Text(track.work); Text(track.composer).font(.subheadline).foregroundStyle(.secondary) } }.accessibilityLabel("\(track.work), por \(track.composer)") } } }.navigationTitle("Explorar") } }
}

struct PlayerView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { VStack(spacing: 16) { Image("mozart_logo").resizable().scaledToFit().frame(maxHeight: 180).accessibilityHidden(true); Text(model.selectedTrack?.work ?? "Nenhuma gravação selecionada").font(.title2.bold()); Text(model.approvedTracks.isEmpty ? "Não há faixas com licença verificada disponíveis para reprodução." : "Escolha uma faixa em Explorar.").foregroundStyle(.secondary) }.padding().navigationTitle("Player") } }
}

struct LibraryView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { VStack { if model.approvedTracks.isEmpty { EmptyCatalogView(loadFailed: model.catalogLoadFailed) }; NavigationLink("Ver créditos") { CreditsView() } }.navigationTitle("Biblioteca") } }
}

struct CreditsView: View {
    var body: some View { NavigationStack { Text("Catálogo, direitos e fontes são mantidos em Catalog/RIGHTS.md.").padding().navigationTitle("Créditos") } }
}
