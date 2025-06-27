import SwiftUI
import FirebaseAuth

struct HeaderView: View {
    let greeting: String
    let user: User?
    let showUserName: Bool
    @State private var animateGreeting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(showUserName ? "\(greeting)," : greeting)
                    .font(.system(size: 34, weight: .bold))
                Spacer()
            }
            if let user = user, showUserName {
                Text(user.email?.components(separatedBy: "@").first ?? "User")
                    .font(.system(size: 34, weight: .bold))
            }
        }
        .foregroundColor(animateGreeting ? .blue : .primary)
        .scaleEffect(animateGreeting ? 1.02 : 1.0)
        .padding(.horizontal)
        .padding(.top, 20)
        .onAppear {
            if showUserName {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)) {
                    animateGreeting = true
                }
            }
        }
    }
} 