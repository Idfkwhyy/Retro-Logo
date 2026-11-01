import AppKit
import SwiftUI

class MenuBarController {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var settings: OverlaySettings
    
    init(settings: OverlaySettings) {
        self.settings = settings
        createMenuBarIcon()
    }
    
    func createMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Observe settings changes to update icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: NSNotification.Name("OverlaySettingsChanged"),
            object: nil
        )
    }
    
    @objc func settingsDidChange() {
        updateMenuBarIcon()
    }
    
    func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        if settings.isEnabled {
            button.image = NSImage(named: "iconEnabled")
        } else {
            button.image = NSImage(named: "iconDisabled")
        }
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        // Both left and right click now show popover
        if let popover = popover, popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: NSStatusBarButton) {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 600)
        popover.behavior = .transient
        
        let hostingController = NSHostingController(
            rootView: PopoverContentView(menuBarController: self)
                .environmentObject(settings)
        )
        
        popover.contentViewController = hostingController
        
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        
        // Activate the app and focus the popover
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        
        // Adjust popover size to fit content after it's shown
        DispatchQueue.main.async {
            let contentView = hostingController.view
            let fittingSize = contentView.fittingSize
            popover.contentSize = NSSize(width: 380, height: fittingSize.height)
        }
        
        self.popover = popover
    }
    
    func showMenu(relativeTo view: NSView) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        menu.addItem(launchItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set target for menu items
        for item in menu.items {
            if item.target == nil {
                item.target = self
            }
        }
        
        // Get mouse location in the view's coordinate system
        if let window = view.window {
            let mouseLocationInWindow = window.mouseLocationOutsideOfEventStream
            let mouseLocationInView = view.convert(mouseLocationInWindow, from: nil)
            
            // Position menu below and to the left of the cursor
            let location = NSPoint(x: mouseLocationInView.x - 12, y: mouseLocationInView.y + 22)
            menu.popUp(positioning: nil, at: location, in: view)
        }
    }
    
    @objc func toggleLaunchAtLogin() {
        // Always show manual instructions
        showManualLaunchAtLoginInstructions()
    }
    
    private func showManualLaunchAtLoginInstructions() {
        let alert = NSAlert()
        alert.messageText = "Launch at Login"
        alert.informativeText = "To keep the app free of dependencies (and because I'm lazy), Launch at Login must be enabled manually:\n\n1. Open System Preferences/Settings\n2. Go to Users & Groups (or General → Login Items on macOS 13+)\n3. Click on your username\n4. Select 'Login Items'\n5. Click the '+' button and add Poof!\n\nWould you like to open Login Items now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Login Items")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open Login Items in System Preferences/Settings
            if #available(macOS 13.0, *) {
                // macOS 13+ uses new Settings URL
                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            } else {
                // macOS 12 and earlier
                let script = """
                tell application "System Preferences"
                    activate
                    set current pane to pane "com.apple.preferences.users"
                    reveal anchor "loginItems" of pane "com.apple.preferences.users"
                end tell
                """
                
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                    
                    if let error = error {
                        print("AppleScript error: \(error)")
                        // Fallback: just open System Preferences
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Preferences.app"))
                    }
                }
            }
        }
    }
    
    @objc func showAbout() {
        let windowWidth: CGFloat = 280
        let windowHeight: CGFloat = 150
        
        let aboutWindow = NSWindow(
            contentRect: NSMakeRect(0, 0, windowWidth, windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.title = ""
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.level = .floating
        aboutWindow.center()
        
        let contentView = NSView(frame: NSMakeRect(0, 0, windowWidth, windowHeight))
        
        let info = Bundle.main.infoDictionary
        
        let appName =
            info?["CFBundleDisplayName"] as? String ??
            info?["CFBundleName"] as? String ??
            "RetroLogo"
        
        let version =
            info?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let build =
            info?["CFBundleVersion"] as? String ?? "1"
        
        let developer =
            info?["DeveloperName"] as? String ?? "Unknown Developer"
        
        let iconSize: CGFloat = 60
        let spacing: CGFloat = 4
        let totalContentHeight = iconSize + 45
        let startY = (windowHeight - totalContentHeight) / 2 + iconSize
        
        let appIcon = NSImageView(
            frame: NSRect(
                x: (windowWidth - iconSize) / 2,
                y: startY,
                width: iconSize,
                height: iconSize
            )
        )
        appIcon.image = NSApp.applicationIconImage
        
        let appNameLabel = NSTextField(labelWithString: appName)
        appNameLabel.frame = NSRect(
            x: 0,
            y: startY - (20 + spacing),
            width: windowWidth,
            height: 20
        )
        appNameLabel.alignment = .center
        appNameLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        let versionLabel = NSTextField(
            labelWithString: "Version \(version) (\(build))"
        )
        versionLabel.frame = NSRect(
            x: 0,
            y: startY - (40 + 2 * spacing),
            width: windowWidth,
            height: 20
        )
        versionLabel.alignment = .center
        versionLabel.font = NSFont.systemFont(ofSize: 10)
        
        let authorLabel = NSTextField(
            labelWithString: "by \(developer)"
        )
        authorLabel.frame = NSRect(
            x: 0,
            y: startY - (65 + 3 * spacing),
            width: windowWidth,
            height: 20
        )
        authorLabel.alignment = .center
        authorLabel.font = NSFont.systemFont(ofSize: 10)
        authorLabel.textColor = .secondaryLabelColor
        
        contentView.addSubview(appIcon)
        contentView.addSubview(appNameLabel)
        contentView.addSubview(versionLabel)
        contentView.addSubview(authorLabel)
        
        aboutWindow.contentView = contentView
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
