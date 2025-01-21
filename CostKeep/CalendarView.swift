import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    
    private var weekDates: [Date] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let weekStart = calendar.date(byAdding: .day, value: 1-weekday, to: selectedDate)!
        
        return (0..<7).map { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)!
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                VStack(spacing: 4) {
                    // Day of week (S, M, T, etc.)
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // Day number
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? 
                                    Color.blue : Color.clear)
                        )
                        .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? 
                            .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut, value: selectedDate)
    }
}