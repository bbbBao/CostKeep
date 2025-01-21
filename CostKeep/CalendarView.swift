import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(calendar.component(.day, from: selectedDate))")
                        .font(.system(size: 34, weight: .bold))
                    Text("\(monthFormatter.string(from: selectedDate))")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedDate = Date()
                    }
                }) {
                    Text("Today")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            
            // Week day headers
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            // Calendar grid
            let days = daysInWeek()
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { date in
                    DayCell(date: date, selectedDate: $selectedDate)
                }
            }
        }
        .padding()
    }
    
    private func daysInWeek() -> [Date] {
        let today = selectedDate
        let calendar = Calendar.current
        
        // Find the start of the week containing the selected date
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        
        return (0...6).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedDate = date
            }
        }) {
            Text("\(calendar.component(.day, from: date))")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
        }
    }
} 