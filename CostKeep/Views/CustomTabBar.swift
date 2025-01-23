import SwiftUI

struct CustomTabBar: View {
    let showImageSourcePicker: () -> Void
    let showProfile: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "house.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: showImageSourcePicker) {
                CameraButtonView()
            }
            Spacer()
            Button(action: showProfile) {
                Image(systemName: "person")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
} 