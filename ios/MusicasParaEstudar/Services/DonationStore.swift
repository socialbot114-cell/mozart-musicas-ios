import Foundation
import Combine
import StoreKit

@MainActor
final class DonationStore: ObservableObject {
    static let productID = "br.com.musicaspara.estudar.donation.r10"

    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var feedback: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        guard product == nil, !isLoadingProduct else { return }
        isLoadingProduct = true
        feedback = nil
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if product == nil {
                feedback = "A contribuição não está disponível no momento."
            }
        } catch {
            feedback = "Não foi possível carregar a contribuição. Tente novamente mais tarde."
        }
    }

    func purchase() async {
        guard let product else {
            feedback = "A contribuição não está disponível no momento."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let result):
                let transaction = try Self.verifiedTransaction(from: result)
                guard transaction.productID == Self.productID else { return }
                await transaction.finish()
                feedback = "Obrigado por apoiar o desenvolvimento do app!"
            case .pending:
                feedback = "A compra está aguardando confirmação da App Store."
            case .userCancelled:
                feedback = nil
            @unknown default:
                feedback = "Não foi possível concluir a compra. Tente novamente."
            }
        } catch {
            feedback = "Não foi possível concluir a compra. Tente novamente."
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try Self.verifiedTransaction(from: result)
            guard transaction.productID == Self.productID else { return }
            await transaction.finish()
            feedback = "Obrigado por apoiar o desenvolvimento do app!"
        } catch {
            feedback = "A App Store não conseguiu verificar a compra."
        }
    }

    private static func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            transaction
        case .unverified:
            throw VerificationError.failed
        }
    }

    private enum VerificationError: Error {
        case failed
    }
}
