import SwiftUI

struct DetailedReceiptView: View {
    let receipt: Receipt
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showFullImage = false
    @State private var showDeleteConfirmation = false
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var receiptImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt Image Section
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                    
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .onTapGesture {
                                showFullImage = true
                            }
                    } else if isLoadingImage {
                        ProgressView()
                    } else {
                        Image(systemName: "doc.text")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                
                // Receipt Details
                VStack(alignment: .leading, spacing: 16) {
                    // Store Name
                    Text(receipt.storeName)
                        .font(.system(size: 24, weight: .bold))
                    
                    // Date
                    HStack {
                        Text("Date")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(receipt.date.formatted(date: .long, time: .shortened))
                    }
                    
                    // Total
                    HStack {
                        Text("Total")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(receipt.currency)\(String(format: "%.2f", receipt.total))")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    // Purchased Items
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Purchased Items")
                            .foregroundColor(.gray)
                            .padding(.bottom, 4)
                        
                        ForEach(receipt.items, id: \.self) { item in
                            Text(item)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                
                // Added Delete Button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Receipt")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Receipt")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        
        // Added confirmation dialog
        .confirmationDialog(
            "Delete Receipt",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await firebaseService.deleteReceipt(receipt.id)
                        onDelete()
                        dismiss()
                    } catch {
                        print("Error deleting receipt: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        
        .onAppear {
            loadReceiptImage()
        }
        .sheet(isPresented: $showFullImage) {
            if let image = receiptImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showFullImage = false
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func loadReceiptImage() {
        guard let imageURLString = receipt.imageURL,
              let imageURL = URL(string: imageURLString) else {
            print("Debug: No image URL available")
            return
        }
        
        isLoadingImage = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.receiptImage = image
                        self.isLoadingImage = false
                    }
                }
            } catch {
                print("Error loading image: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }
}