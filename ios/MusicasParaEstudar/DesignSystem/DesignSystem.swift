import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.34, green: 0.28, blue: 0.72)
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.18)

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

struct MusicCategory: Identifiable {
    let key: String
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]

    var id: String { key }

    var artworkAsset: String? {
        switch key {
        case "foco_profundo": "FocusArtwork"
        case "piano_dormir": "PianoEveningArtwork"
        case "piano_estudar": "ChopinMidnightArtwork"
        case "classica_leitura": "MozartMorningArtwork"
        default: nil
        }
    }

    var decorationAssets: [String] { ArtworkCatalog.categoryOrnaments[key] ?? [] }

    static let focoProfundo = MusicCategory(
        key: "foco_profundo", title: "Foco Profundo", subtitle: "Concentração sem distrações",
        symbol: "scope",
        colors: [Color(red: 0.16, green: 0.15, blue: 0.42), Color(red: 0.42, green: 0.18, blue: 0.62)])
    static let pianoDormir = MusicCategory(
        key: "piano_dormir", title: "Piano para Dormir", subtitle: "Suavidade para a noite",
        symbol: "moon.stars.fill",
        colors: [Color(red: 0.07, green: 0.10, blue: 0.28), Color(red: 0.20, green: 0.18, blue: 0.48)])
    static let pianoEstudar = MusicCategory(
        key: "piano_estudar", title: "Piano para Estudar", subtitle: "Teclas que acompanham a leitura",
        symbol: "pianokeys",
        colors: [Color(red: 0.04, green: 0.24, blue: 0.28), Color(red: 0.05, green: 0.42, blue: 0.36)])
    static let classicaLeitura = MusicCategory(
        key: "classica_leitura", title: "Clássica para Leitura", subtitle: "Orquestras e câmaras",
        symbol: "book.fill",
        colors: [Color(red: 0.32, green: 0.16, blue: 0.34), Color(red: 0.48, green: 0.20, blue: 0.30)])
    static let barroco = MusicCategory(
        key: "barroco", title: "Barroco", subtitle: "Bach, Vivaldi e contraponto",
        symbol: "building.columns.fill",
        colors: [Color(red: 0.38, green: 0.26, blue: 0.07), Color(red: 0.52, green: 0.34, blue: 0.12)])
    static let brasil = MusicCategory(
        key: "brasil", title: "Música Brasileira", subtitle: "Choros e clássicos do Brasil",
        symbol: "flag.fill",
        colors: [Color(red: 0.05, green: 0.34, blue: 0.22), Color(red: 0.10, green: 0.46, blue: 0.20)])

    static let all: [MusicCategory] = [focoProfundo, pianoDormir, pianoEstudar, classicaLeitura, barroco, brasil]

    static func forKey(_ key: String) -> MusicCategory {
        all.first { $0.key == key } ?? focoProfundo
    }
}

struct CategoryArtwork: View {
    let category: MusicCategory

    var body: some View {
        ZStack {
            if let artworkAsset = category.artworkAsset {
                Image(artworkAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .center, endPoint: .bottom)
            } else {
                LinearGradient(colors: category.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: category.symbol)
                    .font(.system(size: 90, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(18)
            }

            ForEach(category.decorationAssets.indices, id: \.self) { index in
                Image(category.decorationAssets[index])
                    .resizable()
                    .scaledToFit()
                    .frame(width: index == 0 ? 76 : 54, height: index == 0 ? 76 : 54)
                    .opacity(category.artworkAsset == nil ? 0.18 : 0.11)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: index.isMultiple(of: 2) ? .topTrailing : .bottomTrailing
                    )
                    .padding(10)
                    .accessibilityHidden(true)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

struct TrackArtwork: View {
    let track: Track

    var body: some View {
        Group {
            if let portrait = ArtworkCatalog.portrait(for: track.composer) {
                ZStack {
                    LinearGradient(colors: track.category.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(portrait)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .clipped()
                .accessibilityHidden(true)
            } else {
                CategoryArtwork(category: track.category)
            }
        }
    }
}

struct TrackRow: View {
    let track: Track
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            TrackArtwork(track: track)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(track.work).font(.headline).foregroundStyle(.primary).lineLimit(2)
                Text(track.composer).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(track.category.title).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.accent).lineLimit(1)
                Text(track.durationText).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("row.play.\(track.id)")
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TrackCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TrackArtwork(track: track)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "play.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(11)
                        .background(.black.opacity(0.32), in: Circle())
                        .padding(10)
                }
            Text(track.work).font(.headline).foregroundStyle(.primary).lineLimit(2).multilineTextAlignment(.leading)
            Text(track.composer).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            HStack {
                Text(track.category.title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.accent).lineLimit(1)
                Spacer()
                Text(track.durationText).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }
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
