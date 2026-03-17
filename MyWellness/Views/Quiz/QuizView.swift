import SwiftUI

struct QuizView: View {
    @StateObject private var vm = QuizViewModel()
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A0A1A"), Color(hex: "0D1B2A"), Color(hex: "0A1628")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if vm.currentStep != .calculating {
                    QuizProgressBar(progress: vm.progress)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Back button
                    HStack {
                        if vm.canGoBack {
                            Button(action: vm.back) {
                                Image(systemName: "chevron.left")
                                    .font(.title3.bold())
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                // Step content
                Group {
                    switch vm.currentStep {
                    case .gender:
                        GenderStepView(selection: $vm.quizData.gender, onNext: vm.next)
                    case .birthdate:
                        BirthdateStepView(date: $vm.quizData.birthdate, onNext: vm.next)
                    case .heightWeight:
                        HeightWeightStepView(
                            height: $vm.quizData.height,
                            weight: $vm.quizData.current_weight,
                            onNext: vm.next
                        )
                    case .targetWeight:
                        TargetWeightStepView(
                            currentWeight: vm.quizData.current_weight,
                            target: $vm.quizData.target_weight,
                            onNext: vm.next
                        )
                    case .weightDifference:
                        WeightDifferenceStepView(
                            currentWeight: vm.quizData.current_weight,
                            targetWeight: vm.quizData.target_weight,
                            onNext: vm.next
                        )
                    case .weightLossSpeed:
                        WeightLossSpeedStepView(selection: $vm.quizData.weight_loss_speed, onNext: vm.next)
                    case .aiComparison:
                        AIComparisonStepView(onNext: vm.next)
                    case .currentBodyType:
                        BodyTypeStepView(
                            title: "Com'è il tuo corpo adesso?",
                            selection: $vm.quizData.current_body_type,
                            onNext: vm.next
                        )
                    case .targetZone:
                        TargetZoneStepView(selection: $vm.quizData.target_zones, onNext: vm.next)
                    case .targetBodyType:
                        BodyTypeStepView(
                            title: "Come vuoi diventare?",
                            selection: $vm.quizData.target_body_type,
                            onNext: vm.next
                        )
                    case .obstacles:
                        MultiSelectStepView(
                            title: QuizStep.obstacles.title,
                            options: obstacleOptions,
                            selection: Binding(
                                get: { vm.quizData.obstacles ?? [] },
                                set: { vm.quizData.obstacles = $0 }
                            ),
                            onNext: vm.next
                        )
                    case .dietType:
                        DietTypeStepView(selection: $vm.quizData.diet_type, onNext: vm.next)
                    case .goals:
                        MultiSelectStepView(
                            title: QuizStep.goals.title,
                            options: goalOptions,
                            selection: Binding(
                                get: { vm.quizData.goals ?? [] },
                                set: { vm.quizData.goals = $0 }
                            ),
                            onNext: vm.next
                        )
                    case .weightPotential:
                        WeightPotentialStepView(
                            currentWeight: vm.quizData.current_weight,
                            targetWeight: vm.quizData.target_weight,
                            onNext: vm.next
                        )
                    case .trust:
                        TrustStepView(onNext: vm.next)
                    case .referralCode:
                        ReferralCodeStepView(code: $vm.quizData.referral_code, onNext: vm.next)
                    case .readyToGenerate:
                        ReadyToGenerateStepView(quizData: vm.quizData, onNext: vm.next)
                    case .calculating:
                        CalculatingStepView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .sheet(isPresented: $vm.showAuthSheet) {
            AuthView { email, password, name in
                if let name {
                    await authVM.register(email: email, password: password, name: name)
                } else {
                    await authVM.login(email: email, password: password)
                }
                vm.showAuthSheet = false
            }
        }
    }

    private let obstacleOptions = [
        "Mancanza di motivazione", "Poco tempo", "Stress", "Cattive abitudini",
        "Metabolismo lento", "Fame emotiva", "Infortuni", "Mancanza di sonno"
    ]

    private let goalOptions = [
        "Perdere peso", "Tonificare i muscoli", "Migliorare la salute", "Più energia",
        "Dormire meglio", "Ridurre lo stress", "Aumentare la flessibilità", "Correre più veloce"
    ]
}

struct QuizProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.teal, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}
