import Foundation

struct MealPlan: Codable, Identifiable {
    var id: String
    var day_of_week: String // monday, tuesday, ...
    var meal_type: String   // breakfast, snack, lunch, dinner
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var ingredients: [Ingredient]?
    var instructions: String?
    var image_url: String?
    var is_cheat_meal: Bool?

    var dayIndex: Int {
        let days = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
        return days.firstIndex(of: day_of_week.lowercased()) ?? 0
    }

    var mealTypeFormatted: String {
        switch meal_type.lowercased() {
        case "breakfast": return "Breakfast"
        case "snack": return "Snack"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        default: return meal_type.capitalized
        }
    }
}

struct Ingredient: Codable, Identifiable {
    var id: String { name }
    var name: String
    var quantity: String?
    var unit: String?
    var calories: Double?
}

struct MealLog: Codable, Identifiable {
    var id: String
    var meal_plan_id: String
    var date: String
    var calories_consumed: Double?
    var notes: String?
}

struct ShoppingListItem: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: String?
    var unit: String?
    var category: String?
    var is_checked: Bool = false
}

struct UserIngredient: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: String?
}
