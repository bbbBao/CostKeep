import SwiftUI
import FirebaseAuth

struct HeaderView: View {
    let greeting: String
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(greeting),")
                    .font(.system(size: 34, weight: .bold))
                Spacer()
            }
            if let user = user {
                Text(user.email?.components(separatedBy: "@").first ?? "User")
                    .font(.system(size: 34, weight: .bold))
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
} 