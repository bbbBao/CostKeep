import SwiftUI

struct CalendarPopover: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let datesWithReceipts: Set<Date>
    private let calendar = Calendar.current
    
    // Fixed dimensions
    private let popoverWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let popoverHeight: CGFloat = 420
    private let contentPadding: CGFloat = 16
    
    @State private var showYearPicker = false
    @State private var selectedYear: Int
    @State private var monthYearChanged = false
    
    // Add this computed property
    private var receiptDayStrings: Set<String> {
        Set(datesWithReceipts.map { date in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return "\(components.year!)-\(components.month!)-\(components.day!)"
        })
    }
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, datesWithReceipts: Set<Date>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self.datesWithReceipts = datesWithReceipts
        self._selectedYear = State(initialValue: Calendar.current.component(.year, from: selectedDate.wrappedValue))
    }
    
    private var currentMonth: Int {
        calendar.component(.month, from: selectedDate)
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: selectedDate)
    }
    
    private struct WeekDay: Identifiable {
        let id: Int
        let name: String
    }
    
    private let weekDays: [WeekDay] = [
        WeekDay(id: 0, name: "S"),  // Sunday
        WeekDay(id: 1, name: "M"),
        WeekDay(id: 2, name: "T"),  // Tuesday
        WeekDay(id: 3, name: "W"),
        WeekDay(id: 4, name: "T"),  // Thursday
        WeekDay(id: 5, name: "F"),
        WeekDay(id: 6, name: "S")   // Saturday
    ]
    
    private func hasReceipt(for date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateString = "\(components.year!)-\(components.month!)-\(components.day!)"
        return receiptDayStrings.contains(dateString)
    }
    
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        calendar.component(.month, from: date) == currentMonth &&
        calendar.component(.year, from: date) == currentYear
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showYearPicker {
                yearPickerView
            } else {
                monthView
            }
        }
        .frame(width: popoverWidth, height: popoverHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.top, 150)
    }
    
    private var yearPickerView: some View {
        VStack(spacing: 0) {
            // Year picker header
            HStack {
                Button(action: { showYearPicker = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                Text("Select Year")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Color.clear
                    .frame(width: 44)
            }
            .padding(.vertical, 12)
            
            // Year grid
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    let currentYear = calendar.component(.year, from: Date())
                    ForEach((currentYear - 10)...(currentYear), id: \.self) { year in
                        Button(action: {
                            selectYear(year)
                        }) {
                            Text(String(year))
                                .font(.system(size: 20))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(year == selectedYear ? Color.blue : Color.clear)
                                )
                                .foregroundColor(year == selectedYear ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var monthView: some View {
        VStack(spacing: 0) {
            // Month and Year header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Button(action: { showYearPicker = true }) {
                    Text("\(selectedDate.formatted(.dateTime.month(.wide))) \(String(currentYear))")
                        .font(.system(size: 20, weight: .bold))
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Week day headers
            HStack(spacing: 0) {
                ForEach(weekDays) { day in
                    Text(day.name)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: (popoverWidth - (contentPadding * 4)) / 7)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, contentPadding * 2)
            .padding(.bottom, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed((popoverWidth - (contentPadding * 4)) / 7)), count: 7), spacing: 8) {
                ForEach(0..<42) { index in
                    if let date = getDate(for: index, in: nil) {
                        let isInCurrentMonth = isDateInCurrentMonth(date)
                        let hasReceipt = hasReceipt(for: date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isFutureDate = calendar.isDateInFuture(date)
                        
                        DayCell(
                            date: date,
                            isInCurrentMonth: isInCurrentMonth,
                            hasReceipt: hasReceipt,
                            isSelected: isSelected,
                            isFutureDate: isFutureDate
                        )
                        .onTapGesture {
                            if isInCurrentMonth && !isFutureDate {
                                withAnimation {
                                    selectedDate = date
                                    isPresented = false
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, contentPadding * 2)
            .id("\(currentYear)-\(currentMonth)-\(monthYearChanged)")
        }
    }
    
    private func selectYear(_ year: Int) {
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.year = year
        
        if year == currentYear && dateComponents.month! > currentMonth {
            dateComponents.month = currentMonth
            dateComponents.day = 1
        }
        
        if let newDate = calendar.date(from: dateComponents) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = newDate
                selectedYear = year
                showYearPicker = false
                monthYearChanged.toggle()
            }
        }
    }
    
    private func getDate(for index: Int, in geometry: GeometryProxy?) -> Date? {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
            return nil
        }
        
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = index - (weekday - 1)
        
        return calendar.date(byAdding: .day, value: offset, to: firstOfMonth)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = newDate
                monthYearChanged.toggle()
            }
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            let currentDate = Date()
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentYear = calendar.component(.year, from: currentDate)
            let newMonth = calendar.component(.month, from: newDate)
            let newYear = calendar.component(.year, from: newDate)
            
            if newYear < currentYear || (newYear == currentYear && newMonth <= currentMonth) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = newDate
                    monthYearChanged.toggle()
                }
            }
        }
    }
}

// Helper extension
extension Calendar {
    func isDateInFuture(_ date: Date) -> Bool {
        let currentDate = Date()
        let startOfToday = self.startOfDay(for: currentDate)
        
        // Allow dates within the current month
        let currentMonth = self.component(.month, from: currentDate)
        let currentYear = self.component(.year, from: currentDate)
        let dateMonth = self.component(.month, from: date)
        let dateYear = self.component(.year, from: date)
        
        if dateYear < currentYear || (dateYear == currentYear && dateMonth <= currentMonth) {
            return date > startOfToday
        }
        return true
    }
}

// Add this new DayCell view
private struct DayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let hasReceipt: Bool
    let isSelected: Bool
    let isFutureDate: Bool
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .foregroundColor(
                    isInCurrentMonth ? 
                        (isSelected ? .white : 
                            (isFutureDate ? .gray.opacity(0.3) : .primary)) :
                        .gray.opacity(0.3)
                )
            
            Circle()
                .fill(hasReceipt && isInCurrentMonth ? Color.gray : Color.clear)
                .frame(width: 4, height: 4)
        }
    }
}
