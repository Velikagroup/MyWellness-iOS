import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var weightHistory: [WeightHistory] = []
    @Published var todayMeals: [MealPlan] = []
    @Published var todayWorkout: WorkoutPlan?
    @Published var progressPhotos: [ProgressPhoto] = []
    @Published var isLoading = false
    @Published var error: String?

    var currentWeight: Double? { weightHistory.first?.weight }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadWeightHistory() }
            group.addTask { await self.loadTodayMeals() }
            group.addTask { await self.loadTodayWorkout() }
        }
    }

    private func loadWeightHistory() async {
        do {
            weightHistory = try await APIService.shared.listWeightHistory()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTodayMeals() async {
        let day = Date().weekdayName
        do {
            todayMeals = try await APIService.shared.listMealPlans(dayOfWeek: day)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTodayWorkout() async {
        let day = Date().weekdayName
        do {
            let plans = try await APIService.shared.listWorkoutPlans()
            todayWorkout = plans.first { $0.day_of_week.lowercased() == day }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logWeight(_ weight: Double) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            let entry = try await APIService.shared.createWeightEntry(
                weight: weight,
                date: formatter.string(from: Date())
            )
            weightHistory.insert(entry, at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
