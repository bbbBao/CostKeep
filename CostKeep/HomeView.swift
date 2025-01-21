import SwiftUI

struct HomeView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedDate = Date()
    @State private var receipts: [Receipt] = []
    @State private var showImagePicker = false
    @State private var showProfile = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(greeting),")
                        .font(.title)
                    if let user = authService.currentUser {
                        Text(user.email?.components(separatedBy: "@").first ?? "User")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Add Calendar View
                CalendarView(selectedDate: $selectedDate)
                    .padding(.bottom)
                
                // Receipts List Header
                HStack {
                    Text("Time")
                        .foregroundColor(.gray)
                    Text("Receipts")
                        .foregroundColor(.gray)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Receipts List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(receipts) { receipt in
                            ReceiptCardView(receipt: receipt)
                        }
                    }
                    .padding()
                }
                
                // Tab Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView()
        }
        .onChange(of: selectedImage) { oldImage, newImage in
            if let image = newImage {
                processSelectedImage(image)
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            loadReceiptsForDate(newValue)
        }
    }
    
    private func processSelectedImage(_ image: UIImage) {
        Task {
            isProcessing = true
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ImageProcessing", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                }
                let receipt = try await FirebaseService.shared.processReceipt(imageData)
                await MainActor.run {
                    selectedImage = nil
                    isProcessing = false
                    // Reload receipts for the current date
                    loadReceiptsForDate(selectedDate)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    selectedImage = nil
                    isProcessing = false
                }
            }
        }
    }
    
    private func loadReceiptsForDate(_ date: Date) {
        Task {
            do {
                let dateStart = Calendar.current.startOfDay(for: date)
                let dateEnd = Calendar.current.date(byAdding: .day, value: 1, to: dateStart)!
                
                let loadedReceipts = try await FirebaseService.shared.fetchReceipts(
                    from: dateStart,
                    to: dateEnd
                )
                
                await MainActor.run {
                    receipts = loadedReceipts.sorted(by: { $0.date > $1.date })
                }
            } catch {
                print("Error loading receipts: \(error)")
            }
        }
    }
} 