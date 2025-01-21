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
    @State private var calendarAnchorPoint: CGPoint = .zero
    
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
                // Header with large date display
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(greeting),")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                    }
                    if let user = authService.currentUser {
                        Text(user.email?.components(separatedBy: "@").first ?? "User")
                            .font(.system(size: 34, weight: .bold))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Date Header
                HStack(alignment: .bottom, spacing: 8) {
                    // Left side with date - tappable for calendar
                    Button(action: {
                        showFullCalendar.toggle()
                    }) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(Calendar.current.component(.day, from: selectedDate))")
                                .font(.system(size: 60, weight: .bold))
                            
                            VStack(alignment: .leading) {
                                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                                    .font(.system(size: 16))
                                Text(selectedDate.formatted(.dateTime.month().year()))
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Separate Today button
                    Button(action: {
                        withAnimation {
                            selectedDate = Date()
                        }
                    }) {
                        Text("Today")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                
                // Week Calendar Strip
                CalendarView(selectedDate: $selectedDate)
                    .padding(.vertical)
                
                // Receipts List Header
                HStack {
                    Text("Time")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    Text("Receipts")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        .padding(.leading)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Receipts List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(receipts) { receipt in
                            ReceiptCardView(receipt: receipt)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
                
                // Custom Tab Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: { showImagePicker = true }) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    Spacer()
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            .overlay {
                if showFullCalendar {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFullCalendar = false
                            }
                        }
                    
                    CalendarPopover(selectedDate: $selectedDate, isPresented: $showFullCalendar)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showFullCalendar)
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
        .onChange(of: selectedDate) { oldDate, newDate in
            print("Date changed from \(oldDate) to \(newDate)")
            loadReceiptsForDate(newDate)
        }
        .onAppear {
            loadReceiptsForDate(selectedDate)
        }
    }
    
    private func processSelectedImage(_ image: UIImage) {
        print("Debug: Starting image processing")
        Task {
            isProcessing = true
            do {
                print("Debug: Calling Firebase service")
                let receipt = try await FirebaseService.shared.processReceiptImage(image)
                print("Debug: Receipt processed successfully")
                try await FirebaseService.shared.saveReceipt(receipt)
                print("Debug: Receipt saved to database")
                
                await MainActor.run {
                    selectedImage = nil
                    isProcessing = false
                    // Reload receipts for the current date
                    loadReceiptsForDate(selectedDate)
                }
            } catch {
                print("Debug: Error processing image: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    selectedImage = nil
                    isProcessing = false
                }
            }
        }
    }
    
    private func loadReceiptsForDate(_ date: Date) {
        print("Loading receipts for date: \(date)")
        Task {
            do {
                let dateStart = Calendar.current.startOfDay(for: date)
                let dateEnd = Calendar.current.date(byAdding: .day, value: 1, to: dateStart)!
                
                let loadedReceipts = try await FirebaseService.shared.fetchReceipts(
                    from: dateStart,
                    to: dateEnd
                )
                
                // For testing: Only add dummy receipts for January 16, 2025
                let targetDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 16))!
                
                var allReceipts = loadedReceipts
                if Calendar.current.isDate(dateStart, inSameDayAs: targetDate) {
                    // Add dummy receipts only for January 16, 2025
                    let dummyReceipt = Receipt(
                        id: "test-123",
                        date: dateStart,
                        total: 85.99,
                        items: ["Groceries ($45.99)", "Electronics ($40.00)"],
                        storeName: "Walmart"
                    )
                    let dummyReceipt1 = Receipt(
                        id: "test-1234",
                        date: dateStart,
                        total: 12.4,
                        items: ["Condoms ($12.99)", "Electronics ($40.00)", "Games ($40.00)", "Meat ($40.00)"],
                        storeName: "Costco"
                    )
                    allReceipts += [dummyReceipt, dummyReceipt1]
                }
                
                // Update the receipts on the main thread
                await MainActor.run {
                    self.receipts = allReceipts
                }
                
                print("Debug: Date Start: \(dateStart)")
                print("Debug: Date End: \(dateEnd)")
                print("Debug: Number of receipts loaded: \(self.receipts.count)")
            } catch {
                print("Error loading receipts: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct CalendarPopover: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                )
                .frame(width: UIScreen.main.bounds.width - 40)
                .frame(maxHeight: 380)
        }
        .padding(.top, 150) // Position from top of screen
        .onChange(of: selectedDate) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        }
    }
}



