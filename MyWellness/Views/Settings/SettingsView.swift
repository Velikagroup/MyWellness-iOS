import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Tab bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SettingsViewModel.SettingsTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { vm.selectedTab = tab }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: tab.icon)
                                        Text(tab.rawValue)
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(vm.selectedTab == tab ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        vm.selectedTab == tab
                                            ? RoundedRectangle(cornerRadius: 20).fill(Color.teal.opacity(0.35))
                                            : RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // Tab content
                    ScrollView {
                        Group {
                            switch vm.selectedTab {
                            case .account:
                                AccountTab(user: authVM.currentUser, vm: vm, authVM: authVM)
                            case .subscription:
                                SubscriptionTab(user: authVM.currentUser)
                            case .billing:
                                BillingTab(vm: vm)
                            case .notifications:
                                NotificationsTab(user: authVM.currentUser, vm: vm)
                            case .support:
                                SupportTab()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }

                if let msg = vm.successMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.teal.opacity(0.8)))
                            .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Account Tab

struct AccountTab: View {
    let user: User?
    @ObservedObject var vm: SettingsViewModel
    @ObservedObject var authVM: AuthViewModel
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var showLogoutAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.teal, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Text(String(user?.displayName.prefix(1) ?? "?"))
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 8)

            // Fields
            SettingsSection(title: "Personal Info") {
                SettingsField(label: "Full Name", text: $name, placeholder: "Your name")
                SettingsField(label: "Phone", text: $phone, placeholder: "+1 234 567 890")
                    .keyboardType(.phonePad)
            }

            // Save
            Button {
                Task {
                    await vm.updateProfile(updates: ["full_name": name, "phone": phone])
                    await authVM.loadUser()
                }
            } label: {
                Text(vm.isSaving ? "Saving..." : "Save Changes")
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.isSaving)

            Divider().background(Color.white.opacity(0.1))

            // Logout
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.right.square").foregroundColor(.red)
                    Text("Logout").foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
            }
        }
        .onAppear {
            name = user?.full_name ?? ""
            phone = user?.phone ?? ""
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Logout", role: .destructive) { authVM.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Subscription Tab

struct SubscriptionTab: View {
    let user: User?
    @EnvironmentObject var store: StoreKitService
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            // Current plan card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.activeSubscriptionName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                    Spacer()
                    StatusBadge(status: store.isSubscribed ? "active" : "inactive")
                }

                if let renewal = user?.subscription_renewal_date {
                    HStack {
                        Image(systemName: "calendar.badge.clock").foregroundColor(.white.opacity(0.5))
                        Text("Renews \(renewal)").font(.caption).foregroundColor(.white.opacity(0.5))
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.yellow.opacity(0.2)))
            )

            if !store.isSubscribed {
                // Upgrade prompt
                VStack(spacing: 12) {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("AI meal plans, personalized workouts, body scan analysis and more.\n3-day free trial included.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    Button { showPaywall = true } label: {
                        Label("Start Free Trial", systemImage: "crown.fill")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [.teal, Color(hex: "7C3AED")], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task { await store.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            } else {
                // Manage subscription
                Button {
                    // Open App Store subscription management
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape").foregroundColor(.teal)
                        Text("Manage Subscription in App Store")
                            .font(.subheadline)
                            .foregroundColor(.teal)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.teal)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.teal.opacity(0.08)))
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionPaywallView()
                .environmentObject(store)
        }
    }

    var statusText: String {
        store.isSubscribed ? "Active Apple subscription" : "No active subscription"
    }

    var statusColor: Color {
        store.isSubscribed ? .green : .gray
    }
}

struct StatusBadge: View {
    let status: String
    var color: Color {
        switch status {
        case "active": return .green
        case "trialing": return .teal
        case "cancelled": return .red
        default: return .gray
        }
    }
    var body: some View {
        Text(status.capitalized)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

// MARK: - Billing Tab

struct BillingTab: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(spacing: 16) {
            SettingsSection(title: "No transactions yet") {
                Text("Your billing history will appear here")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Notifications Tab

struct NotificationsTab: View {
    let user: User?
    @ObservedObject var vm: SettingsViewModel
    @State private var marketing = false
    @State private var updates = true
    @State private var renewals = true
    @State private var workouts = true

    var body: some View {
        SettingsSection(title: "Notifications") {
            NotifToggle(title: "Marketing emails", subtitle: "Tips, offers and news", isOn: $marketing)
            NotifToggle(title: "Product updates", subtitle: "New features and improvements", isOn: $updates)
            NotifToggle(title: "Renewal reminders", subtitle: "Before your subscription renews", isOn: $renewals)
            NotifToggle(title: "Workout reminders", subtitle: "Daily push notifications", isOn: $workouts)
        }
    }
}

struct NotifToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.5))
            }
        }
        .tint(.teal)
        .padding(.vertical, 4)
    }
}

// MARK: - Support Tab

struct SupportTab: View {
    @State private var category = "General"
    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false

    let categories = ["General", "Technical", "Billing", "Feedback", "Other"]

    var body: some View {
        VStack(spacing: 20) {
            SettingsSection(title: "Submit a ticket") {
                VStack(spacing: 12) {
                    // Category
                    Menu {
                        ForEach(categories, id: \.self) { cat in
                            Button(cat) { category = cat }
                        }
                    } label: {
                        HStack {
                            Text(category).foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.4))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                    }

                    TextField("Subject", text: $subject)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                    TextEditor(text: $message)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        .frame(height: 120)

                    Button {
                        isSending = true
                        // TODO: submit ticket
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isSending = false
                            subject = ""
                            message = ""
                        }
                    } label: {
                        Text(isSending ? "Sending..." : "Send Ticket")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [.teal, .purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSending)
                }
            }
        }
    }
}

// MARK: - Shared Settings components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08)))
            )
        }
    }
}

struct SettingsField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            Divider().background(Color.white.opacity(0.1))
        }
    }
}
