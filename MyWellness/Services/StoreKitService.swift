import StoreKit
import Foundation

@MainActor
class StoreKitService: ObservableObject {

    // MARK: - Product IDs
    // These must match EXACTLY what you configure in App Store Connect
    static let monthlyProductID = "com.mywellness.subscription.monthly"
    static let annualProductID  = "com.mywellness.subscription.annual"

    static let productIDs: Set<String> = [monthlyProductID, annualProductID]

    // MARK: - Published state
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    var isSubscribed: Bool { !purchasedProductIDs.isEmpty }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyProductID } }
    var annualProduct:  Product? { products.first { $0.id == Self.annualProductID  } }

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Load products from App Store

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            // Sort: monthly first, then annual
            products = fetched.sorted { a, _ in a.id == Self.monthlyProductID }
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            // Waiting for approval (e.g. Ask to Buy)
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore purchases

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            self.error = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Check current entitlements

    func refreshPurchasedProducts() async {
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        var active: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    active.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = active

        // Sync status with your backend
        if !active.isEmpty {
            await syncSubscriptionWithBackend(productID: active.first)
        }
    }

    // MARK: - Listen for transaction updates (renewals, cancellations)

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verify transaction

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Sync with backend

    private func syncSubscriptionWithBackend(productID: String?) async {
        guard let productID else { return }

        let plan: String
        let status = "active"

        switch productID {
        case Self.monthlyProductID: plan = "monthly"
        case Self.annualProductID:  plan = "annual"
        default: return
        }

        _ = try? await APIService.shared.updateMe([
            "subscription_plan": plan,
            "subscription_status": status,
            "subscription_source": "apple_iap"
        ])
    }

    // MARK: - Trial info helpers

    func trialInfo(for product: Product) -> String? {
        guard let subscription = product.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return nil }

        let days = offer.period.value
        return "\(days)-day free trial"
    }

    func priceString(for product: Product) -> String {
        product.displayPrice
    }

    // MARK: - Active subscription detail

    var activeSubscriptionName: String {
        if purchasedProductIDs.contains(Self.annualProductID) { return "Annual Plan" }
        if purchasedProductIDs.contains(Self.monthlyProductID) { return "Monthly Plan" }
        return "No active subscription"
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Transaction verification failed."
        case .productNotFound:    return "Product not found in App Store."
        }
    }
}
