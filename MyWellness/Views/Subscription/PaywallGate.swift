import SwiftUI

// MARK: - PaywallGate
// Wraps any view or action and blocks access if not subscribed

struct PaywallGate<Content: View>: View {
    @EnvironmentObject var store: StoreKitService
    let content: () -> Content

    @State private var showPaywall = false

    var body: some View {
        Group {
            if store.isSubscribed {
                content()
            } else {
                lockedPlaceholder
            }
        }
        .sheet(isPresented: $showPaywall) {
            PostQuizPaywallView()
                .environmentObject(store)
        }
    }

    var lockedPlaceholder: some View {
        Button { showPaywall = true } label: {
            ZStack {
                content()
                    .blur(radius: 8)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Funzione Premium")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Text("Inizia il tuo trial gratuito\ndi 3 giorni")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            Text("Sblocca ora →")
                                .font(.subheadline.bold())
                                .foregroundColor(.teal)
                        }
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PaywallButton
// Use this to gate any action (e.g. "Generate with AI" button)

struct PaywallButton<Label: View>: View {
    @EnvironmentObject var store: StoreKitService
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var showPaywall = false

    var body: some View {
        Button {
            if store.isSubscribed { action() }
            else { showPaywall = true }
        } label: {
            label()
                .overlay(alignment: .topTrailing) {
                    if !store.isSubscribed {
                        Image(systemName: "lock.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.orange))
                            .offset(x: 4, y: -4)
                    }
                }
        }
        .sheet(isPresented: $showPaywall) {
            PostQuizPaywallView()
                .environmentObject(store)
        }
    }
}

// MARK: - View modifier shorthand
// Usage: .paywallGated()

extension View {
    func paywallGated() -> some View {
        PaywallGate { self }
    }
}

// MARK: - PaywallBanner
// Compact inline banner for non-subscribed users

struct PaywallBanner: View {
    @EnvironmentObject var store: StoreKitService
    @State private var showPaywall = false

    var body: some View {
        if !store.isSubscribed {
            Button { showPaywall = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passa a Premium")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("3 giorni gratis · Cancella quando vuoi")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Text("Prova gratis →")
                        .font(.caption.bold())
                        .foregroundColor(.teal)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.yellow.opacity(0.3))
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) {
                PostQuizPaywallView()
                    .environmentObject(store)
            }
        }
    }
}
