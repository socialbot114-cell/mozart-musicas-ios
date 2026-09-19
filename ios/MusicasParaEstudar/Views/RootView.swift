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
    @Published var selectedTrack: Track?
    let playback = PlaybackService()
    private let repository: CatalogRepositoryProtocol

    init(repository: CatalogRepositoryProtocol) {
        self.repository = repository
        catalog = (try? repository.load()) ?? (try! PreviewCatalogRepository().load())
    }

    var approvedTracks: [Track] { catalog.tracks.filter { $0.rightsStatus == "approved" } }
}

struct EmptyCatalogView: View {
    var body: some View {
        ContentUnavailableView("Prévia em curadoria", systemImage: "music.note.list", description: Text("Nenhuma gravação Mozart com direitos verificados está disponível ainda."))
    }
}

struct HomeView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        NavigationStack { VStack(alignment: .leading, spacing: 20) {
            Text("Mozart para estudar").font(.largeTitle.bold())
            Text("Sessões calmas, com uma curadoria que só publica gravações verificadas.").foregroundStyle(.secondary)
            EmptyCatalogView()
        }.padding().navigationTitle("Inicio") }
    }
}

struct ExploreView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { Group { if model.approvedTracks.isEmpty { EmptyCatalogView() } else { List(model.approvedTracks) { Text($0.work) } } }.navigationTitle("Explorar") } }
}

struct PlayerView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { VStack(spacing: 16) { Image("mozart_logo").resizable().scaledToFit().frame(maxHeight: 180); Text(model.selectedTrack?.work ?? "Nenhuma gravação selecionada").font(.title2.bold()); Text("O player será ativado quando houver uma faixa aprovada.").foregroundStyle(.secondary) }.padding().navigationTitle("Player") } }
}

struct LibraryView: View {
    @ObservedObject var model: AppModel
    var body: some View { NavigationStack { VStack { EmptyCatalogView(); NavigationLink("Ver créditos") { CreditsView() } }.navigationTitle("Biblioteca") } }
}

struct CreditsView: View {
    var body: some View { NavigationStack { Text("Catálogo, direitos e fontes são mantidos em Catalog/RIGHTS.md.").padding().navigationTitle("Créditos") } }
}
