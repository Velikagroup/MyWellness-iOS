import SwiftUI

struct WorkoutsView: View {
    @StateObject private var vm = WorkoutsViewModel()
    @EnvironmentObject var store: StoreKitService

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Paywall banner
                    PaywallBanner()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Day selector
                    DaySelector(days: vm.days, selectedIndex: $vm.selectedDay)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    ScrollView {
                        if vm.isLoading {
                            ProgressView().tint(.teal).padding(40)
                        } else if vm.isRestDay {
                            RestDayView()
                                .padding(20)
                        } else if let workout = vm.todayWorkout {
                            // Gate workout detail if not subscribed
                            if store.isSubscribed {
                                WorkoutDetailContent(workout: workout, vm: vm)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 30)
                            } else {
                                WorkoutDetailContent(workout: workout, vm: vm)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 30)
                                    .paywallGated()
                                    .padding(.horizontal, 16)
                            }
                        } else {
                            if store.isSubscribed {
                                EmptyWorkoutView { vm.showAssessmentWizard = true }
                                    .padding(20)
                            } else {
                                EmptyWorkoutView { vm.showAssessmentWizard = true }
                                    .padding(20)
                                    .paywallGated()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .refreshable { await vm.load() }
                }

                if vm.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.showAssessmentWizard = true
                    } label: {
                        Image(systemName: "sparkles").foregroundColor(.teal)
                    }
                }
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $vm.showAssessmentWizard) {
            WorkoutAssessmentView { profile in
                // TODO: generate plan from profile
                vm.showAssessmentWizard = false
                await vm.load()
            }
        }
    }
}

// MARK: - Workout Detail Content

struct WorkoutDetailContent: View {
    let workout: WorkoutPlan
    @ObservedObject var vm: WorkoutsViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Summary row
            HStack(spacing: 16) {
                if let duration = workout.duration_minutes {
                    StatPill(icon: "clock", value: "\(duration)m", color: .teal)
                }
                if let cal = workout.estimated_calories {
                    StatPill(icon: "flame.fill", value: "\(cal) kcal", color: .orange)
                }
                if let diff = workout.difficulty {
                    StatPill(icon: "bolt.fill", value: diff.capitalized, color: .purple)
                }
                Spacer()

                if vm.isWorkoutComplete {
                    Label("Complete!", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }

            // Warmup
            if let warmup = workout.warmup, !warmup.isEmpty {
                SectionCard(title: "Warm Up", icon: "flame", color: .orange) {
                    ForEach(warmup) { activity in
                        HStack {
                            Text(activity.name).font(.subheadline).foregroundColor(.white.opacity(0.85))
                            Spacer()
                            if let secs = activity.duration_seconds {
                                Text("\(secs / 60) min").font(.caption).foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }

            // Exercises
            SectionCard(title: "Exercises", icon: "dumbbell.fill", color: .teal) {
                ForEach(workout.exercises) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        completedSets: vm.completedSets[exercise.id] ?? Array(repeating: false, count: exercise.sets),
                        onToggleSet: { setIndex in
                            Task { await vm.toggleSet(exerciseId: exercise.id, setIndex: setIndex, totalSets: exercise.sets) }
                        }
                    )
                }
            }

            // Cooldown
            if let cooldown = workout.cooldown, !cooldown.isEmpty {
                SectionCard(title: "Cool Down", icon: "snowflake", color: .blue) {
                    ForEach(cooldown) { activity in
                        HStack {
                            Text(activity.name).font(.subheadline).foregroundColor(.white.opacity(0.85))
                            Spacer()
                            if let secs = activity.duration_seconds {
                                Text("\(secs / 60) min").font(.caption).foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: Exercise
    let completedSets: [Bool]
    let onToggleSet: (Int) -> Void

    @State private var isExpanded = false

    var allSetsComplete: Bool { !completedSets.isEmpty && completedSets.allSatisfy { $0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline.bold())
                            .foregroundColor(allSetsComplete ? .white.opacity(0.5) : .white)
                            .strikethrough(allSetsComplete)

                        HStack(spacing: 8) {
                            Label("\(exercise.sets) sets", systemImage: "number.square")
                            Label("\(exercise.reps) reps", systemImage: "arrow.counterclockwise")
                            if let rest = exercise.rest_seconds {
                                Label("\(rest)s rest", systemImage: "timer")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .labelStyle(.titleAndIcon)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .buttonStyle(.plain)

            // Set trackers
            HStack(spacing: 8) {
                ForEach(0..<exercise.sets, id: \.self) { i in
                    Button {
                        onToggleSet(i)
                    } label: {
                        let done = i < completedSets.count && completedSets[i]
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(done ? Color.teal.opacity(0.4) : Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(done ? Color.teal : Color.white.opacity(0.15)))
                                .frame(width: 44, height: 36)
                            Text("Set \(i+1)")
                                .font(.caption2.bold())
                                .foregroundColor(done ? .teal : .white.opacity(0.6))
                        }
                    }
                }
            }

            // Expanded: tips
            if isExpanded {
                if let tips = exercise.form_tips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Form Tips")
                            .font(.caption.bold())
                            .foregroundColor(.teal)
                        ForEach(tips.prefix(4), id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Color.teal).frame(width: 4, height: 4).padding(.top, 6)
                                Text(tip).font(.caption).foregroundColor(.white.opacity(0.65))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(allSetsComplete ? Color.teal.opacity(0.08) : Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(allSetsComplete ? Color.teal.opacity(0.3) : Color.white.opacity(0.08)))
        )
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline).foregroundColor(.white)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.08)))
        )
    }
}

// MARK: - Rest Day View

struct RestDayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("💤").font(.system(size: 60))
            Text("Rest Day").font(.title2.bold()).foregroundColor(.white)
            Text("Recovery is just as important as training. Rest, hydrate, and prepare for tomorrow.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
}

// MARK: - Empty Workout View

struct EmptyWorkoutView: View {
    let onSetup: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.teal.opacity(0.6))

            Text("No workout plan yet")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Set up your fitness profile to generate a personalized workout plan")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button(action: onSetup) {
                Label("Set Up Workout Plan", systemImage: "sparkles")
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

// MARK: - Workout Assessment View

struct WorkoutAssessmentView: View {
    let onComplete: (UserFitnessProfile) async -> Void
    @State private var profile = UserFitnessProfile()
    @State private var step = 0
    @Environment(\.dismiss) var dismiss

    let goalOptions = ["Strength", "Hypertrophy", "Weight Loss", "Endurance", "Flexibility", "General Fitness"]
    let locationOptions = [("home", "Home", "No gym needed"), ("gym", "Gym", "Full equipment access"), ("outdoor", "Outdoor", "Parks and running")]
    let experienceOptions = [("beginner", "Beginner", "< 1 year"), ("intermediate", "Intermediate", "1-3 years"), ("advanced", "Advanced", "3+ years")]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D1F").ignoresSafeArea()
                QuizProgressBar(progress: Double(step + 1) / 5.0)
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 80)

                        switch step {
                        case 0:
                            // Goals
                            QuizStepContainer(title: "What are your fitness goals?") {
                                VStack(spacing: 10) {
                                    ForEach(goalOptions, id: \.self) { g in
                                        let selected = profile.fitness_goals?.contains(g) ?? false
                                        QuizOptionButton(title: g, isSelected: selected) {
                                            if profile.fitness_goals == nil { profile.fitness_goals = [] }
                                            if selected { profile.fitness_goals!.removeAll { $0 == g } }
                                            else { profile.fitness_goals!.append(g) }
                                        }
                                    }
                                    QuizNextButton(isEnabled: !(profile.fitness_goals?.isEmpty ?? true)) { step += 1 }
                                }
                            }

                        case 1:
                            // Location
                            QuizStepContainer(title: "Where will you workout?") {
                                VStack(spacing: 10) {
                                    ForEach(locationOptions, id: \.0) { val, title, sub in
                                        QuizOptionButton(title: title, subtitle: sub, isSelected: profile.workout_location == val) {
                                            profile.workout_location = val; step += 1
                                        }
                                    }
                                }
                            }

                        case 2:
                            // Experience
                            QuizStepContainer(title: "What's your experience level?") {
                                VStack(spacing: 10) {
                                    ForEach(experienceOptions, id: \.0) { val, title, sub in
                                        QuizOptionButton(title: title, subtitle: sub, isSelected: profile.experience_level == val) {
                                            profile.experience_level = val; step += 1
                                        }
                                    }
                                }
                            }

                        case 3:
                            // Days/week
                            QuizStepContainer(title: "How many days per week?") {
                                VStack(spacing: 16) {
                                    Text("\(profile.workout_days_per_week ?? 3) days/week")
                                        .font(.title.bold())
                                        .foregroundColor(.teal)
                                    Slider(value: Binding(
                                        get: { Double(profile.workout_days_per_week ?? 3) },
                                        set: { profile.workout_days_per_week = Int($0) }
                                    ), in: 2...6, step: 1).tint(.teal)
                                    QuizNextButton(action: { step += 1 })
                                }
                            }

                        default:
                            // Summary
                            QuizStepContainer(title: "Ready to generate your plan!") {
                                VStack(spacing: 16) {
                                    Text("We'll create a personalized \(profile.workout_days_per_week ?? 3)-day/week workout plan based on your profile.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    QuizNextButton(title: "Generate Plan") {
                                        Task { await onComplete(profile) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fitness Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}
