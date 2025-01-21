import SwiftUI

struct ReceiptsListView: View {
    let receipts: [Receipt]
    
    let noReceiptsMessages = [
        "No receipts today - your wallet is taking a break! 💰",
        "Empty like my coffee cup on Monday morning ☕️",
        "Looks like a no-spend day! Your bank account thanks you 🎉",
        "Receipt-free zone! Time to go shopping? 🛍️",
        "As empty as my fridge before grocery day 🌮"
    ]
    
    var randomMessage: String {
        noReceiptsMessages.randomElement() ?? noReceiptsMessages[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Headers - Always at the top
            HStack(spacing: 0) {
                Text("Time")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .frame(width: 80)
                
                Text("Receipts")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(.leading)
                
                Spacer()
            }
            .padding(.vertical, 16)
            
            // Scrollable content area
            ScrollView {
                if receipts.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 100)
                        Text(randomMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                } else {
                    HStack(alignment: .top, spacing: 0) {
                        // Time Column
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(receipts) { receipt in
                                Text(receipt.date.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 16))
                                    .padding(.vertical, 32)
                            }
                        }
                        .frame(width: 80)
                        
                        // Receipts Column
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                                ReceiptCardView(receipt: receipt, isFirst: index == 0)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
} 