import Foundation

struct User: Codable, Identifiable {
    var id: String
    var email: String
    var full_name: String?
    var phone: String?
    var language: String?
    var gender: String?
    var birthdate: String?
    var height: Double?
    var current_weight: Double?
    var target_weight: Double?
    var body_fat_percentage: Double?
    var bmr: Double?
    var daily_calories: Double?
    var activity_level: String?
    var diet_type: String?
    var allergies: [String]?
    var fitness_goals: [String]?
    var workout_days_per_week: Int?
    var workout_location: String?
    var equipment: [String]?
    var experience_level: String?
    var joint_pain: [String]?
    var subscription_plan: String?
    var subscription_status: String?
    var subscription_renewal_date: String?
    var terms_accepted: Bool?
    var quiz_completed: Bool?
    var onboarding_completed: Bool?

    var displayName: String {
        full_name ?? email.components(separatedBy: "@").first ?? "User"
    }

    var isSubscribed: Bool {
        subscription_status == "active" || subscription_status == "trialing"
    }

    var bmi: Double? {
        guard let w = current_weight, let h = height, h > 0 else { return nil }
        let hMeters = h / 100
        return w / (hMeters * hMeters)
    }
}

struct WeightHistory: Codable, Identifiable {
    var id: String
    var weight: Double
    var date: String
    var notes: String?
}

struct ProgressPhoto: Codable, Identifiable {
    var id: String
    var photo_url: String
    var date: String
    var weight: Double?
    var notes: String?
    var ai_analysis: String?
}
