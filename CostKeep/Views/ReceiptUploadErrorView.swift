import SwiftUI

struct ReceiptUploadErrorView: View {
    let errorMessage: String
    let errorLogs: String
    @Binding var isPresented: Bool
    @State private var showLogs = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Question Mark Icon
            Image(systemName: "questionmark.square.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding(.top, 24)
                .opacity(isAnimating ? 0.5 : 1.0)
                .scaleEffect(isAnimating ? 0.95 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            // Error Title
            Text("Opps...")
                .font(.title2)
                .bold()
            
            // Error Message
            Text(errorMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 10) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showLogs = true
                }) {
                    Text("Show Log")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(height: UIScreen.main.bounds.height * 0.75)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showLogs) {
            NavigationView {
                ScrollView {
                    Text(errorLogs)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Error Logs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showLogs = false
                        }
                    }
                }
            }
        }
    }
}
