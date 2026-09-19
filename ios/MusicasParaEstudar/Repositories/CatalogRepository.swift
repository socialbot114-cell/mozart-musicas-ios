import Foundation

protocol CatalogRepositoryProtocol {
    func load() throws -> Catalog
}

struct BundleResourcePath: Equatable {
    let name: String
    let fileExtension: String?
    let subdirectory: String?

    init?(_ value: String) {
        let components = value.split(separator: "/", omittingEmptySubsequences: false)
        guard !value.hasPrefix("/"), !components.isEmpty,
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { return nil }

        let file = String(components.last!) as NSString
        guard !file.deletingPathExtension.isEmpty else { return nil }
        name = file.deletingPathExtension
        fileExtension = file.pathExtension.isEmpty ? nil : file.pathExtension
        subdirectory = components.count > 1 ? components.dropLast().joined(separator: "/") : nil
    }

    func url(in bundle: Bundle) -> URL? {
        bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
    }
}

struct BundleCatalogRepository: CatalogRepositoryProtocol {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func load() throws -> Catalog {
        guard let path = BundleResourcePath("Catalog/catalog.json"), let url = path.url(in: bundle) else {
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
