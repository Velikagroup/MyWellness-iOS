import Foundation
import Combine
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var error: String?

    var isAuthenticated: Bool { currentUser != nil }
    var hasCompletedQuiz: Bool { currentUser?.quiz_completed == true }

    init() {
        Task { await loadUser() }
    }

    func loadUser() async {
        guard APIService.shared.isAuthenticated else {
            isLoading = false
            return
        }
        do {
            currentUser = try await APIService.shared.me()
        } catch {
            currentUser = nil
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            currentUser = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func register(email: String, password: String, name: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await APIService.shared.register(email: email, password: password, name: name)
            currentUser = response.user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        APIService.shared.logout()
        currentUser = nil
    }

    func updateUser(_ updates: [String: Any]) async {
        do {
            currentUser = try await APIService.shared.updateMe(updates)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
