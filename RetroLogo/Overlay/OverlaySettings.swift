import SwiftUI
import AppKit

class OverlaySettings: ObservableObject {

    private var isLoading = true

    @Published var selectedIcon: String = "AppleRainbow" {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    @Published var customImages: [String: NSImage] = [:] {
        didSet {
            guard !isLoading else { return }
            notifyChange()
        }
    }

    @Published var selectedCustomImageKey: String? = nil {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    @Published var size: CGFloat = 21 {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    @Published var xPosition: Int = 16 {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    @Published var yPosition: Int = 22 {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    @Published var isEnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            notifyChange()
            saveSettings()
        }
    }

    var isUsingCustomImage: Bool {
        selectedCustomImageKey != nil
    }

    var currentImage: NSImage? {
        if let key = selectedCustomImageKey {
            return customImages[key]
        }
        return nil
    }

    init() {
        loadSettings()
        loadCustomImages()
        isLoading = false
    }

    func notifyChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("OverlaySettingsChanged"),
            object: nil
        )
    }

    private func saveSettings() {
        UserDefaults.standard.set(selectedIcon, forKey: "selectedIcon")
        UserDefaults.standard.set(selectedCustomImageKey, forKey: "selectedCustomImageKey")
        UserDefaults.standard.set(size, forKey: "size")
        UserDefaults.standard.set(xPosition, forKey: "xPosition")
        UserDefaults.standard.set(yPosition, forKey: "yPosition")
        UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
    }

    private func loadSettings() {
        if let icon = UserDefaults.standard.string(forKey: "selectedIcon") {
            selectedIcon = icon
        }

        selectedCustomImageKey = UserDefaults.standard.string(forKey: "selectedCustomImageKey")

        if UserDefaults.standard.object(forKey: "size") != nil {
            let savedSize = UserDefaults.standard.double(forKey: "size")
            if savedSize > 0 {
                size = savedSize
            }
        }

        if UserDefaults.standard.object(forKey: "xPosition") != nil {
            xPosition = UserDefaults.standard.integer(forKey: "xPosition")
        }

        if UserDefaults.standard.object(forKey: "yPosition") != nil {
            yPosition = UserDefaults.standard.integer(forKey: "yPosition")
        }

        if UserDefaults.standard.object(forKey: "isEnabled") != nil {
            isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")
        }
    }

    func saveCustomImages() {
        let imageDirectory = getCustomImagesDirectory()

        try? FileManager.default.removeItem(at: imageDirectory)
        try? FileManager.default.createDirectory(
            at: imageDirectory,
            withIntermediateDirectories: true
        )

        let keys = Array(customImages.keys)
        UserDefaults.standard.set(keys, forKey: "customImageKeys")

        for (key, image) in customImages {
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {

                let fileURL = imageDirectory.appendingPathComponent("\(key).png")
                try? pngData.write(to: fileURL)
            }
        }
    }

    private func loadCustomImages() {
        let imageDirectory = getCustomImagesDirectory()

        guard let keys = UserDefaults.standard.array(forKey: "customImageKeys") as? [String] else {
            return
        }

        var loadedImages: [String: NSImage] = [:]
        for key in keys {
            let fileURL = imageDirectory.appendingPathComponent("\(key).png")
            if let image = NSImage(contentsOf: fileURL) {
                loadedImages[key] = image
            }
        }

        customImages = loadedImages
    }

    private func getCustomImagesDirectory() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        let bundleID = Bundle.main.bundleIdentifier ?? "com.retrologo"
        return appSupport
            .appendingPathComponent(bundleID)
            .appendingPathComponent("CustomImages")
    }
}
