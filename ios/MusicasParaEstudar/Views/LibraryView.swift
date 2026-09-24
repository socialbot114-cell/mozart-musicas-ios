import SwiftUI
import UIKit

struct LibraryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section {
                LabeledContent("Obras licenciadas", value: "\(model.approvedTracks.count)")
                LabeledContent("Categorias", value: "\(model.categories.count)")
            } header: {
                Text("Biblioteca")
            } footer: {
                Text("Somente gravações com licença verificada são exibidas.")
            }

            Section("Favoritos") {
                if model.favoriteTracks.isEmpty {
                    Label("Suas obras favoritas aparecerão aqui.", systemImage: "heart")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.favoriteTracks) { track in
                        Button {
                            model.openPlayer(for: track)
                        } label: {
                            HStack(spacing: 12) {
                                TrackArtwork(track: track)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(track.work).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text(track.composer).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                Image("PlayerFavorite")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("favorite.\(track.id)")
                    }
                }
            }

            Section {
                NavigationLink {
                    CreditsView()
                } label: {
                    Label("Créditos e direitos", systemImage: "checkmark.shield")
                }
                NavigationLink {
                    AboutView()
                } label: {
                    Label("Sobre o app", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Biblioteca")
    }
}

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Direitos e fontes")
                    .font(AppTheme.display(22, weight: .bold))
                Text("Cada gravação publicada possui fonte verificada, licença, território e data de verificação registrados no catálogo incluído no aplicativo. A lista completa é mantida em Catalog/RIGHTS.md.")
                    .foregroundStyle(.secondary)
                Label("Composições em domínio público", systemImage: "checkmark.circle")
                Label("Gravações de fonte verificada", systemImage: "checkmark.circle")
                Label("Distribuição mundial", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Créditos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Músicas para Estudar")
                    .font(AppTheme.display(22, weight: .bold))
                Text("Uma curadoria offline de música clássica para foco, leitura e descanso. Sem anúncios, sem conta e sem coleta de dados.")
                    .foregroundStyle(.secondary)
                Label("100% offline", systemImage: "wifi.slash")
                Label("Sem coleta de dados", systemImage: "hand.raised")
                Label("Sem anúncios", systemImage: "nosign")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Sobre")
        .navigationBarTitleDisplayMode(.inline)
    }
}
