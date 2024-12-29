//
//  ContentView.swift
//  CostKeep
//
//  Created by Tianyi Bao on 12/29/24.
//

import SwiftUI

struct MainView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var scannedReceipts: [Receipt] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
                    VStack {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Text("Scan Receipt")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isProcessing)
                        
                        List(scannedReceipts) { receipt in
                            ReceiptRow(receipt: receipt)
                        }
                        
                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                    .navigationTitle("CostKeep")
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage)
                    }
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            processReceipt(image)
                        }
                    }
                    .alert("Error", isPresented: .constant(errorMessage != nil)) {
                        Button("OK") {
                            errorMessage = nil
                        }
                    } message: {
                        if let error = errorMessage {
                            Text(error)
                        }
                    }
                }
            }
    private func signOut() {
            do {
                try authService.signOut()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    
    private func processReceipt(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let receipt = try await FirebaseService.shared.processReceiptImage(image)
                try await FirebaseService.shared.saveReceipt(receipt)
                await MainActor.run {
                    scannedReceipts.insert(receipt, at: 0)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}


