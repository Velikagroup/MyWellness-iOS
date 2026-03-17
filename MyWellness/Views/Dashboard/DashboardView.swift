import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showWeightLogger = false
    @State private var showEditCalories = false
    @State private var newCalories = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Good \(greetingTime),")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(authVM.currentUser?.displayName ?? "")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button {
                                showWeightLogger = true
                            } label: {
                                Image(systemName: "scalemass")
                                    .font(.title3)
                                    .foregroundColor(.teal)
                                    .padding(10)
                                    .background(Circle().fill(Color.teal.opacity(0.15)))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Calorie meter
                        if let user = authVM.currentUser {
                            CalorieMeterCard(user: user, todayMeals: vm.todayMeals)
                                .padding(.horizontal, 20)
                        }

                        // Weight progress chart
                        WeightChartCard(
                            weightHistory: vm.weightHistory,
                            targetWeight: authVM.currentUser?.target_weight
                        )
                        .padding(.horizontal, 20)

                        // Today's meals
                        TodayMealsCard(meals: vm.todayMeals)
                            .padding(.horizontal, 20)

                        // Today's workout
                        if let workout = vm.todayWorkout {
                            TodayWorkoutCard(workout: workout)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .refreshable { await vm.load() }

                if vm.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
        .task { await vm.load() }
        .sheet(isPresented: $showWeightLogger) {
            WeightLoggerSheet { weight in
                await vm.logWeight(weight)
                showWeightLogger = false
            }
        }
    }

    var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "morning" }
        else if hour < 17 { return "afternoon" }
        else { return "evening" }
    }
}

// MARK: - Calorie Meter Card

struct CalorieMeterCard: View {
    let user: User
    let todayMeals: [MealPlan]

    var consumedCalories: Double {
        todayMeals.reduce(0) { $0 + $1.calories }
    }

    var targetCalories: Double { user.daily_calories ?? 2000 }
    var progress: Double { min(consumedCalories / targetCalories, 1.0) }

    var body: some View {
        DashCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Calorie Balance")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(consumedCalories)) / \(Int(targetCalories)) kcal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: progress > 0.9 ? [.orange, .red] : [.teal, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 12)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 12)

                // Macros row
                HStack {
                    MacroChip(label: "Protein", value: Int(todayMeals.reduce(0) { $0 + $1.protein }), unit: "g", color: .blue)
                    Spacer()
                    MacroChip(label: "Carbs", value: Int(todayMeals.reduce(0) { $0 + $1.carbs }), unit: "g", color: .orange)
                    Spacer()
                    MacroChip(label: "Fat", value: Int(todayMeals.reduce(0) { $0 + $1.fat }), unit: "g", color: .yellow)
                }
            }
        }
    }
}

struct MacroChip: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(unit)")
                .font(.subheadline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Weight Chart Card

struct WeightChartCard: View {
    let weightHistory: [WeightHistory]
    let targetWeight: Double?

    var chartData: [WeightHistory] {
        Array(weightHistory.prefix(14).reversed())
    }

    var body: some View {
        DashCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weight Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if let target = targetWeight {
                        Text("Target: \(String(format: "%.1f", target)) kg")
                            .font(.caption)
                            .foregroundColor(.teal)
                    }
                }

                if chartData.isEmpty {
                    Text("No weight data yet")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                } else {
                    Chart {
                        ForEach(chartData) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            .foregroundStyle(Color.teal)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            .foregroundStyle(Color.teal.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                        }

                        if let target = targetWeight {
                            RuleMark(y: .value("Target", target))
                                .foregroundStyle(Color.purple.opacity(0.7))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text("\(Int(d))")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                }
            }
        }
    }
}

// MARK: - Today Meals Card

struct TodayMealsCard: View {
    let meals: [MealPlan]

    var body: some View {
        DashCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Meals")
                    .font(.headline)
                    .foregroundColor(.white)

                if meals.isEmpty {
                    Text("No meal plan for today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(meals.prefix(3)) { meal in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(mealColor(meal.meal_type).opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(mealEmoji(meal.meal_type))
                                        .font(.body)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(meal.mealTypeFormatted)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Text("\(Int(meal.calories)) kcal")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }

    func mealEmoji(_ type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "🌅"
        case "lunch": return "🥗"
        case "dinner": return "🍽️"
        default: return "🍎"
        }
    }

    func mealColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .green
        case "dinner": return .blue
        default: return .purple
        }
    }
}

// MARK: - Today Workout Card

struct TodayWorkoutCard: View {
    let workout: WorkoutPlan

    var body: some View {
        NavigationLink(destination: WorkoutsView()) {
            DashCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today's Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }

                    if workout.is_rest_day == true {
                        HStack {
                            Image(systemName: "zzz")
                                .foregroundColor(.blue)
                            Text("Rest Day — Recovery time!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        HStack(spacing: 16) {
                            StatPill(icon: "clock", value: "\(workout.duration_minutes ?? 45)m", color: .teal)
                            StatPill(icon: "flame", value: "\(workout.estimated_calories ?? 300) kcal", color: .orange)
                            StatPill(icon: "dumbbell", value: "\(workout.exercises.count) exercises", color: .purple)
                        }

                        ForEach(workout.exercises.prefix(2)) { ex in
                            HStack {
                                Circle()
                                    .fill(Color.teal.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(ex.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(ex.sets)×\(ex.reps)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.15)))
    }
}

// MARK: - Weight Logger Sheet

struct WeightLoggerSheet: View {
    let onSave: (Double) async -> Void
    @State private var weightText = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D1F").ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Log Your Weight")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))

                    Button {
                        guard let w = Double(weightText) else { return }
                        isLoading = true
                        Task {
                            await onSave(w)
                            isLoading = false
                        }
                    } label: {
                        Text(isLoading ? "Saving..." : "Save")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(weightText.isEmpty || isLoading)

                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Shared Card wrapper

struct DashCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}
