import SwiftUI
import AppKit

// Utility struct for animation related functions
struct AnimationUtils {
    static func wiggleAnimation(interval: TimeInterval, variance: Double) -> Animation {
        return Animation.easeInOut(duration: randomize(interval: interval, withVariance: variance)).repeatForever(autoreverses: true)
    }
    static func randomize(interval: TimeInterval, withVariance variance: Double) -> TimeInterval {
        let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
        return interval + variance * random
    }
}

struct WiggleRotationModifier: ViewModifier {
    @Binding var isWiggling: Bool
    var rotationAmount: Double
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isWiggling ? rotationAmount : 0))
            .animation(isWiggling ? AnimationUtils.wiggleAnimation(interval: 0.14, variance: 0.025) : .default, value: isWiggling)
    }
}

struct WiggleBounceModifier: GeometryEffect {
    var amount: Double
    var bounceAmount: Double
    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let bounce = sin(.pi * 2 * animatableData) * bounceAmount
        let translationEffect = CGAffineTransform(translationX: 0, y: CGFloat(bounce))
        return ProjectionTransform(translationEffect)
    }
}

extension View {
    func wiggling(isWiggling: Binding<Bool>, rotationAmount: Double = 3, bounceAmount: Double = 1) -> some View {
        self
            .modifier(WiggleRotationModifier(isWiggling: isWiggling, rotationAmount: rotationAmount))
            .modifier(WiggleBounceModifier(amount: isWiggling.wrappedValue ? 1 : 0, bounceAmount: bounceAmount))
            .animation(isWiggling.wrappedValue ? AnimationUtils.wiggleAnimation(interval: 0.3, variance: 0.025).repeatForever(autoreverses: true) : .default, value: isWiggling.wrappedValue)
    }
}

struct PopoverContentView: View {
    @EnvironmentObject var settings: OverlaySettings
    @State private var hoveredImageKey: String?
    @State private var hoveredBuiltInIcon: String?
    @State private var hoveredDeleteButton: String?
    @State private var isHoveringPlus = false
    @State private var isHoveringSettings = false
    @State private var isJiggleMode = false
    @State private var longPressTimer: Timer?
    
    // State variables for BigSurSlider
    @State private var sizeSliderWidth: Float = 350
    @State private var sizeSliderHeight: Float = 24
    @State private var xSliderWidth: Float = 350
    @State private var xSliderHeight: Float = 24
    @State private var ySliderWidth: Float = 350
    @State private var ySliderHeight: Float = 24
    
    var menuBarController: MenuBarController?
    
    let builtInIcons = [
        "Apple2001Aqua",
        "Apple2001Blue",
        "Apple2001DarkBlue",
        "Apple2001Green",
        "Apple2001Orange",
        "Apple2001Purple",
        "Apple2001Red",
        "Apple2001Silver",
        "Apple2001Yellow",
        "AppleCarbonNeutral",
        "AppleRainbow",
        "AppleRed"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Enable switch at the top
            HStack {
                Text("Enable Retro Logo")
                    .font(.title3)
                Spacer()
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Divider()
            
            // Scrollable icon grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    // Built-in icons (now with jiggle animation)
                    ForEach(builtInIcons, id: \.self) { icon in
                        Button(action: {
                            if !isJiggleMode {
                                settings.selectedIcon = icon
                                settings.selectedCustomImageKey = nil
                            }
                        }) {
                            Image(icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                                .frame(width: 48, height: 48)
                                .wiggling(isWiggling: $isJiggleMode, rotationAmount: 2, bounceAmount: 0.5)
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            hoveredBuiltInIcon = isHovering ? icon : nil
                        }
                    }
                    
                    // Custom images with hover delete
                    ForEach(Array(settings.customImages.keys.sorted()), id: \.self) { key in
                        if let image = settings.customImages[key] {
                            Button(action: {
                                if !isJiggleMode {
                                    settings.selectedCustomImageKey = key
                                }
                            }) {
                                ZStack(alignment: .topLeading) {
                                    Image(nsImage: image)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .frame(width: 48, height: 48)
                                        .wiggling(isWiggling: $isJiggleMode, rotationAmount: 2, bounceAmount: 0.5)
                                    
                                    // Delete button visible in jiggle mode
                                    if isJiggleMode {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                settings.customImages.removeValue(forKey: key)
                                                if settings.selectedCustomImageKey == key {
                                                    settings.selectedCustomImageKey = nil
                                                }
                                                settings.saveCustomImages()
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.secondary)
                                                    .frame(width: 16, height: 16)
                                                
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                    .shadow(color: .black, radius: 2, x: 0, y: 0)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .offset(x: 3, y: 3)
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 1.0)
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isJiggleMode = true
                                        }
                                    }
                            )
                        }
                    }
                    
                    // Add custom image button
                    Button(action: {
                        if !isJiggleMode {
                            selectCustomImage()
                        }
                    }) {
                        ZStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                                .opacity(isHoveringPlus ? 0 : 1)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                                .opacity(isHoveringPlus ? 1 : 0)
                        }
                        .frame(width: 48, height: 48)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringPlus)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        isHoveringPlus = isHovering
                    }
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    if isJiggleMode {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isJiggleMode = false
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // Size & Position controls with Big Sur Sliders
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BigSurSlider(
                        percentage: Binding(
                            get: { Float((settings.size - 8) / (64 - 8) * 100) },
                            set: { settings.size = Double($0 / 100 * (64 - 8) + 8) }
                        ),
                        sliderWidth: $sizeSliderWidth,
                        sliderHeight: $sizeSliderHeight,
                        image: .constant("arrow.up.left.and.arrow.down.right")
                    )
                    .frame(height: 24)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("X Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BigSurSlider(
                        percentage: Binding(
                            get: { Float(settings.xPosition) / 50 * 100 },
                            set: { settings.xPosition = Int($0 / 100 * 50) }
                        ),
                        sliderWidth: $xSliderWidth,
                        sliderHeight: $xSliderHeight,
                        image: .constant("arrow.left.and.right")
                    )
                    .frame(height: 24)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Y Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BigSurSlider(
                        percentage: Binding(
                            get: { Float(settings.yPosition) / 50 * 100 },
                            set: { settings.yPosition = Int($0 / 100 * 50) }
                        ),
                        sliderWidth: $ySliderWidth,
                        sliderHeight: $ySliderHeight,
                        image: .constant("arrow.up.and.down")
                    )
                    .frame(height: 24)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Settings button at the bottom right
            HStack {
                Spacer()
                SettingsButtonView(isHovering: $isHoveringSettings, menuBarController: menuBarController)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .padding(.top, -16)
        }
    }
    
    private func selectCustomImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif]
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                let key = UUID().uuidString
                settings.customImages[key] = image
                settings.selectedCustomImageKey = key
                settings.saveCustomImages()
            }
        }
    }
}

struct SettingsButtonView: View {
    @Binding var isHovering: Bool
    var menuBarController: MenuBarController?
    
    var body: some View {
        Button(action: {
            if let controller = menuBarController,
               let contentView = NSApp.keyWindow?.contentView {
                controller.showMenu(relativeTo: contentView)
            }
        }) {
            ZStack {
                Image(systemName: "gear")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .opacity(isHovering ? 0 : 1)
                
                Image(systemName: "gear")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .opacity(isHovering ? 1 : 0)
            }
            .frame(width: 32, height: 32)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
