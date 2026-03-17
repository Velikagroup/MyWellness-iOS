import SwiftUI
import StoreKit

// MARK: - PostQuizPaywallView
// Mirrors /enpostquizsubscription from the web app

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
                ReminderScreen(onContinue: {
                    Task { await startPurchase() }
                }, isPurchasing: isPurchasing)
            } else {
                mainContent
            }
        }
        .alert("Errore", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
        .task { if store.products.isEmpty { await store.loadProducts() } }
    }

    // MARK: - Main Content

    var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Plan-dependent content
                    if selectedPlan == .annual {
                        trialTimeline
                    } else {
                        featureList
                    }

                    // Testimonials
                    testimonialsSection

                    // FAQ
                    faqSection

                    // Bottom spacer for fixed CTA
                    Color.clear.frame(height: 160)
                }
                .padding(.top, 24)
            }

            // Fixed bottom plan selector + CTA
            bottomBar
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: 8) {
            Text(selectedPlan == .annual ? "Start Your 3-Day Free Trial" : "Unlock Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "111111"))
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.25), value: selectedPlan)

            Text("Nessun vincolo · Cancella quando vuoi")
                .font(.subheadline)
                .foregroundColor(Color(hex: "888888"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Trial Timeline (Annual)

    var trialTimeline: some View {
        VStack(spacing: 24) {
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

            // No payment badge
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return [
            TimelineStepData(icon: "lock.fill", label: "Oggi", detail: "Sblocca tutte le funzionalità come scan calorie AI e altro.", color: Color(hex: "F59E0B")),
            TimelineStepData(icon: "bell.fill", label: "Giorno 2", detail: "Ti invieremo un promemoria che il tuo trial sta per finire.", color: Color(hex: "F59E0B")),
            TimelineStepData(icon: "crown.fill", label: "Giorno 3", detail: "Sarai addebitato il \(formatter.string(from: date3)) se non cancelli prima.", color: Color(hex: "111111"))
        ]
    }

    // MARK: - Feature List (Monthly)

    var featureList: some View {
        VStack(spacing: 16) {
            PaywallFeatureRow(emoji: "🧬", title: "Età biologica del tuo corpo", subtitle: "Scopri la tua vera età biologica")
            PaywallFeatureRow(emoji: "📊", title: "Percentuale di massa grassa", subtitle: "Monitoraggio preciso della composizione corporea")
            PaywallFeatureRow(emoji: "💪", title: "Scoperta del tuo somatotipo", subtitle: "Piano personalizzato sul tuo corpo")
            PaywallFeatureRow(emoji: "📸", title: "Scan cibi ed etichette", subtitle: "Traccia calorie con una foto")
            PaywallFeatureRow(emoji: "🥗", title: "Piani nutrizionali AI", subtitle: "7 giorni di pasti personalizzati ogni settimana")
            PaywallFeatureRow(emoji: "🏋️", title: "Programmi di allenamento", subtitle: "Workout personalizzati sul tuo livello")
            PaywallFeatureRow(emoji: "🛒", title: "Lista della spesa intelligente", subtitle: "Generata automaticamente dal tuo piano")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Testimonials

    var testimonialsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cosa dicono i nostri utenti")
                .font(.title2.bold())
                .foregroundColor(Color(hex: "111111"))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(testimonials, id: \.name) { t in
                        TestimonialCard(testimonial: t)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - FAQ

    var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Domande frequenti")
                .font(.title2.bold())
                .foregroundColor(Color(hex: "111111"))
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ForEach(faqs, id: \.question) { faq in
                    FAQRow(faq: faq)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 12) {
                // Plan cards
                HStack(spacing: 10) {
                    // Monthly
                    PlanSelectorCard(
                        label: "Mensile",
                        price: store.monthlyProduct?.displayPrice ?? "€9.99",
                        perMonth: nil,
                        badge: nil,
                        isSelected: selectedPlan == .monthly
                    ) { selectedPlan = .monthly }

                    // Annual
                    PlanSelectorCard(
                        label: "Annuale",
                        price: "€4.16/mo",
                        perMonth: store.annualProduct?.displayPrice ?? "€49.99",
                        badge: "3 Giorni Gratis",
                        isSelected: selectedPlan == .annual
                    ) { selectedPlan = .annual }
                }

                // CTA
                Button {
                    if selectedPlan == .annual {
                        showReminder = true
                    } else {
                        Task { await startPurchase() }
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(selectedPlan == .annual ? "Inizia il Trial Gratuito" : "Inizia il Tuo Percorso")
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

                // Sub-text
                Text(selectedPlan == .annual
                     ? "3 giorni gratis, poi €49.99/anno"
                     : "€9.99/mese, cancella quando vuoi")
                    .font(.caption)
                    .foregroundColor(Color(hex: "888888"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }

    // MARK: - Purchase

    private func startPurchase() async {
        let product: Product?
        switch selectedPlan {
        case .monthly: product = store.monthlyProduct
        case .annual:  product = store.annualProduct
        }
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

            VStack(spacing: 12) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                appeared = isActive
            }
        }
        .onChange(of: isActive) { appeared = $0 }
    }
}

struct TimelineConnector: View {
    let animated: Bool
    let delay: Double
    @State private var progress: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "F59E0B"), Color(hex: "E5E7EB")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: progress == 1 ? .infinity : 2, height: 3)
            .animation(.easeInOut(duration: 0.5).delay(delay), value: progress)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 50)
            .onAppear {
                if animated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { progress = 1 }
                }
            }
            .onChange(of: animated) { if $0 { progress = 1 } }
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
                Text(title).font(.subheadline.bold()).foregroundColor(Color(hex: "111111"))
                Text(subtitle).font(.caption).foregroundColor(Color(hex: "666666"))
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

// MARK: - Testimonial Card

struct TestimonialData {
    let name: String
    let role: String
    let text: String
    let initials: String
}

struct TestimonialCard: View {
    let testimonial: TestimonialData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }

            Text(""\(testimonial.text)"")
                .font(.subheadline)
                .foregroundColor(Color(hex: "333333"))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "111111"))
                        .frame(width: 36, height: 36)
                    Text(testimonial.initials)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(testimonial.name).font(.caption.bold()).foregroundColor(Color(hex: "111111"))
                    Text(testimonial.role).font(.caption2).foregroundColor(Color(hex: "888888"))
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

// MARK: - FAQ Row

struct FAQData {
    let question: String
    let answer: String
}

struct FAQRow: View {
    let faq: FAQData
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(faq.question)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "111111"))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 12)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "888888"))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(faq.answer)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "555555"))
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
    }
}

// MARK: - Data

extension PostQuizPaywallView {
    var testimonials: [TestimonialData] { [
        TestimonialData(name: "Maria Santos",   role: "Studentessa Universitaria", initials: "MS",
            text: "Con il budget da studentessa non potevo permettermi un nutrizionista. MyWellness mi ha creato un piano alimentare economico e completo."),
        TestimonialData(name: "Luca Moretti",   role: "Personal Trainer",          initials: "LM",
            text: "L'analisi fotografica AI è impressionante — rileva progressi che io stesso fatico a notare."),
        TestimonialData(name: "Anna Bianchi",   role: "Insegnante",                initials: "AB",
            text: "In 6 mesi sono tornata a 58kg. L'app ha capito che avevo poco tempo con il neonato."),
        TestimonialData(name: "Thomas Weber",   role: "Software Engineer",         initials: "TW",
            text: "L'approccio scientifico mi ha conquistato. Dashboard con BMR, massa grassa, proiezioni peso..."),
        TestimonialData(name: "Francesca M.",   role: "Farmacista",                initials: "FM",
            text: "Soffro di ipotiroidismo e perdere peso è sempre stato un incubo. -12kg in 6 mesi senza soffrire."),
        TestimonialData(name: "Luca Colombo",   role: "CEO Startup Tech",          initials: "LC",
            text: "Ho perso 14kg in 4 mesi e i miei livelli di energia sono triplicati."),
    ] }

    var faqs: [FAQData] { [
        FAQData(question: "Posso cancellare in qualsiasi momento?",
                answer: "Sì, puoi cancellare quando vuoi senza vincoli o penali. Il servizio resterà attivo fino alla fine del periodo già pagato."),
        FAQData(question: "Cosa include il piano MyWellness?",
                answer: "Il piano include TUTTE le funzionalità: piani nutrizionali e di allenamento personalizzati, generazioni illimitate, analisi AI e Body Scan."),
        FAQData(question: "Che differenza c'è tra piano mensile e annuale?",
                answer: "Entrambi includono le stesse funzionalità. Il piano annuale ti fa risparmiare il 58% (€4,16/mese invece di €9,99/mese)."),
        FAQData(question: "Come funziona il trial gratuito?",
                answer: "Hai 3 giorni completamente gratuiti. Nessun addebito adesso. Ti avvisiamo il giorno prima che il trial finisca."),
        FAQData(question: "Come funziona l'analisi AI dei pasti?",
                answer: "Fotografi il tuo pasto e la nostra AI analizza automaticamente calorie e macronutrienti consumati."),
        FAQData(question: "Come funziona il Body Scan AI?",
                answer: "Carichi foto corpo in più angolazioni e l'AI analizza composizione corporea, massa grassa e ti dà raccomandazioni personalizzate."),
        FAQData(question: "I piani sono personalizzati o generici?",
                answer: "Tutti i piani sono 100% personalizzati in base al tuo profilo, obiettivi, intolleranze e preferenze."),
        FAQData(question: "Cosa succede ai miei dati se cancello?",
                answer: "I tuoi dati rimangono al sicuro per 90 giorni. Dopo vengono eliminati per rispettare la privacy."),
    ] }
}
