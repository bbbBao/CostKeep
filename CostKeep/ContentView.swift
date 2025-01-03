//
//  ContentView.swift
//  CostKeep
//
//  Created by Tianyi Bao on 12/29/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainView()  // Your existing receipt scanning view
            } else {
                LoginView()
            }
        }
    }
}

struct Receipt: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let total: Double
    let items: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, date, total, items
    }
}

struct ReceiptRow: View {
    let receipt: Receipt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(receipt.date, style: .date)
                .font(.headline)
            Text("Total: $\(String(format: "%.2f", receipt.total))")
                .font(.subheadline)
            if !receipt.items.isEmpty {
                Text("Items:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                ForEach(receipt.items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
