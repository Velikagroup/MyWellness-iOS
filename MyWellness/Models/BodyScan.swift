import Foundation

struct BodyScanResult: Codable, Identifiable {
    var id: String
    var created_at: String
    var front_photo_url: String?
    var side_photo_url: String?
    var back_photo_url: String?

    // Body composition
    var biological_age: Int?
    var somatotype: String?
    var body_fat_percentage: Double?
    var muscle_definition_score: Int?  // 1-10

    // Tissue analysis
    var skin_texture: String?
    var skin_tone: String?
    var swelling_percentage: Double?

    // Postural & areas
    var postural_assessment: String?
    var problem_areas: [String]?
    var strong_areas: [String]?

    // Recommendations
    var recommended_diet_focus: [String]?
    var recommended_workout_focus: [String]?

    // Comparison
    var improvement_score: Double?

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: created_at) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        return created_at
    }
}
