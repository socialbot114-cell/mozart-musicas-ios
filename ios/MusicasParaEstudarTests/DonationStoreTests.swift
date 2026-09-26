import StoreKitTest
import XCTest
@testable import MusicasParaEstudar

@MainActor
final class DonationStoreTests: XCTestCase {
    func testStoreKitReturnsConfiguredNonConsumableDonation() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = DonationStore()
        await store.loadProduct()

        XCTAssertEqual(store.product?.id, DonationStore.productID)
        XCTAssertEqual(store.product?.type, .nonConsumable)
        XCTAssertTrue(store.displayPrice?.contains("10") == true)
        XCTAssertFalse(store.hasContributed)
    }

    func testNonConsumableDonationPurchaseCanBeRestored() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let purchaser = DonationStore()
        await purchaser.loadProduct()
        XCTAssertNotNil(purchaser.product)

        await purchaser.purchase()
        XCTAssertTrue(purchaser.hasContributed)
        XCTAssertEqual(purchaser.feedback, "Obrigado por apoiar o desenvolvimento do app!")

        let restoredStore = DonationStore()
        await restoredStore.loadProduct()
        XCTAssertTrue(restoredStore.hasContributed)
        await restoredStore.restorePurchases()
        XCTAssertTrue(restoredStore.hasContributed)
    }

    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Donation")
        session.locale = Locale(identifier: "pt_BR")
        session.storefront = "BRA"
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }
}
