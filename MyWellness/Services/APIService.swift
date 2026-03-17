import Foundation

// MARK: - Base44 API Service
// Mirrors the base44 SDK used in the web app

class APIService {
    static let shared = APIService()

    // TODO: Replace with your actual Base44 app server URL
    // Find it in src/api/base44Client.js -> serverUrl
    private let baseURL = "https://api.base44.app"
    private let appId = "YOUR_APP_ID"  // from base44Client.js

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }

    private init() {}

    // MARK: - Generic Request

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(appId)\(path)") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth

    func me() async throws -> User {
        return try await request(method: "GET", path: "/auth/me")
    }

    func updateMe(_ updates: [String: Any]) async throws -> User {
        return try await request(method: "PUT", path: "/auth/me", body: updates)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let response: AuthResponse = try await request(
            method: "POST",
            path: "/auth/login",
            body: ["email": email, "password": password]
        )
        authToken = response.token
        return response
    }

    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        let response: AuthResponse = try await request(
            method: "POST",
            path: "/auth/register",
            body: ["email": email, "password": password, "full_name": name]
        )
        authToken = response.token
        return response
    }

    func logout() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }

    // MARK: - Entities

    func listWeightHistory() async throws -> [WeightHistory] {
        return try await request(method: "GET", path: "/entities/WeightHistory?sort=-date&limit=30")
    }

    func createWeightEntry(weight: Double, date: String) async throws -> WeightHistory {
        return try await request(
            method: "POST",
            path: "/entities/WeightHistory",
            body: ["weight": weight, "date": date]
        )
    }

    func listMealPlans(dayOfWeek: String? = nil) async throws -> [MealPlan] {
        var path = "/entities/MealPlan"
        if let day = dayOfWeek {
            path += "?day_of_week=\(day)"
        }
        return try await request(method: "GET", path: path)
    }

    func listWorkoutPlans() async throws -> [WorkoutPlan] {
        return try await request(method: "GET", path: "/entities/WorkoutPlan")
    }

    func listBodyScans() async throws -> [BodyScanResult] {
        return try await request(method: "GET", path: "/entities/BodyScanResult?sort=-created_at")
    }

    func createWorkoutLog(_ log: [String: Any]) async throws -> WorkoutLog {
        return try await request(method: "POST", path: "/entities/WorkoutLog", body: log)
    }

    func updateWorkoutLog(id: String, updates: [String: Any]) async throws -> WorkoutLog {
        return try await request(method: "PUT", path: "/entities/WorkoutLog/\(id)", body: updates)
    }

    func listWorkoutLogs(date: String) async throws -> [WorkoutLog] {
        return try await request(method: "GET", path: "/entities/WorkoutLog?date=\(date)")
    }

    // MARK: - Functions (Cloud Functions)

    func invokeFunction(_ name: String, params: [String: Any] = [:]) async throws -> [String: Any] {
        let result: [String: Any] = try await request(
            method: "POST",
            path: "/functions/\(name)",
            body: params
        )
        return result
    }

    // MARK: - Token management

    var isAuthenticated: Bool {
        authToken != nil
    }

    func setToken(_ token: String) {
        authToken = token
    }
}

// MARK: - Supporting Types

struct AuthResponse: Codable {
    var token: String
    var user: User
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let msg): return "Decoding error: \(msg)"
        case .unauthorized: return "Not authorized"
        }
    }
}

// Helper for decoding [String: Any]
extension Dictionary: Decodable where Key == String, Value == Any {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyDecodable].self)
        self = raw.mapValues { $0.value }
    }
}

struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyDecodable].self) { value = array.map(\.value) }
        else if let dict = try? container.decode([String: AnyDecodable].self) { value = dict.mapValues(\.value) }
        else { value = NSNull() }
    }
}
