import SwiftUI

struct ReceiptCardView: View {
    let receipt: Receipt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(receipt.storeName)
                .font(.headline)
            Text(receipt.date, style: .date)
                .font(.subheadline)
            Text("Total: $\(String(format: "%.2f", receipt.total))")
                .font(.subheadline)
            if !receipt.items.isEmpty {
                Text("Items:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                ForEach(receipt.items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
} 