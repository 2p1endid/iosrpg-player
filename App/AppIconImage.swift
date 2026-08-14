import SwiftUI
import UIKit

struct AppIconImage: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(named: "AboutIcon") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(size * 0.2)
                    .background(.blue.gradient)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}
