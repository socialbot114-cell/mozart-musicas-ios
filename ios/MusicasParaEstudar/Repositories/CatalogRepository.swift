import Foundation

protocol CatalogRepositoryProtocol {
    func load() throws -> Catalog
}

struct BundleCatalogRepository: CatalogRepositoryProtocol {
    func load() throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Catalog") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }
}

struct PreviewCatalogRepository: CatalogRepositoryProtocol {
    func load() throws -> Catalog {
        Catalog(schemaVersion: 1, product: Product(appStoreId: "6813681353", bundleId: "br.com.musicaspara.estudar"), tracks: [], candidates: [])
    }
}
