import SwiftUI

struct AuthView: View {
    let onAuth: (String, String, String?) async -> Void

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0A0A1A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(LinearGradient(colors: [.teal, .purple], startPoint: .top, endPoint: .bottom))
                        Text("MyWellness")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)

                    // Toggle
                    HStack(spacing: 0) {
                        TabButton(title: "Login", isSelected: isLogin) { isLogin = true }
                        TabButton(title: "Register", isSelected: !isLogin) { isLogin = false }
                    }
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Form
                    VStack(spacing: 16) {
                        if !isLogin {
                            AuthTextField(placeholder: "Full name", text: $name, icon: "person")
                        }
                        AuthTextField(placeholder: "Email", text: $email, icon: "envelope")
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        AuthTextField(placeholder: "Password", text: $password, icon: "lock", isSecure: true)
                    }

                    // Button
                    Button {
                        submit()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isLogin ? "Login" : "Create Account")
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.teal, Color(hex: "7C3AED")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoading || !isFormValid)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && (isLogin || !name.isEmpty)
    }

    func submit() {
        isLoading = true
        Task {
            await onAuth(email, password, isLogin ? nil : name)
            isLoading = false
        }
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15)))
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected ? RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.3)) : nil
                )
        }
        .padding(4)
    }
}
