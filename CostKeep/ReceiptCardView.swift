import SwiftUI

struct ReceiptCardView: View {
    let receipt: Receipt
    let isFirst: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(receipt.storeName)
                    .font(.system(size: 24, weight: .bold))
                Text("\(receipt.currency)\(String(format: "%.0f", receipt.total))")
                .font(.system(size: 24, weight: .semibold))
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(isFirst ? .white : .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFirst ? Color.blue : Color(UIColor.systemGray6))
        )
        .foregroundColor(isFirst ? .white : .black)
    }
} 