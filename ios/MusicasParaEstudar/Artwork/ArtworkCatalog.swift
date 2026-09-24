import Foundation

struct FeaturedCollectionArtwork: Identifiable {
    let title: String
    let subtitle: String
    let assetName: String
    let ornamentAsset: String
    let categoryKey: String?
    let composerSearchTerm: String?

    var id: String { assetName }
}

struct ComposerArtwork: Identifiable {
    let name: String
    let searchTerm: String
    let assetName: String

    var id: String { searchTerm.lowercased() }
}

struct InstrumentArtwork: Identifiable {
    let name: String
    let assetName: String
    let categoryKeys: Set<String>
    let workTerms: [String]

    var id: String { assetName }

    func matches(_ track: Track) -> Bool {
        if categoryKeys.contains(track.categoryKey) { return true }
        let searchable = "\(track.id) \(track.work) \(track.composer)"
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return workTerms.contains { searchable.contains($0) }
    }
}

struct StudyObjectArtwork: Identifiable {
    let name: String
    let assetName: String

    var id: String { assetName }
}

enum ArtworkCatalog {
    static let collections = [
        FeaturedCollectionArtwork(
            title: "Foco Profundo", subtitle: "Concentração sem distrações",
            assetName: "FocusArtwork", ornamentAsset: "TrebleClef",
            categoryKey: "foco_profundo", composerSearchTerm: nil
        ),
        FeaturedCollectionArtwork(
            title: "Piano e Chuva", subtitle: "Suavidade para a noite",
            assetName: "PianoEveningArtwork", ornamentAsset: "MusicNotes",
            categoryKey: "piano_dormir", composerSearchTerm: nil
        ),
        FeaturedCollectionArtwork(
            title: "Noite com Chopin", subtitle: "Noturnos e piano",
            assetName: "ChopinMidnightArtwork", ornamentAsset: "StarOrnament",
            categoryKey: nil, composerSearchTerm: "Chopin"
        ),
        FeaturedCollectionArtwork(
            title: "Manhã com Mozart", subtitle: "Clássicos para começar",
            assetName: "MozartMorningArtwork", ornamentAsset: "ConstellationOrnament",
            categoryKey: nil, composerSearchTerm: "Mozart"
        ),
        FeaturedCollectionArtwork(
            title: "Beethoven em Foco", subtitle: "Força para estudar",
            assetName: "BeethovenPowerArtwork", ornamentAsset: "LaurelBranch",
            categoryKey: nil, composerSearchTerm: "Beethoven"
        )
    ]

    static let composers = [
        ComposerArtwork(name: "Bach", searchTerm: "Bach", assetName: "BachPortrait"),
        ComposerArtwork(name: "Chopin", searchTerm: "Chopin", assetName: "ChopinPortrait"),
        ComposerArtwork(name: "Mozart", searchTerm: "Mozart", assetName: "MozartPortrait"),
        ComposerArtwork(name: "Beethoven", searchTerm: "Beethoven", assetName: "BeethovenPortrait"),
        ComposerArtwork(name: "Vivaldi", searchTerm: "Vivaldi", assetName: "VivaldiPortrait"),
        ComposerArtwork(name: "Debussy", searchTerm: "Debussy", assetName: "DebussyPortrait"),
        ComposerArtwork(name: "Satie", searchTerm: "Satie", assetName: "SatiePortrait"),
        ComposerArtwork(name: "Liszt", searchTerm: "Liszt", assetName: "LisztPortrait"),
        ComposerArtwork(name: "Tchaikovsky", searchTerm: "Tchaikovsky", assetName: "TchaikovskyPortrait"),
        ComposerArtwork(name: "Brahms", searchTerm: "Brahms", assetName: "BrahmsPortrait")
    ]

    static let instruments = [
        InstrumentArtwork(name: "Piano de cauda", assetName: "GrandPiano", categoryKeys: ["piano_dormir", "piano_estudar"], workTerms: ["piano"]),
        InstrumentArtwork(name: "Teclas", assetName: "PianoKeys", categoryKeys: ["piano_dormir", "piano_estudar"], workTerms: ["piano", "cravo"]),
        InstrumentArtwork(name: "Violino", assetName: "Violin", categoryKeys: [], workTerms: ["violino"]),
        InstrumentArtwork(name: "Violoncelo", assetName: "Cello", categoryKeys: [], workTerms: ["violoncelo"]),
        InstrumentArtwork(name: "Trompete", assetName: "Trumpet", categoryKeys: [], workTerms: ["trompete", "trumpet"]),
        InstrumentArtwork(name: "Flauta", assetName: "Flute", categoryKeys: [], workTerms: ["flauta", "flute"]),
        InstrumentArtwork(name: "Partitura enrolada", assetName: "RolledScore", categoryKeys: ["classica_leitura"], workTerms: []),
        InstrumentArtwork(name: "Partitura aberta", assetName: "OpenScore", categoryKeys: ["classica_leitura", "barroco"], workTerms: []),
        InstrumentArtwork(name: "Fones de ouvido", assetName: "Headphones", categoryKeys: ["foco_profundo", "piano_dormir"], workTerms: []),
        InstrumentArtwork(name: "Batuta", assetName: "ConductorBaton", categoryKeys: ["classica_leitura", "barroco"], workTerms: [])
    ]

    static let studyObjects = [
        StudyObjectArtwork(name: "Livros", assetName: "BooksStack"),
        StudyObjectArtwork(name: "Livro aberto", assetName: "OpenStudyBook"),
        StudyObjectArtwork(name: "Lápis", assetName: "Pencil"),
        StudyObjectArtwork(name: "Café", assetName: "CoffeeCup"),
        StudyObjectArtwork(name: "Notebook", assetName: "Laptop"),
        StudyObjectArtwork(name: "Luminária", assetName: "DeskLamp"),
        StudyObjectArtwork(name: "Planta", assetName: "StudyPlant"),
        StudyObjectArtwork(name: "Lua", assetName: "Moon"),
        StudyObjectArtwork(name: "Sol", assetName: "Sun"),
        StudyObjectArtwork(name: "Ampulheta", assetName: "Hourglass")
    ]

    static let categoryOrnaments: [String: [String]] = [
        "foco_profundo": ["LeafBranch"],
        "piano_dormir": ["FlourishOrnament"],
        "piano_estudar": ["MusicStaff"],
        "classica_leitura": ["ClassicalColumn"],
        "barroco": ["MarbleColumn", "LyreEmblem"],
        "brasil": ["GoldRibbon"]
    ]

    static func portrait(for composer: String) -> String? {
        composers.first { composer.localizedCaseInsensitiveContains($0.searchTerm) }?.assetName
    }
}
