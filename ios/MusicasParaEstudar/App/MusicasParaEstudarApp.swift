import SwiftUI
#if DEBUG && targetEnvironment(simulator)
import StoreKitTest
#endif

@main
struct MusicasParaEstudarApp: App {
#if DEBUG && targetEnvironment(simulator)
    @State private var donationScreenshotSession: SKTestSession? = nil

    init() {
        guard ProcessInfo.processInfo.arguments.contains("--review-donation-screenshot") else { return }

        do {
            let session = try SKTestSession(configurationFileNamed: "Donation")
            session.locale = Locale(identifier: "pt_BR")
            session.storefront = "BRA"
            session.clearTransactions()
            session.disableDialogs = false
            _donationScreenshotSession = State(initialValue: session)
        } catch {
            _donationScreenshotSession = State(initialValue: nil)
            assertionFailure("Could not start the local StoreKit screenshot session: \(error)")
        }
    }
#endif

    var body: some Scene { WindowGroup { RootView() } }
}
