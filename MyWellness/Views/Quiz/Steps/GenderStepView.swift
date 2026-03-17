import SwiftUI

struct GenderStepView: View {
    @Binding var selection: String?
    let onNext: () -> Void

    var body: some View {
        QuizStepContainer(title: "What's your gender?") {
            VStack(spacing: 12) {
                QuizOptionButton(
                    title: "Male",
                    icon: "♂️",
                    isSelected: selection == "male",
                    action: { selection = "male"; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() } }
                )
                QuizOptionButton(
                    title: "Female",
                    icon: "♀️",
                    isSelected: selection == "female",
                    action: { selection = "female"; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() } }
                )
            }
        }
    }
}
