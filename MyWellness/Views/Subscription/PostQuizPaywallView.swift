import SwiftUI
import StoreKit

struct PostQuizPaywallView: View {
    @EnvironmentObject var store: StoreKitService
    @Environment(\.dismiss) var dismiss

    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showReminder = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var timelineAnimated = false

    enum PlanType { case monthly, annual }

    var body: some View {
        ZStack {
            Color(hex: "FAFAFA").ignoresSafeArea()

            if showReminder {
                ReminderScreen(
                    onContinue: { Task { await startPurchase() } },
                    isPurchasing: isPurchasing
                )
            } else {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            headerSection
                            if selectedPlan == .annual {
                                trialTimeline
                            } else {
                                featureList
                            }
                            Color.clear.frame(height: 160)
                        }
                        .padding(.top, 24)
                    }
                    bottomBar
                }
            }
        }
        .alert("Errore", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            if store.products.isEmpty { await store.loadProducts() }
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )

            Text(selectedPlan == .annual ? "Inizia il tuo Trial Gratuito" : "Passa a Premium")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(hex: "111111"))
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.2), value: selectedPlan)

            Text("Nessun vincolo · Cancella quando vuoi")
                .font(.subheadline)
                .foregroundColor(Color(hex: "888888"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Trial Timeline (Annual)

    var trialTimeline: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(timelineSteps.indices, id: \.self) { i in
                    TimelineStep(
                        step: timelineSteps[i],
                        isActive: timelineAnimated,
                        delay: Double(i) * 0.3
                    )
                    if i < timelineSteps.count - 1 {
                        TimelineConnector(animated: timelineAnimated, delay: Double(i) * 0.3 + 0.15)
                    }
                }
            }
            .padding(.horizontal, 24)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.8)) { timelineAnimated = true }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(hex: "F59E0B"))
                Text("Nessun Pagamento Richiesto Ora")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "92400E"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "FEF3C7")))
        }
    }

    var timelineSteps: [TimelineStepData] {
        let date3 = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return [
            TimelineStepData(icon: "lock.fill",  label: "Oggi",     detail: "Sblocca tutte le funzionalita premium.",              color: Color(hex: "F59E0B")),
            TimelineStepData(icon: "bell.fill",  label: "Giorno 2", detail: "Ti avvisiamo prima della fine del trial.",             color: Color(hex: "F59E0B")),
            TimelineStepData(icon: "crown.fill", label: "Giorno 3", detail: "Addebito il \(fmt.string(from: date3)) se non cancelli.", color: Color(hex: "111111"))
        ]
    }

    // MARK: - Feature List (Monthly)

    var featureList: some View {
        VStack(spacing: 14) {
            PaywallFeatureRow(emoji: "🥗", title: "Piano nutrizionale AI",  subtitle: "7 giorni di pasti personalizzati ogni settimana")
            PaywallFeatureRow(emoji: "🏋️", title: "Programma workout",       subtitle: "Workout personalizzati sul tuo livello")
            PaywallFeatureRow(emoji: "🧬", title: "Body Scan AI",            subtitle: "Analisi composizione corporea con foto")
            PaywallFeatureRow(emoji: "📊", title: "Tracking progressi",      subtitle: "Peso, calorie, macro in tempo reale")
            PaywallFeatureRow(emoji: "🛒", title: "Lista della spesa",       subtitle: "Generata automaticamente dal piano")
            PaywallFeatureRow(emoji: "📸", title: "Analisi pasti con foto",  subtitle: "Scatta una foto e calcola le calorie")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 12) {
                // Plan cards
                HStack(spacing: 10) {
                    PlanSelectorCard(
                        label: "Mensile",
                        price: store.monthlyProduct?.displayPrice ?? "9.99",
                        perMonth: nil,
                        badge: nil,
                        isSelected: selectedPlan == .monthly
                    ) { selectedPlan = .monthly }

                    PlanSelectorCard(
                        label: "Annuale",
                        price: "4.16/mese",
                        perMonth: store.annualProduct?.displayPrice ?? "49.99",
                        badge: "3 Giorni Gratis",
                        isSelected: selectedPlan == .annual
                    ) { selectedPlan = .annual }
                }

                // CTA
                Button {
                    if selectedPlan == .annual { showReminder = true }
                    else { Task { await startPurchase() } }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(selectedPlan == .annual ? "Inizia il Trial Gratuito" : "Inizia il tuo Percorso")
                                .font(.body.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "111111"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing)

                Text(selectedPlan == .annual ? "3 giorni gratis, poi 49.99/anno" : "9.99/mese, cancella quando vuoi")
                    .font(.caption)
                    .foregroundColor(Color(hex: "888888"))

                Button("Ripristina acquisti") {
                    Task { await store.restorePurchases() }
                }
                .font(.caption)
                .foregroundColor(Color(hex: "AAAAAA"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }

    // MARK: - Purchase

    private func startPurchase() async {
        let product = selectedPlan == .monthly ? store.monthlyProduct : store.annualProduct
        guard let product else { return }
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
}

// MARK: - Reminder Screen

struct ReminderScreen: View {
    let onContinue: () -> Void
    let isPurchasing: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF3C7"))
                        .frame(width: 100, height: 100)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                Circle()
                    .fill(Color.red)
                    .frame(width: 28, height: 28)
                    .overlay(Text("1").font(.caption2.bold()).foregroundColor(.white))
                    .offset(x: 4, y: -4)
            }

            VStack(spacing: 10) {
                Text("Nessun Pagamento\nRichiesto Ora")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "111111"))
                    .multilineTextAlignment(.center)
                Text("Il tuo trial di 3 giorni inizia oggi.\nSarai avvisato prima che termini.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onContinue) {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continua Gratis")
                            .font(.body.bold())
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "111111"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isPurchasing)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "FAFAFA").ignoresSafeArea())
    }
}

// MARK: - Timeline Components

struct TimelineStepData {
    let icon: String
    let label: String
    let detail: String
    let color: Color
}

struct TimelineStep: View {
    let step: TimelineStepData
    let isActive: Bool
    let delay: Double
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(appeared ? step.color : Color(hex: "E5E7EB"))
                    .frame(width: 44, height: 44)
                    .animation(.easeInOut(duration: 0.5).delay(delay), value: appeared)
                Image(systemName: step.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(appeared ? .white : Color(hex: "9CA3AF"))
                    .animation(.easeInOut(duration: 0.5).delay(delay), value: appeared)
            }
            Text(step.label)
                .font(.caption.bold())
                .foregroundColor(Color(hex: "111111"))
            Text(step.detail)
                .font(.caption2)
                .foregroundColor(Color(hex: "888888"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { appeared = isActive }
        }
        .onChange(of: isActive) { _, newValue in appeared = newValue }
    }
}

struct TimelineConnector: View {
    let animated: Bool
    let delay: Double
    @State private var active = false

    var body: some View {
        Rectangle()
            .fill(active ? Color(hex: "F59E0B") : Color(hex: "E5E7EB"))
            .frame(height: 3)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 60)
            .animation(.easeInOut(duration: 0.5).delay(delay), value: active)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { active = animated }
            }
            .onChange(of: animated) { _, newValue in if newValue { active = true } }
    }
}

// MARK: - Feature Row

struct PaywallFeatureRow: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "111111"))
                    .frame(width: 38, height: 38)
                Text(emoji).font(.body)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "111111"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color(hex: "666666"))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "10B981"))
                .font(.title3)
        }
    }
}

// MARK: - Plan Selector Card

struct PlanSelectorCard: View {
    let label: String
    let price: String
    let perMonth: String?
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "111111"))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "111111"))
                    }
                }
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: "111111")))
                }
                Text(price)
                    .font(.headline.bold())
                    .foregroundColor(Color(hex: "111111"))
                if let perMonth {
                    Text(perMonth + "/anno")
                        .font(.caption)
                        .foregroundColor(Color(hex: "888888"))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color(hex: "111111") : Color(hex: "E5E7EB"),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
