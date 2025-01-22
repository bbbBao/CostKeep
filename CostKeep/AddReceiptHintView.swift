import SwiftUI

struct AddReceiptHintView: View {
    let message: String
    @Binding var isVisible: Bool
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGray6))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
                    )
                
                // Triangle pointer
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 20, y: 15))
                    path.addLine(to: CGPoint(x: 40, y: 0))
                    path.closeSubpath()
                }
                .fill(Color(uiColor: .systemGray6))
                .frame(width: 40, height: 15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
            }
            .offset(y: offsetY)
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetY = -10
                }
            }
        }
    }
}
