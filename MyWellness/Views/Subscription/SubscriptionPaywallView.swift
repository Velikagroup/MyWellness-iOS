import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @EnvironmentObject var store: StoreKitService
    @Environment(\.dismiss) var dismiss

    @State private var selectedProductID = StoreKitService.annualProductID
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "060612"), Color(hex: "0D0B2A"), Color(hex: "060612")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )

                        Text("MyWellness Premium")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text("Your AI-powered health coach.\nPersonalized for you, every day.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }

                    // Feature list
                    VStack(spacing: 14) {
                        FeatureRow(icon: "sparkles",       color: .teal,   text: "AI-generated meal plans (7 days/week)")
                        FeatureRow(icon: "dumbbell.fill",  color: .purple, text: "Personalized workout programs")
                        FeatureRow(icon: "person.crop.rectangle.badge.plus", color: .blue, text: "Body scan & AI composition analysis")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", color: .green, text: "Weight & progress tracking")
                        FeatureRow(icon: "cart.fill",      color: .orange, text: "Automatic shopping lists")
                        FeatureRow(icon: "arrow.clockwise", color: .pink,  text: "Unlimited plan regenerations")
                    }
                    .padding(.horizontal, 20)

                    // Trial badge
                    HStack(spacing: 8) {
                        Image(systemName: "gift.fill").foregroundColor(.teal)
                        Text("3-day free trial — cancel anytime")
                            .font(.subheadline.bold())
                            .foregroundColor(.teal)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.teal.opacity(0.15)))

                    // Plan selector
                    VStack(spacing: 12) {
                        if store.products.isEmpty {
                            ProgressView().tint(.teal)
                        } else {
                            // Annual plan
                            if let annual = store.annualProduct {
                                PlanCard(
                                    title: "Annual",
                                    badge: "Best Value — Save 58%",
                                    price: annual.displayPrice,
                                    priceDetail: "then \(annual.displayPrice)/year",
                                    trialText: store.trialInfo(for: annual),
                                    perMonth: annualPerMonth(annual),
                                    isSelected: selectedProductID == annual.id,
                                    isRecommended: true
                                ) {
                                    selectedProductID = annual.id
                                }
                            }

                            // Monthly plan
                            if let monthly = store.monthlyProduct {
                                PlanCard(
                                    title: "Monthly",
                                    badge: nil,
                                    price: monthly.displayPrice,
                                    priceDetail: "\(monthly.displayPrice)/month",
                                    trialText: store.trialInfo(for: monthly),
                                    perMonth: nil,
                                    isSelected: selectedProductID == monthly.id,
                                    isRecommended: false
                                ) {
                                    selectedProductID = monthly.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // CTA button
                    Button {
                        Task { await startPurchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                VStack(spacing: 4) {
                                    Text("Start Free Trial")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    Text("3 days free, then auto-renews")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.teal, Color(hex: "7C3AED")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .teal.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(isPurchasing || store.products.isEmpty)
                    .padding(.horizontal, 20)

                    // Restore + legal
                    VStack(spacing: 10) {
                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))

                        Text("Payment will be charged to your Apple ID. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. You can manage your subscription in App Store settings.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
    }

    // MARK: - Purchase action

    private func startPurchase() async {
        guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await store.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Helpers

    private func annualPerMonth(_ product: Product) -> String? {
        guard let price = product.price as Decimal? else { return nil }
        let monthly = (price / 12)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatStyle.locale.currency?.identifier ?? "EUR"
        return formatter.string(from: monthly as NSDecimalNumber).map { "\($0)/mo" }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let title: String
    let badge: String?
    let price: String
    let priceDetail: String
    let trialText: String?
    let perMonth: String?
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.white)

                            if isRecommended {
                                Text("RECOMMENDED")
                                    .font(.caption2.bold())
                                    .foregroundColor(.teal)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.teal.opacity(0.2)))
                            }
                        }

                        if let badge {
                            Text(badge)
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        if let perMonth {
                            Text(perMonth)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                if let trial = trialText {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill").font(.caption).foregroundColor(.teal)
                        Text(trial).font(.caption.bold()).foregroundColor(.teal)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.teal.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected
                                    ? LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.12)], startPoint: .leading, endPoint: .trailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }
}
