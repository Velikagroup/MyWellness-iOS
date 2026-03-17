import SwiftUI

// MARK: - Target Weight Step

struct TargetWeightStepView: View {
    let currentWeight: Double?
    @Binding var target: Double?
    let onNext: () -> Void
    @State private var targetText = ""

    var body: some View {
        QuizStepContainer(
            title: "What's your target weight?",
            subtitle: currentWeight != nil ? "Current: \(String(format: "%.1f", currentWeight!)) kg" : nil
        ) {
            VStack(spacing: 20) {
                TextField("Target weight (kg)", text: $targetText)
                    .keyboardType(.decimalPad)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15)))

                QuizNextButton(isEnabled: !targetText.isEmpty) {
                    target = Double(targetText)
                    onNext()
                }
            }
        }
    }
}

// MARK: - Weight Loss Speed Step

struct WeightLossSpeedStepView: View {
    @Binding var selection: String?
    let onNext: () -> Void

    let options: [(String, String, String)] = [
        ("slow", "Slow & Steady", "0.25 kg/week — easier to maintain"),
        ("moderate", "Moderate", "0.5 kg/week — recommended"),
        ("fast", "Aggressive", "1 kg/week — requires discipline")
    ]

    var body: some View {
        QuizStepContainer(title: "How fast do you want to lose weight?") {
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { value, title, subtitle in
                    QuizOptionButton(
                        title: title,
                        subtitle: subtitle,
                        isSelected: selection == value,
                        action: {
                            selection = value
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Body Type Step (reused for both current and target body type)

struct BodyTypeStepView: View {
    var title: String = "Com'è il tuo corpo adesso?"
    @Binding var selection: String?
    let onNext: () -> Void

    let options: [(String, String, String)] = [
        ("slim",     "Snello",    "Massa grassa bassa, corporatura leggera"),
        ("average",  "Nella media", "Composizione corporea moderata"),
        ("stocky",   "Robusto",   "Struttura più pesante, più grasso"),
        ("athletic", "Atletico",  "Muscoloso e tonico"),
        ("obese",    "In sovrappeso", "Percentuale di grasso elevata")
    ]

    var body: some View {
        QuizStepContainer(title: title) {
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { value, optTitle, subtitle in
                    QuizOptionButton(
                        title: optTitle,
                        subtitle: subtitle,
                        isSelected: selection == value,
                        action: {
                            selection = value
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Target Zone Step

struct TargetZoneStepView: View {
    @Binding var selection: [String]?
    let onNext: () -> Void

    let options = ["Belly", "Arms", "Legs", "Back", "Glutes", "Chest", "Shoulders", "Full body"]

    var body: some View {
        QuizStepContainer(title: "Where do you want to focus?", subtitle: "Select all that apply") {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection?.contains(option) ?? false
                    QuizOptionButton(
                        title: option,
                        isSelected: isSelected,
                        action: { toggle(option) }
                    )
                }
                QuizNextButton(isEnabled: !(selection?.isEmpty ?? true), action: onNext)
            }
        }
    }

    private func toggle(_ option: String) {
        if selection == nil { selection = [] }
        if selection!.contains(option) {
            selection!.removeAll { $0 == option }
        } else {
            selection!.append(option)
        }
    }
}

// MARK: - Activity Level Step

struct ActivityLevelStepView: View {
    @Binding var selection: String?
    let onNext: () -> Void

    let options: [(String, String, String)] = [
        ("sedentary", "Sedentary", "Little to no exercise"),
        ("lightly_active", "Lightly Active", "Exercise 1-3 days/week"),
        ("moderately_active", "Moderately Active", "Exercise 3-5 days/week"),
        ("very_active", "Very Active", "Exercise 6-7 days/week"),
        ("extra_active", "Extra Active", "Physical job + daily training")
    ]

    var body: some View {
        QuizStepContainer(title: "How active are you?") {
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { value, title, subtitle in
                    QuizOptionButton(
                        title: title,
                        subtitle: subtitle,
                        isSelected: selection == value,
                        action: {
                            selection = value
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Diet Type Step

struct DietTypeStepView: View {
    @Binding var selection: String?
    let onNext: () -> Void

    let options: [(String, String, String)] = [
        ("balanced", "Balanced", "All food groups"),
        ("mediterranean", "Mediterranean", "Fish, olive oil, vegetables"),
        ("low_carb", "Low Carb", "Reduce carbohydrates"),
        ("keto", "Keto", "High fat, very low carbs"),
        ("vegan", "Vegan", "No animal products"),
        ("vegetarian", "Vegetarian", "No meat"),
        ("carnivore", "Carnivore", "Mainly meat and animal products"),
        ("paleo", "Paleo", "No processed foods")
    ]

    var body: some View {
        QuizStepContainer(title: "What diet do you prefer?") {
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { value, title, subtitle in
                    QuizOptionButton(
                        title: title,
                        subtitle: subtitle,
                        isSelected: selection == value,
                        action: {
                            selection = value
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Multi Select Step (Obstacles, Goals, Allergies)

struct MultiSelectStepView: View {
    let title: String
    let options: [String]
    @Binding var selection: [String]
    let onNext: () -> Void

    var body: some View {
        QuizStepContainer(title: title, subtitle: "Select all that apply") {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    QuizOptionButton(
                        title: option,
                        isSelected: selection.contains(option),
                        action: { toggle(option) }
                    )
                }
                QuizNextButton(action: onNext)
            }
        }
    }

    private func toggle(_ option: String) {
        if selection.contains(option) {
            selection.removeAll { $0 == option }
        } else {
            selection.append(option)
        }
    }
}

// MARK: - Referral Code Step

struct ReferralCodeStepView: View {
    @Binding var code: String?
    let onNext: () -> Void
    @State private var codeText = ""

    var body: some View {
        QuizStepContainer(
            title: "Do you have a referral code?",
            subtitle: "Optional — leave blank to skip"
        ) {
            VStack(spacing: 20) {
                TextField("Enter code", text: $codeText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15)))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)

                QuizNextButton(title: codeText.isEmpty ? "Skip" : "Continue") {
                    code = codeText.isEmpty ? nil : codeText
                    onNext()
                }
            }
        }
    }
}

// MARK: - Weight Difference Step

struct WeightDifferenceStepView: View {
    let currentWeight: Double?
    let targetWeight: Double?
    let onNext: () -> Void

    var diff: Double { abs((targetWeight ?? 0) - (currentWeight ?? 0)) }
    var isLosing: Bool { (targetWeight ?? 0) < (currentWeight ?? 0) }

    var message: (String, String) {
        switch diff {
        case ..<4:   return ("È un obiettivo realistico.", "Non difficile per niente! Il 90% degli utenti ci riesce.")
        case 4..<9:  return ("È un obiettivo realistico.", "Assolutamente raggiungibile! L'88% degli utenti ce la fa.")
        case 9..<16: return ("È un obiettivo impegnativo ma raggiungibile.", "L'85% degli utenti raggiunge questo traguardo.")
        default:     return ("È un obiettivo ambizioso.", "Con il piano giusto, ce la puoi fare.")
        }
    }

    var body: some View {
        QuizStepContainer(
            title: isLosing ? "Vuoi perdere \(String(format: "%.0f", diff)) kg" : "Vuoi guadagnare \(String(format: "%.0f", diff)) kg"
        ) {
            VStack(spacing: 20) {
                // Visual highlight
                VStack(spacing: 8) {
                    Text("\(String(format: "%.0f", diff)) kg")
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                    Text(isLosing ? "da perdere" : "da guadagnare")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 16)

                // Message card
                VStack(spacing: 8) {
                    Text(message.0)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(message.1)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.teal.opacity(0.12)))

                QuizNextButton(action: onNext)
            }
        }
    }
}

// MARK: - AI Comparison Step

struct AIComparisonStepView: View {
    let onNext: () -> Void
    @State private var animated = false

    var body: some View {
        QuizStepContainer(
            title: "Con MyWellness perdi il doppio",
            subtitle: "Il nostro AI ti accompagna in ogni passo del percorso"
        ) {
            VStack(spacing: 24) {
                // Bars comparison
                HStack(alignment: .bottom, spacing: 32) {
                    // Without
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 80, height: 180)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 80, height: animated ? 36 : 0)
                                .animation(.easeOut(duration: 0.8).delay(0.2), value: animated)
                        }
                        Text("Senza\nMyWellness")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        Text("20%")
                            .font(.headline.bold())
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // With MyWellness
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 80, height: 180)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.teal, .purple], startPoint: .top, endPoint: .bottom))
                                .frame(width: 80, height: animated ? 180 : 0)
                                .animation(.easeOut(duration: 1.0).delay(0.4), value: animated)
                            if animated {
                                Text("2X")
                                    .font(.title.black)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        Text("Con\nMyWellness")
                            .font(.caption.bold())
                            .foregroundColor(.teal)
                            .multilineTextAlignment(.center)
                        Text("100%")
                            .font(.headline.bold())
                            .foregroundColor(.teal)
                    }
                }
                .padding(.vertical, 8)

                QuizNextButton(action: onNext)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { animated = true }
            }
        }
    }
}

// MARK: - Weight Potential Step

struct WeightPotentialStepView: View {
    let currentWeight: Double?
    let targetWeight: Double?
    let onNext: () -> Void
    @State private var animated = false

    var isLosing: Bool { (targetWeight ?? 0) < (currentWeight ?? 0) }
    var diff: Double { abs((targetWeight ?? 0) - (currentWeight ?? 0)) }

    var chartPoints: [CGFloat] {
        // Simulated weight curve: slow start, then accelerating
        [0, 0.05, 0.12, 0.22, 0.35, 0.5, 0.65, 0.78, 0.88, 0.95, 1.0]
    }

    var body: some View {
        QuizStepContainer(
            title: "Hai un grande potenziale!",
            subtitle: "Secondo i dati di MyWellness, puoi raggiungere il tuo obiettivo"
        ) {
            VStack(spacing: 24) {
                // Animated chart
                GeometryReader { geo in
                    ZStack {
                        // Grid lines
                        ForEach(0..<4) { i in
                            Path { p in
                                let y = geo.size.height * CGFloat(i) / 3
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        }

                        // Fill area
                        if animated {
                            Path { path in
                                let pts = chartPoints.enumerated().map { i, v in
                                    CGPoint(
                                        x: geo.size.width * CGFloat(i) / CGFloat(chartPoints.count - 1),
                                        y: geo.size.height * (1 - v)
                                    )
                                }
                                path.move(to: CGPoint(x: 0, y: geo.size.height))
                                for pt in pts { path.addLine(to: pt) }
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                path.closeSubpath()
                            }
                            .fill(LinearGradient(colors: [Color.teal.opacity(0.3), Color.teal.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                            .transition(.opacity)
                        }

                        // Line
                        Path { path in
                            let pts = chartPoints.enumerated().map { i, v in
                                CGPoint(
                                    x: geo.size.width * CGFloat(i) / CGFloat(chartPoints.count - 1),
                                    y: geo.size.height * (1 - (animated ? v : 0))
                                )
                            }
                            path.move(to: pts[0])
                            for pt in pts.dropFirst() { path.addLine(to: pt) }
                        }
                        .stroke(Color.teal, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .animation(.easeOut(duration: 1.2), value: animated)

                        // Goal heart at end
                        if animated {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.teal)
                                .font(.title2)
                                .position(x: geo.size.width - 10, y: 10)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Day labels
                        HStack {
                            Text("Giorno 3").font(.caption2).foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("Giorno 7").font(.caption2).foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("Giorno 30").font(.caption2).foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, -20)
                    }
                }
                .frame(height: 140)
                .padding(.bottom, 20)

                Text(isLosing
                     ? "La perdita di peso può essere lenta all'inizio, ma accelera con costanza."
                     : "Il guadagno muscolare richiede costanza, ma i risultati arrivano presto.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                QuizNextButton(action: onNext)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { animated = true }
            }
        }
    }
}

// MARK: - Trust Step

struct TrustStepView: View {
    let onNext: () -> Void
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                // Animated hand + circles
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.08))
                        .frame(width: 160, height: 160)
                        .scaleEffect(scale)
                    Circle()
                        .fill(Color.teal.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .scaleEffect(scale)
                    Text("🤚")
                        .font(.system(size: 60))
                        .scaleEffect(scale)
                }
                .animation(.easeOut(duration: 0.8), value: scale)

                VStack(spacing: 10) {
                    Text("Grazie per fidarti di noi")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Ora personalizziamo MyWellness per te...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                // Privacy badge
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.teal)
                    Text("Le tue informazioni personali sono private e al sicuro")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                .padding(.horizontal, 24)

                QuizNextButton(action: onNext)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .onAppear {
            withAnimation { scale = 1.0 }
        }
    }
}

// MARK: - Ready To Generate Step

struct ReadyToGenerateStepView: View {
    let quizData: QuizData
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.teal.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(LinearGradient(colors: [.teal, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }

                VStack(spacing: 10) {
                    Text("Il tuo piano è pronto\nper essere generato!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Creeremo un piano nutrizionale e di allenamento\n100% personalizzato su di te.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                // Summary chips
                VStack(spacing: 10) {
                    if let bmr = quizData.bmr {
                        SummaryChip(icon: "flame.fill", label: "BMR", value: "\(Int(bmr)) kcal/giorno", color: .orange)
                    }
                    if let cal = quizData.dailyCalories {
                        SummaryChip(icon: "bolt.fill", label: "Fabbisogno", value: "\(Int(cal)) kcal/giorno", color: .teal)
                    }
                    if let bmi = quizData.bmi {
                        SummaryChip(icon: "scalemass", label: "BMI", value: String(format: "%.1f", bmi), color: .purple)
                    }
                }
                .padding(.horizontal, 24)

                QuizNextButton(title: "Genera il mio piano →", action: onNext)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
    }
}

struct SummaryChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(label).font(.subheadline).foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}

// MARK: - Calculating Step

struct CalculatingStepView: View {
    @State private var progress: Double = 0
    @State private var stepIndex = 0

    let steps = [
        "Analisi del tuo profilo metabolico...",
        "Calcolo del fabbisogno calorico...",
        "Costruzione del piano nutrizionale...",
        "Progettazione del programma workout...",
        "Personalizzazione finale...",
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .stroke(Color.teal.opacity(0.2), lineWidth: 4)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient(colors: [.teal, .purple], startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 12) {
                Text("Stiamo creando il tuo piano")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                if stepIndex < steps.count {
                    Text(steps[stepIndex])
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .animation(.easeInOut, value: stepIndex)
                }
            }

            Spacer()
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        let total = Double(steps.count)
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                stepIndex = i
                progress = Double(i + 1) / total
            }
        }
    }
}
