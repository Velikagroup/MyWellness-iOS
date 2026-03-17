import Foundation
import Combine
import SwiftUI

@MainActor
class QuizViewModel: ObservableObject {
    @Published var quizData = QuizData()
    @Published var currentStep: QuizStep = .gender
    @Published var isCalculating = false
    @Published var showAuthSheet = false
    @Published var error: String?

    var progress: Double { currentStep.progress }

    var canGoBack: Bool {
        currentStep != .gender && currentStep != .calculating
    }

    func next() {
        let steps = dynamicSteps()
        guard let idx = steps.firstIndex(of: currentStep) else { return }
        let nextIdx = idx + 1
        if nextIdx >= steps.count {
            finishQuiz(); return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = steps[nextIdx]
        }
    }

    func back() {
        let steps = dynamicSteps()
        guard let idx = steps.firstIndex(of: currentStep), idx > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = steps[idx - 1]
        }
    }

    private func dynamicSteps() -> [QuizStep] {
        let isLosingWeight: Bool = {
            if let cw = quizData.current_weight, let tw = quizData.target_weight { return tw < cw }
            return false
        }()

        var steps: [QuizStep] = [
            .gender,
            .birthdate,
            .heightWeight,
            .targetWeight,
            .weightDifference   // always shown — motivational delta
        ]
        if isLosingWeight {
            steps += [.weightLossSpeed, .aiComparison]
        }
        steps += [
            .currentBodyType,
            .targetZone,
            .targetBodyType,
            .obstacles,
            .dietType,
            .goals,
            .weightPotential,
            .trust,
            .referralCode,
            .readyToGenerate,
            .calculating
        ]
        return steps
    }

    func finishQuiz() {
        withAnimation {
            isCalculating = true
            currentStep = .calculating
        }

        Task {
            try? await Task.sleep(nanoseconds: 5_500_000_000) // 5.5s like web app
            await saveQuizData()
        }
    }

    private func saveQuizData() async {
        var updates: [String: Any] = [:]
        if let g = quizData.gender { updates["gender"] = g }
        if let h = quizData.height { updates["height"] = h }
        if let cw = quizData.current_weight { updates["current_weight"] = cw }
        if let tw = quizData.target_weight { updates["target_weight"] = tw }
        if let al = quizData.activity_level { updates["activity_level"] = al }
        if let dt = quizData.diet_type { updates["diet_type"] = dt }
        if let goals = quizData.goals { updates["fitness_goals"] = goals }
        if let allergies = quizData.allergies { updates["allergies"] = allergies }
        if let bmr = quizData.bmr { updates["bmr"] = bmr }
        if let cal = quizData.dailyCalories { updates["daily_calories"] = cal }
        if let bd = quizData.birthdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updates["birthdate"] = formatter.string(from: bd)
        }
        updates["quiz_completed"] = true

        do {
            _ = try await APIService.shared.updateMe(updates)
            // Also create initial weight history entry
            if let weight = quizData.current_weight {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                _ = try await APIService.shared.createWeightEntry(
                    weight: weight,
                    date: formatter.string(from: Date())
                )
            }
            // Show auth if not logged in
            showAuthSheet = true
        } catch {
            self.error = error.localizedDescription
        }
        isCalculating = false
    }
}
