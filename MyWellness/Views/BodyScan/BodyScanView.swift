import SwiftUI

struct BodyScanView: View {
    @StateObject private var vm = BodyScanViewModel()
    @EnvironmentObject var store: StoreKitService

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Text("Body Scan")
                                .font(.largeTitle.bold())
                                .foregroundStyle(
                                    LinearGradient(colors: [.teal, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                            Text("AI-powered body composition analysis")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 8)

                        // Paywall banner
                        PaywallBanner()
                            .padding(.horizontal, 16)

                        if let scan = vm.latestScan {
                            // Gate body scan content
                            if store.isSubscribed {
                                LatestScanCard(scan: scan)
                                    .padding(.horizontal, 16)
                            } else {
                                LatestScanCard(scan: scan)
                                    .padding(.horizontal, 16)
                                    .paywallGated()
                                    .padding(.horizontal, 16)
                            }

                            // History
                            if vm.scans.count > 1 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Scan History")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)

                                    ForEach(vm.scans.dropFirst()) { scan in
                                        ScanHistoryRow(
                                            scan: scan,
                                            isExpanded: vm.expandedScanId == scan.id,
                                            onTap: { vm.toggleExpanded(scan.id) }
                                        )
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        } else if !vm.isLoading {
                            EmptyBodyScanView()
                                .padding(20)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .refreshable { await vm.load() }

                if vm.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationBarHidden(true)
        }
        .task { await vm.load() }
    }
}

// MARK: - Latest Scan Card

struct LatestScanCard: View {
    let scan: BodyScanResult

    var body: some View {
        VStack(spacing: 20) {
            // Date
            HStack {
                Image(systemName: "calendar").foregroundColor(.teal)
                Text("Latest scan: \(scan.formattedDate)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }

            // Photos row
            HStack(spacing: 10) {
                BodyPhotoSlot(url: scan.front_photo_url, label: "Front")
                BodyPhotoSlot(url: scan.side_photo_url, label: "Side")
                BodyPhotoSlot(url: scan.back_photo_url, label: "Back")
            }

            // Body Composition Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let age = scan.biological_age {
                    MetricTile(icon: "figure.walk", label: "Bio Age", value: "\(age) yrs", color: .green)
                }
                if let soma = scan.somatotype {
                    MetricTile(icon: "person.fill", label: "Somatotype", value: soma, color: .purple)
                }
                if let fat = scan.body_fat_percentage {
                    MetricTile(icon: "drop.fill", label: "Body Fat", value: "\(String(format: "%.1f", fat))%", color: .orange)
                }
                if let muscle = scan.muscle_definition_score {
                    MetricTile(icon: "bolt.fill", label: "Muscle Def.", value: "\(muscle)/10", color: .blue)
                }
            }

            // Tissue analysis
            if scan.skin_texture != nil || scan.skin_tone != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tissue Analysis")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if let texture = scan.skin_texture {
                        TissueRow(label: "Skin Texture", value: texture)
                    }
                    if let tone = scan.skin_tone {
                        TissueRow(label: "Skin Tone", value: tone)
                    }
                    if let swelling = scan.swelling_percentage {
                        TissueRow(label: "Swelling", value: "\(String(format: "%.1f", swelling))%")
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            }

            // Problem / Strong areas
            HStack(alignment: .top, spacing: 12) {
                if let problems = scan.problem_areas, !problems.isEmpty {
                    AreasList(title: "Problem Areas", items: problems, color: .red)
                }
                if let strengths = scan.strong_areas, !strengths.isEmpty {
                    AreasList(title: "Strong Areas", items: strengths, color: .green)
                }
            }

            // Recommendations
            if let diet = scan.recommended_diet_focus, !diet.isEmpty {
                RecommendationCard(title: "Diet Focus", items: diet, icon: "fork.knife", color: .teal)
            }
            if let workout = scan.recommended_workout_focus, !workout.isEmpty {
                RecommendationCard(title: "Workout Focus", items: workout, icon: "dumbbell", color: .purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1)))
        )
    }
}

// MARK: - Supporting components

struct BodyPhotoSlot: View {
    let url: String?
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .frame(height: 120)
                .overlay(
                    Group {
                        if let url, !url.isEmpty {
                            AsyncImage(url: URL(string: url)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.2))
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.2))
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetricTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.subheadline.bold()).foregroundColor(.white)
                Text(label).font(.caption2).foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}

struct TissueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
    }
}

struct AreasList: View {
    let title: String
    let items: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).foregroundColor(color)
            ForEach(items.prefix(4), id: \.self) { item in
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 4, height: 4)
                    Text(item).font(.caption).foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
    }
}

struct RecommendationCard: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.subheadline.bold()).foregroundColor(.white)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(color).frame(width: 4, height: 4).padding(.top, 6)
                    Text(item).font(.caption).foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)))
    }
}

// MARK: - Scan History Row

struct ScanHistoryRow: View {
    let scan: BodyScanResult
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Thumbnail
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Group {
                                if let url = scan.front_photo_url {
                                    AsyncImage(url: URL(string: url)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.fill").foregroundColor(.white.opacity(0.2))
                                    }
                                } else {
                                    Image(systemName: "person.fill").foregroundColor(.white.opacity(0.2))
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(scan.formattedDate)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        if let age = scan.biological_age {
                            Text("Bio age: \(age)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    if let score = scan.improvement_score {
                        let improved = score > 0
                        Label(String(format: "%+.1f", score), systemImage: improved ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(improved ? .green : .red)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(Color.white.opacity(0.1))
                LatestScanCard(scan: scan)
                    .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08)))
        )
    }
}

// MARK: - Empty State

struct EmptyBodyScanView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.rectangle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.teal.opacity(0.6))
            Text("No scans yet")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Complete a body scan to get your AI-powered body composition analysis")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
}
