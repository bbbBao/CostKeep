import SwiftUI

struct DateHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var showFullCalendar: Bool
    let loadReceiptsForDate: (Date, Bool) -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: {
                showFullCalendar.toggle()
                if showFullCalendar {
                    loadReceiptsForDate(selectedDate, true)
                }
            }) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(Calendar.current.component(.day, from: selectedDate))")
                        .font(.system(size: 60, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 4) {
                            Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                                .font(.system(size: 16))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Text(selectedDate.formatted(.dateTime.month().year()))
                            .font(.system(size: 16))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    selectedDate = Date()
                }
            }) {
                Text("Today")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
} 