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
    let durationSeconds: Double?
    let recording: String
    let rightsStatus: String
    let audioPath: String?
    let sourceUrl: URL?
    let sha256: String?
    let license: String?
    let blockedReason: String?

    var categoryKey: String {
        let parts = (audioPath ?? "").split(separator: "/")
        return parts.count > 1 ? String(parts[1]) : ""
    }

    var category: MusicCategory { MusicCategory.forKey(categoryKey) }

    var durationText: String { Self.format(durationSeconds ?? 0) }

    static func format(_ seconds: Double) -> String {
        guard seconds > 0, seconds.isFinite else { return "--:--" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
