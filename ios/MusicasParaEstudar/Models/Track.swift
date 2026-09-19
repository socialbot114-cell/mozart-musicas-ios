import Foundation

struct Catalog: Decodable {
    let schemaVersion: Int
    let product: Product
    let tracks: [Track]
    let candidates: [Track]
}

struct Product: Decodable {
    let appStoreId: String
    let bundleId: String
}

struct Track: Identifiable, Decodable, Hashable {
    let id: String
    let composer: String
    let work: String
    let recording: String
    let rightsStatus: String
    let audioPath: String?
    let sourceUrl: URL?
    let sha256: String?
    let license: String?
    let blockedReason: String?
}
