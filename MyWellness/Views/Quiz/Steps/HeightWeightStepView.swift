import SwiftUI

struct HeightWeightStepView: View {
    @Binding var height: Double?
    @Binding var weight: Double?
    let onNext: () -> Void

    @State private var heightText = ""
    @State private var weightText = ""
    @State private var unit: MeasurementUnit = .metric

    enum MeasurementUnit { case metric, imperial }

    var body: some View {
        QuizStepContainer(title: "Your current measurements") {
            VStack(spacing: 20) {
                // Unit toggle
                Picker("Unit", selection: $unit) {
                    Text("Metric (cm/kg)").tag(MeasurementUnit.metric)
                    Text("Imperial (in/lbs)").tag(MeasurementUnit.imperial)
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (\(unit == .metric ? "cm" : "inches"))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    TextField("", text: $heightText)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15)))
                }

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (\(unit == .metric ? "kg" : "lbs"))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    TextField("", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15)))
                }

                QuizNextButton(
                    isEnabled: !heightText.isEmpty && !weightText.isEmpty,
                    action: saveAndNext
                )
            }
        }
    }

    private func saveAndNext() {
        if let h = Double(heightText), let w = Double(weightText) {
            if unit == .imperial {
                height = h * 2.54   // inches to cm
                weight = w * 0.4536 // lbs to kg
            } else {
                height = h
                weight = w
            }
            onNext()
        }
    }
}
