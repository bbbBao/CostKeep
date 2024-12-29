import FirebaseAuth
import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
} 