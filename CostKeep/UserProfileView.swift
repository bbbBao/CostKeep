import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let email = authService.currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
} 