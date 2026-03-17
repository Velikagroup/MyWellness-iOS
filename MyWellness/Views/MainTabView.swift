import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: StoreKitService
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard, meals, workouts, bodyScan, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(Tab.meals)

            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(Tab.workouts)

            BodyScanView()
                .tabItem {
                    Label("Body Scan", systemImage: "person.crop.rectangle.badge.plus")
                }
                .tag(Tab.bodyScan)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.teal)
        .toolbarBackground(Color(hex: "0D0D1F").opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
