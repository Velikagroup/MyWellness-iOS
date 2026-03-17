import Foundation
import Combine

@MainActor
class BodyScanViewModel: ObservableObject {
    @Published var scans: [BodyScanResult] = []
    @Published var isLoading = false
    @Published var expandedScanId: String?
    @Published var error: String?

    var latestScan: BodyScanResult? { scans.first }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            scans = try await APIService.shared.listBodyScans()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleExpanded(_ id: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedScanId = expandedScanId == id ? nil : id
        }
    }

    func improvementScore(for scan: BodyScanResult, previousScan: BodyScanResult?) -> Double? {
        guard let prev = previousScan, let current = scan.biological_age, let prevAge = prev.biological_age else {
            return nil
        }
        return Double(prevAge - current)
    }
}
