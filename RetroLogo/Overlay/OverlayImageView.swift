import SwiftUI

struct OverlayImageView: View {
    @EnvironmentObject var settings: OverlaySettings
    
    var body: some View {
        Group {
            if let customImage = settings.currentImage {
                Image(nsImage: customImage)
                    .resizable()
                    .frame(width: settings.size, height: settings.size)
            } else {
                Image(settings.selectedIcon)
                    .resizable()
                    .frame(width: settings.size, height: settings.size)
            }
        }
    }
}
