import SwiftUI

@main
struct MyWellnessApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var storeKit = StoreKitService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(storeKit)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var storeKit: StoreKitService
    @State private var showPaywall = false

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                if authViewModel.hasCompletedQuiz {
                    MainTabView()
                        .sheet(isPresented: $showPaywall) {
                            PostQuizPaywallView()
                                .environmentObject(storeKit)
                        }
                } else {
                    QuizView()
                }
            } else {
                QuizView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            // Show paywall after login if not subscribed
            if isAuth && !storeKit.isSubscribed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPaywall = true
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("MyWellness")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }
        }
    }
}
