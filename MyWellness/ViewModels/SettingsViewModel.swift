import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .account
    @Published var isSaving = false
    @Published var showDeleteConfirmation = false
    @Published var error: String?
    @Published var successMessage: String?

    enum SettingsTab: String, CaseIterable {
        case account = "Account"
        case subscription = "Subscription"
        case billing = "Billing"
        case notifications = "Notifications"
        case support = "Support"

        var icon: String {
            switch self {
            case .account: return "person.circle"
            case .subscription: return "crown"
            case .billing: return "creditcard"
            case .notifications: return "bell"
            case .support: return "questionmark.circle"
            }
        }
    }

    func updateProfile(updates: [String: Any]) async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await APIService.shared.updateMe(updates)
            successMessage = "Saved successfully"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
