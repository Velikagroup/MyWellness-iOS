import Foundation

@MainActor
class MealsViewModel: ObservableObject {
    @Published var mealPlans: [MealPlan] = []
    @Published var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 2  // 0=Mon
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var generationStep: String = ""
    @Published var showGenerationWizard = false
    @Published var showShoppingList = false
    @Published var selectedMeal: MealPlan?
    @Published var error: String?

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

    var selectedDayName: String { dayNames[max(0, min(selectedDay, 6))] }

    var mealsForSelectedDay: [MealPlan] {
        mealPlans
            .filter { $0.day_of_week.lowercased() == selectedDayName }
            .sorted { mealTypeOrder($0.meal_type) < mealTypeOrder($1.meal_type) }
    }

    var dailyTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        mealsForSelectedDay.reduce((0,0,0,0)) { acc, meal in
            (acc.0 + meal.calories, acc.1 + meal.protein, acc.2 + meal.carbs, acc.3 + meal.fat)
        }
    }

    private func mealTypeOrder(_ type: String) -> Int {
        switch type.lowercased() {
        case "breakfast": return 0
        case "snack": return 1
        case "lunch": return 2
        case "dinner": return 3
        default: return 4
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            mealPlans = try await APIService.shared.listMealPlans()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func generatePlan(preferences: MealGenerationPreferences) async {
        isGenerating = true
        generationProgress = 0

        let steps = [
            "Analyzing your metabolic profile...",
            "Calculating macronutrients...",
            "Selecting foods based on preferences...",
            "Building your weekly schedule...",
            "Optimizing meal timing...",
            "Generating shopping list...",
            "Saving your plan..."
        ]

        for (i, step) in steps.enumerated() {
            generationStep = step
            generationProgress = Double(i + 1) / Double(steps.count)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        // After generation, reload
        await load()
        isGenerating = false
        showGenerationWizard = false
    }
}

struct MealGenerationPreferences {
    var dietType: String = "balanced"
    var cookingTime: String = "moderate"
    var intermittentFasting: Bool = false
    var fastingWindow: String?
    var allergies: [String] = []
    var mealsPerDay: Int = 4
}
