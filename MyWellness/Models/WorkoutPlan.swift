import Foundation

struct WorkoutPlan: Codable, Identifiable {
    var id: String
    var day_of_week: String
    var is_rest_day: Bool?
    var duration_minutes: Int?
    var estimated_calories: Int?
    var difficulty: String?
    var warmup: [WorkoutActivity]?
    var exercises: [Exercise]
    var cooldown: [WorkoutActivity]?
    var notes: String?
}

struct Exercise: Codable, Identifiable {
    var id: String
    var name: String
    var sets: Int
    var reps: String  // e.g. "12" or "12-15"
    var rest_seconds: Int?
    var muscle_groups: [String]?
    var difficulty: String?
    var description: String?
    var form_tips: [String]?
    var equipment: String?
}

struct WorkoutActivity: Codable, Identifiable {
    var id: String { name }
    var name: String
    var duration_seconds: Int?
    var description: String?
}

struct WorkoutLog: Codable, Identifiable {
    var id: String
    var workout_plan_id: String
    var date: String
    var completed_sets: [String: [Bool]]  // exerciseId -> [set1completed, set2completed, ...]
    var is_completed: Bool?
}

struct UserFitnessProfile: Codable {
    var fitness_goals: [String]?
    var performance_oriented: Bool?
    var workout_style: [String]?
    var experience_level: String?
    var strength_level: String?
    var workout_days_per_week: Int?
    var session_duration_minutes: Int?
    var workout_location: String?
    var equipment: [String]?
    var joint_pain: [String]?
}
