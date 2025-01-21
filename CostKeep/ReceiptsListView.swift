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
        VStack {
            if receipts.isEmpty {
                Spacer()
                Text(randomMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                HStack(alignment: .top, spacing: 0) {
                    // Time Column
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Time")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        ForEach(receipts) { receipt in
                            Text(receipt.date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 16))
                                .padding(.vertical, 32)
                        }
                    }
                    .frame(width: 80)
                    
                    // Receipts Column
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Receipts")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                            .padding(.leading)
                        
                        ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                            ReceiptCardView(receipt: receipt, isFirst: index == 0)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
    }
} 