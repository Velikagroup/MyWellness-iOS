import Foundation

struct QuizData: Codable {
    var gender: String?
    var birthdate: Date?
    var height: Double?
    var current_weight: Double?
    var target_weight: Double?
    var weight_loss_speed: String?
    var current_body_type: String?
    var target_body_type: String?
    var target_zones: [String]?
    var activity_level: String?
    var obstacles: [String]?
    var goals: [String]?
    var diet_type: String?
    var allergies: [String]?
    var referral_code: String?

    // Computed fields
    var age: Int? {
        guard let birthdate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year
    }

    var bmi: Double? {
        guard let w = current_weight, let h = height, h > 0 else { return nil }
        return w / ((h / 100) * (h / 100))
    }

    /// Mifflin-St Jeor formula
    var bmr: Double? {
        guard let w = current_weight, let h = height, let a = age, let g = gender else { return nil }
        if g.lowercased() == "male" {
            return 10 * w + 6.25 * h - 5 * Double(a) + 5
        } else {
            return 10 * w + 6.25 * h - 5 * Double(a) - 161
        }
    }

    var activityMultiplier: Double {
        switch activity_level?.lowercased() {
        case "sedentary": return 1.2
        case "lightly_active": return 1.375
        case "moderately_active": return 1.55
        case "very_active": return 1.725
        case "extra_active": return 1.9
        default: return 1.375
        }
    }

    var dailyCalories: Double? {
        guard let b = bmr else { return nil }
        return b * activityMultiplier
    }
}

enum QuizStep: CaseIterable {
    // Step 1
    case gender
    // Step 2
    case birthdate
    // Step 3
    case heightWeight
    // Step 4
    case targetWeight
    // Step 5 — always (shows calculated weight delta with motivation)
    case weightDifference
    // Step 6 — conditional (only if losing weight)
    case weightLossSpeed
    // Step 7 — conditional (only if losing weight)
    case aiComparison
    // Step 8
    case currentBodyType
    // Step 9
    case targetZone
    // Step 10
    case targetBodyType
    // Step 11
    case obstacles
    // Step 12
    case dietType
    // Step 13
    case goals
    // Step 14 — animated weight potential chart
    case weightPotential
    // Step 15 — trust / privacy screen
    case trust
    // Step 16
    case referralCode
    // Step 17 — "ready to generate" confirmation
    case readyToGenerate
    // Final — calculating animation
    case calculating

    var title: String {
        switch self {
        case .gender:          return "Scegli il tuo genere"
        case .birthdate:       return "Quando sei nato/a?"
        case .heightWeight:    return "Le tue misure attuali"
        case .targetWeight:    return "Qual è il tuo peso ideale?"
        case .weightDifference:return ""
        case .weightLossSpeed: return "Con quale velocità vuoi perdere peso?"
        case .aiComparison:    return ""
        case .currentBodyType: return "Com'è il tuo corpo adesso?"
        case .targetZone:      return "Dove vuoi concentrarti?"
        case .targetBodyType:  return "Come vuoi diventare?"
        case .obstacles:       return "Quali sono i tuoi ostacoli principali?"
        case .dietType:        return "Segui una dieta specifica?"
        case .goals:           return "Quali sono i tuoi obiettivi?"
        case .weightPotential: return "Hai un grande potenziale!"
        case .trust:           return ""
        case .referralCode:    return "Hai un codice referral?"
        case .readyToGenerate: return ""
        case .calculating:     return "Stiamo creando il tuo piano..."
        }
    }

    var progress: Double {
        // Use only the "real" steps for progress (exclude calculating)
        let display: [QuizStep] = [
            .gender, .birthdate, .heightWeight, .targetWeight, .weightDifference,
            .weightLossSpeed, .aiComparison, .currentBodyType, .targetZone,
            .targetBodyType, .obstacles, .dietType, .goals, .weightPotential,
            .trust, .referralCode, .readyToGenerate
        ]
        guard let idx = display.firstIndex(of: self) else { return 1 }
        return Double(idx + 1) / Double(display.count)
    }
}
