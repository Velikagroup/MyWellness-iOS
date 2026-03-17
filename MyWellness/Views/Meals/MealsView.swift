import SwiftUI

struct MealsView: View {
    @StateObject private var vm = MealsViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var store: StoreKitService

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Paywall banner for non-subscribers
                    PaywallBanner()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Day selector
                    DaySelector(days: vm.days, selectedIndex: $vm.selectedDay)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    // Daily macros summary
                    if !vm.mealsForSelectedDay.isEmpty {
                        DailyMacrosSummary(
                            totals: vm.dailyTotals,
                            target: authVM.currentUser?.daily_calories ?? 2000
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    // Meal list
                    ScrollView {
                        if vm.isGenerating {
                            GeneratingView(progress: vm.generationProgress, step: vm.generationStep)
                                .padding(20)
                        } else if vm.mealsForSelectedDay.isEmpty {
                            // Gate empty state: show paywall if not subscribed
                            if store.isSubscribed {
                                EmptyMealsView { vm.showGenerationWizard = true }
                                    .padding(20)
                            } else {
                                EmptyMealsView { vm.showGenerationWizard = true }
                                    .padding(20)
                                    .paywallGated()
                                    .padding(.horizontal, 16)
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.mealsForSelectedDay) { meal in
                                    MealCard(meal: meal) {
                                        vm.selectedMeal = meal
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                        }
                    }
                    .refreshable { await vm.load() }
                }

                if vm.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    PaywallButton(action: { vm.showGenerationWizard = true }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.teal)
                    }
                    Button {
                        vm.showShoppingList = true
                    } label: {
                        Image(systemName: "cart")
                            .foregroundColor(.teal)
                    }
                }
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $vm.showGenerationWizard) {
            MealGenerationWizard { prefs in
                await vm.generatePlan(preferences: prefs)
            }
        }
        .sheet(item: $vm.selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
    }
}

// MARK: - Day Selector

struct DaySelector: View {
    let days: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days.indices, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedIndex = i }
                    } label: {
                        Text(days[i])
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedIndex == i ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedIndex == i
                                    ? RoundedRectangle(cornerRadius: 20).fill(Color.teal.opacity(0.4))
                                    : RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07))
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Daily Macros Summary

struct DailyMacrosSummary: View {
    let totals: (calories: Double, protein: Double, carbs: Double, fat: Double)
    let target: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(totals.calories)) kcal")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("of \(Int(target)) target")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 16) {
                MacroStat(label: "P", value: totals.protein, color: .blue)
                MacroStat(label: "C", value: totals.carbs, color: .orange)
                MacroStat(label: "F", value: totals.fat, color: .yellow)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.15), Color.purple.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.teal.opacity(0.3)))
        )
    }
}

struct MacroStat: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.subheadline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: MealPlan
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 10)
                    .fill(mealGradient)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(mealEmoji)
                            .font(.title)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    if meal.is_cheat_meal == true {
                        Text("CHEAT MEAL")
                            .font(.caption2.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.2)))
                    }

                    Text(meal.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(meal.mealTypeFormatted)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 8) {
                        Text("🔥 \(Int(meal.calories))")
                        Text("P: \(Int(meal.protein))g")
                        Text("C: \(Int(meal.carbs))g")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08)))
            )
        }
        .buttonStyle(.plain)
    }

    var mealEmoji: String {
        switch meal.meal_type.lowercased() {
        case "breakfast": return "🌅"
        case "lunch": return "🥗"
        case "dinner": return "🍽️"
        default: return "🍎"
        }
    }

    var mealGradient: LinearGradient {
        switch meal.meal_type.lowercased() {
        case "breakfast": return LinearGradient(colors: [.orange.opacity(0.3), .yellow.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "lunch": return LinearGradient(colors: [.green.opacity(0.3), .teal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dinner": return LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.purple.opacity(0.3), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Meal Detail View

struct MealDetailView: View {
    let meal: MealPlan
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D1F").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.teal.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .overlay(Text("🍽️").font(.system(size: 60)))

                        Group {
                            // Macros grid
                            HStack(spacing: 12) {
                                MetricCard(label: "Calories", value: "\(Int(meal.calories))", unit: "kcal", color: .orange)
                                MetricCard(label: "Protein", value: "\(Int(meal.protein))", unit: "g", color: .blue)
                                MetricCard(label: "Carbs", value: "\(Int(meal.carbs))", unit: "g", color: .green)
                                MetricCard(label: "Fat", value: "\(Int(meal.fat))", unit: "g", color: .yellow)
                            }

                            // Ingredients
                            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Ingredients")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    ForEach(ingredients) { ing in
                                        HStack {
                                            Circle().fill(Color.teal).frame(width: 6, height: 6)
                                            Text(ing.name)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.85))
                                            Spacer()
                                            if let qty = ing.quantity {
                                                Text("\(qty) \(ing.unit ?? "")")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                    }
                                }
                            }

                            // Instructions
                            if let instructions = meal.instructions {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Instructions")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(instructions)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineSpacing(6)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}

// MARK: - Generating View

struct GeneratingView: View {
    let progress: Double
    let step: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .tint(.teal)
                .scaleEffect(x: 1, y: 2)

            Text(step)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Text("Please don't close the app")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }
}

// MARK: - Empty Meals View

struct EmptyMealsView: View {
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.teal.opacity(0.6))

            Text("No meal plan yet")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Generate your personalized meal plan with AI")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button(action: onGenerate) {
                Label("Generate with AI", systemImage: "sparkles")
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
        }
        .padding(30)
    }
}

// MARK: - Meal Generation Wizard

struct MealGenerationWizard: View {
    let onGenerate: (MealGenerationPreferences) async -> Void
    @State private var prefs = MealGenerationPreferences()
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss

    let dietTypes = ["Balanced", "Mediterranean", "Low Carb", "Keto", "Vegan", "Vegetarian", "Carnivore", "Paleo"]
    let cookingTimes = [("quick", "Quick (< 30 min)"), ("moderate", "Moderate (30-60 min)"), ("relaxed", "Relaxed (60+ min)")]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D1F").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Diet type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Diet Type").font(.headline).foregroundColor(.white)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(dietTypes, id: \.self) { diet in
                                    Button {
                                        prefs.dietType = diet.lowercased().replacingOccurrences(of: " ", with: "_")
                                    } label: {
                                        Text(diet)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(prefs.dietType == diet.lowercased().replacingOccurrences(of: " ", with: "_")
                                                          ? Color.teal.opacity(0.3)
                                                          : Color.white.opacity(0.07))
                                            )
                                    }
                                }
                            }
                        }

                        // Cooking time
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cooking Time").font(.headline).foregroundColor(.white)
                            ForEach(cookingTimes, id: \.0) { value, label in
                                QuizOptionButton(
                                    title: label,
                                    isSelected: prefs.cookingTime == value,
                                    action: { prefs.cookingTime = value }
                                )
                            }
                        }

                        // IF toggle
                        Toggle(isOn: $prefs.intermittentFasting) {
                            VStack(alignment: .leading) {
                                Text("Intermittent Fasting")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("Skip breakfast (16:8 protocol)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .tint(.teal)

                        // Meals per day
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meals per day: \(prefs.mealsPerDay)").font(.headline).foregroundColor(.white)
                            Slider(value: Binding(
                                get: { Double(prefs.mealsPerDay) },
                                set: { prefs.mealsPerDay = Int($0) }
                            ), in: 2...6, step: 1)
                            .tint(.teal)
                        }

                        // Generate button
                        Button {
                            isLoading = true
                            Task {
                                await onGenerate(prefs)
                                isLoading = false
                            }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Generate Plan", systemImage: "sparkles")
                                        .font(.body.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading)
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Generate Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}
