import SwiftUI

struct BirthdateStepView: View {
    @Binding var date: Date?
    let onNext: () -> Void
    @State private var selectedDate = Date(timeIntervalSince1970: 0)

    var body: some View {
        QuizStepContainer(title: "When were you born?", subtitle: "We use this to calculate your metabolic rate") {
            VStack(spacing: 20) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { selectedDate },
                        set: { selectedDate = $0; date = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .colorScheme(.dark)
                .labelsHidden()
                .onChange(of: selectedDate) { date = $0 }

                QuizNextButton(
                    isEnabled: date != nil,
                    action: onNext
                )
            }
        }
        .onAppear {
            if let d = date { selectedDate = d }
            else {
                // Default: 30 years ago
                selectedDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
                date = selectedDate
            }
        }
    }
}
