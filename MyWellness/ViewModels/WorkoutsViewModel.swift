import Foundation

@MainActor
class WorkoutsViewModel: ObservableObject {
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 2
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var showAssessmentWizard = false
    @Published var completedSets: [String: [Bool]] = [:]  // exerciseId -> [Bool]
    @Published var error: String?

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

    var selectedDayName: String { dayNames[max(0, min(selectedDay, 6))] }

    var todayWorkout: WorkoutPlan? {
        workoutPlans.first { $0.day_of_week.lowercased() == selectedDayName }
    }

    var isRestDay: Bool { todayWorkout?.is_rest_day == true }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            workoutPlans = try await APIService.shared.listWorkoutPlans()
            if workoutPlans.isEmpty {
                showAssessmentWizard = true
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            workoutLogs = try await APIService.shared.listWorkoutLogs(date: formatter.string(from: Date()))
            loadCompletedSets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadCompletedSets() {
        completedSets = [:]
        if let log = workoutLogs.first, let sets = log.completed_sets as? [String: [Bool]] {
            completedSets = sets
        }
    }

    func toggleSet(exerciseId: String, setIndex: Int, totalSets: Int) async {
        if completedSets[exerciseId] == nil {
            completedSets[exerciseId] = Array(repeating: false, count: totalSets)
        }
        completedSets[exerciseId]?[setIndex].toggle()
        await saveLog()
    }

    private func saveLog() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        let logData: [String: Any] = [
            "workout_plan_id": todayWorkout?.id ?? "",
            "date": dateStr,
            "completed_sets": completedSets,
            "is_completed": isWorkoutComplete
        ]

        do {
            if let existing = workoutLogs.first {
                _ = try await APIService.shared.updateWorkoutLog(id: existing.id, updates: logData)
            } else {
                let newLog = try await APIService.shared.createWorkoutLog(logData)
                workoutLogs = [newLog]
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    var isWorkoutComplete: Bool {
        guard let workout = todayWorkout else { return false }
        return workout.exercises.allSatisfy { exercise in
            let sets = completedSets[exercise.id] ?? []
            return !sets.isEmpty && sets.allSatisfy { $0 }
        }
    }
}
