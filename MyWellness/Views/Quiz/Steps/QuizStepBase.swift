import SwiftUI

// MARK: - Shared quiz step layout

struct QuizStepContainer<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                content()
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }
}

struct QuizOptionButton: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let icon {
                    Text(icon).font(.title2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.teal)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.teal.opacity(0.2) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.teal : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct QuizNextButton: View {
    var title = "Continue"
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isEnabled
                                ? LinearGradient(colors: [.teal, Color(hex: "7C3AED")], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        )
                )
        }
        .disabled(!isEnabled)
        .padding(.top, 16)
    }
}
