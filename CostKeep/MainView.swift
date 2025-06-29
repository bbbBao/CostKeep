import SwiftUI

struct MainView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedDate = Date()
    @State private var receipts: [Receipt] = []
    @State private var showImagePicker = false
    @State private var showProfile = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showFullCalendar = false
    @State private var showImageSourcePicker = false
    @State private var selectedImageSource: UIImagePickerController.SourceType = .camera
    @State private var showUploadError = false
    @State private var uploadErrorMessage = ""
    @State private var uploadErrorLogs = ""
    @State private var showGreeting = true
    
    private var selectedDateTotal: Double {
        receipts
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.total }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var headerText: String {
        if showGreeting {
            return greeting
        }

        let totalString = String(format: "¥%.2f", selectedDateTotal)
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today's Total: \(totalString)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            // let dateString = dateFormatter.string(from: selectedDate)
            return "Total for This Day: \(totalString)"
        }
    }
    
    var sortedReceipts: [Receipt] {
        receipts.sorted { $0.date > $1.date }
    }
    
    private var datesWithReceipts: Set<Date> {
        Set(receipts.map { Calendar.current.startOfDay(for: $0.date) })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(
                    greeting: headerText,
                    user: authService.currentUser,
                    showUserName: showGreeting
                )
                
                DateHeaderView(
                    selectedDate: $selectedDate,
                    showFullCalendar: $showFullCalendar,
                    loadReceiptsForDate: loadReceiptsForDate
                )
                
                CalendarView(selectedDate: $selectedDate, datesWithReceipts: datesWithReceipts)
                    .padding(.vertical)
                
                ReceiptsListView(
                    receipts: sortedReceipts,
                    selectedDate: selectedDate,
                    onReceiptDeleted: {
                        loadReceiptsForDate(selectedDate)
                    }
                )
                
                CustomTabBar(
                    showImageSourcePicker: { showImageSourcePicker = true },
                    showProfile: { showProfile = true }
                )
            }
            .overlay(overlayView)
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourcePicker) {
            Button("Camera") {
                selectedImageSource = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                selectedImageSource = .photoLibrary
                showImagePicker = true
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                image: $selectedImage,
                sourceType: selectedImageSource
            )
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView()
        }
        .sheet(isPresented: $showUploadError) {
            ReceiptUploadErrorView(
                errorMessage: uploadErrorMessage,
                errorLogs: uploadErrorLogs,
                isPresented: $showUploadError
            )
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                processSelectedImage(image)
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            loadReceiptsForDate(newDate)
        }
        .onAppear {
            showGreeting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showGreeting = false
                }
            }
            loadReceiptsForDate(selectedDate)
        }
    }
    
    private func processSelectedImage(_ image: UIImage) {
        print("Debug: Starting image processing")
        isProcessing = true
        Task {
            do {
                print("Debug: Calling Firebase service")
                let receipt = try await FirebaseService.shared.processReceiptImage(image)
                print("Debug: Receipt processed successfully")
                try await FirebaseService.shared.saveReceipt(receipt)
                print("Debug: Receipt saved to database")
                
                await MainActor.run {
                    selectedImage = nil
                    isProcessing = false
                    selectedDate = Calendar.current.startOfDay(for: receipt.date)
                    loadReceiptsForDate(selectedDate)
                }
            } catch {
                print("Debug: Error processing image: \(error)")
                await MainActor.run {
                    uploadErrorMessage = "Unable to process receipt image. Please ensure:\n\n• The image contains a valid purchase receipt\n• The receipt image is clear and well-lit\n• All text is clearly visible and readable\n• The receipt is properly aligned in the frame"
                    uploadErrorLogs = """
                    Error Type: \(type(of: error))
                    Error Description: \(error.localizedDescription)
                    Debug Log:
                    - Starting image processing
                    - Error occurred during processing
                    - Full error: \(error)
                    """
                    selectedImage = nil
                    isProcessing = false
                    showUploadError = true
                }
            }
        }
    }
    
    private func loadReceiptsForDate(_ date: Date, loadFullMonth: Bool = false) {
        print("Loading receipts for date: \(date)")
        Task {
            do {
                let calendar = Calendar.current
                let dateRange: (start: Date, end: Date)
                
                if loadFullMonth {
                    // Get the start and end of the month
                    let components = calendar.dateComponents([.year, .month], from: date)
                    guard let firstOfMonth = calendar.date(from: components),
                          let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) else {
                        return
                    }
                    dateRange = (firstOfMonth, lastOfMonth)
                } else {
                    // Get the week range as before
                    let weekday = calendar.component(.weekday, from: date)
                    let weekStart = calendar.date(byAdding: .day, value: 1-weekday, to: date)!
                    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                    dateRange = (weekStart, weekEnd)
                }
                
                let loadedReceipts = try await FirebaseService.shared.fetchReceipts(
                    from: dateRange.start,
                    to: dateRange.end
                )
                
                await MainActor.run {
                    self.receipts = loadedReceipts
                }
            } catch {
                print("Error loading receipts: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private var overlayView: some View {
        ZStack {
            if showFullCalendar {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFullCalendar = false
                        }
                    }
                
                CalendarPopover(
                    selectedDate: $selectedDate, 
                    isPresented: $showFullCalendar,
                    datesWithReceipts: datesWithReceipts
                )
            }
            
            if isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Processing receipt, this may take a few seconds...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
            }
        }
    }
}

struct CameraButtonView: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}







