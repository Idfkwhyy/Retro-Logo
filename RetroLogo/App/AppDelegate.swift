import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSPanel?
    var settings = OverlaySettings()
    var menuBarController: MenuBarController?
    var fullscreenCheckTimer: Timer?
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("OverlaySettingsChanged"),
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        DispatchQueue.main.async() {
            NSApp.setActivationPolicy(.accessory)
            self.startApplication()
        }
    }

    private func startApplication() {
        menuBarController = MenuBarController(settings: settings)
        createOverlayWindow()

        fullscreenCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateOverlayVisibility()
            self?.keepOverlayOnTop()
        }
        
        // Monitor all mouse events to detect drags
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.keepOverlayOnTop()
        }

        settings.notifyChange()
    }
    
    private func keepOverlayOnTop() {
        guard let panel = overlayWindow, settings.isEnabled else { return }
        if !isAnyAppInFullscreen() {
            panel.orderFrontRegardless()
        }
    }

    func createOverlayWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: settings.size, height: settings.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Use a much higher window level to stay above drag operations
        // CGWindowLevelForKey(.maximumWindow) is above most things including drags
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        
        // Collection behavior to appear on all spaces
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        updateWindowPosition(panel)

        let contentView = NSHostingView(
            rootView: OverlayImageView().environmentObject(settings)
        )
        panel.contentView = contentView

        panel.orderFrontRegardless()
        overlayWindow = panel

        updateOverlayVisibility()
    }

    func updateWindowPosition(_ panel: NSPanel) {
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = CGFloat(settings.xPosition)
            let y = screenFrame.maxY - CGFloat(settings.yPosition)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    @objc func settingsChanged() {
        guard let panel = overlayWindow else { return }

        panel.setContentSize(NSSize(width: settings.size, height: settings.size))
        updateWindowPosition(panel)

        if !isAnyAppInFullscreen() {
            panel.orderFrontRegardless()
        }
    }

    @objc func activeSpaceChanged() {
        // When switching spaces, reposition the overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateOverlayVisibility()
        }
    }

    func isAnyAppInFullscreen() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        for window in windowList {
            if let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
               ownerPID == frontmostApp.processIdentifier,
               let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
               let screen = NSScreen.main,
               let windowLayer = window[kCGWindowLayer as String] as? Int {

                let windowHeight = bounds["Height"] ?? 0
                let windowWidth = bounds["Width"] ?? 0
                let screenHeight = screen.frame.height
                let screenWidth = screen.frame.width

                // Only consider it fullscreen if BOTH dimensions match
                // AND it's at a normal window layer (not drag layer)
                // Window layer 0 is normal windows, higher layers are overlays/drags
                if windowLayer == 0 &&
                   abs(windowHeight - screenHeight) < 5 &&
                   abs(windowWidth - screenWidth) < 5 {
                    return true
                }
            }
        }

        return false
    }

    func updateOverlayVisibility() {
        guard let panel = overlayWindow else { return }

        if !settings.isEnabled {
            panel.orderOut(nil)
            return
        }

        if isAnyAppInFullscreen() {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
