import SwiftUI
import AppKit
import Carbon

@main
struct TurkishDeasciifierApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - essential for menu bar apps
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create custom tü icon with underlined t
            let attributedTitle = NSMutableAttributedString(string: "tü")
            attributedTitle.addAttribute(.font, value: NSFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: 2))
            attributedTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: 1))
            button.attributedTitle = attributedTitle
            button.action = #selector(togglePopover(_:))
            button.target = self
            
            // Add right-click menu
            let menu = NSMenu()
            menu.addItem(withTitle: "Open Turkish Deasciifier", action: #selector(togglePopover(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "About", action: #selector(showAbout), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Turkish Deasciifier", action: #selector(quit), keyEquivalent: "q")
            
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        
        // Set up global hotkey monitoring for Option+Cmd+T
        eventMonitor = EventMonitor(mask: [.keyDown]) { [weak self] event in
            self?.handleGlobalKeyDown(event)
        }
        eventMonitor?.start()
        
        // Check accessibility permissions
        checkAccessibilityPermissions()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            let event = NSApp.currentEvent!
            
            if event.type == NSEvent.EventType.rightMouseUp {
                // Show context menu on right click
                let menu = NSMenu()
                menu.addItem(withTitle: "Open Turkish Deasciifier", action: #selector(openPopover), keyEquivalent: "")
                menu.addItem(NSMenuItem.separator())
                menu.addItem(withTitle: "About", action: #selector(showAbout), keyEquivalent: "")
                menu.addItem(NSMenuItem.separator())
                menu.addItem(withTitle: "Quit Turkish Deasciifier", action: #selector(quit), keyEquivalent: "q")
                
                statusItem.menu = menu
                statusItem.button?.performClick(nil)
                statusItem.menu = nil
            } else {
                // Left click - toggle popover
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
    
    @objc func openPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Turkish Deasciifier"
        alert.informativeText = "Version 1.0\n\nA menu bar app to convert ASCII Turkish text to proper Turkish characters.\n\nGlobal Hotkey: ⌥⌘T\n\nDeveloped with Claude Code"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func handleGlobalKeyDown(_ event: NSEvent) {
        // Debug: Print key events to help troubleshoot
        if event.keyCode == 17 { // T key
            print("🔍 T key pressed with modifiers: \(event.modifierFlags)")
            print("   Command: \(event.modifierFlags.contains(.command))")
            print("   Option: \(event.modifierFlags.contains(.option))")
            print("   Both: \(event.modifierFlags.contains([.command, .option]))")
        }

        // Check for Option+Cmd+T (key code 17 = 'T' key)
        if event.modifierFlags.contains([.command, .option]) && event.keyCode == 17 {
            print("✅ Hotkey triggered: Option+Cmd+T")
            convertSelectedText()
        }
    }
    
    func convertSelectedText() {
        // Check accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            showAlert(title: "Permission Required", message: "Please grant accessibility permissions to use global hotkey")
            return
        }
        
        // Copy selected text
        let copyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 8, keyDown: true) // C key
        copyEvent?.flags = .maskCommand
        copyEvent?.post(tap: .cghidEventTap)
        
        let copyEventUp = CGEvent(keyboardEventSource: nil, virtualKey: 8, keyDown: false)
        copyEventUp?.flags = .maskCommand
        copyEventUp?.post(tap: .cghidEventTap)
        
        // Wait briefly for clipboard to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.processClipboardText()
        }
    }
    
    func processClipboardText() {
        let pasteboard = NSPasteboard.general
        guard let originalText = pasteboard.string(forType: .string), !originalText.isEmpty else {
            NSSound.beep()
            // Could show alert but usually better to just beep for no selection
            return
        }
        
        // Convert text using our deasciifier
        let deasciifier = TurkishDeasciifier()
        let convertedText = deasciifier.convertToTurkish(originalText)
        
        // Count conversions
        let originalChars = Array(originalText)
        let convertedChars = Array(convertedText)
        var conversionCount = 0
        
        for i in 0..<min(originalChars.count, convertedChars.count) {
            if originalChars[i] != convertedChars[i] {
                conversionCount += 1
            }
        }
        
        if conversionCount > 0 {
            // Replace clipboard content
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(convertedText, forType: .string)
            
            // Paste back
            let pasteEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true) // V key
            pasteEvent?.flags = .maskCommand
            pasteEvent?.post(tap: .cghidEventTap)
            
            let pasteEventUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)
            pasteEventUp?.flags = .maskCommand
            pasteEventUp?.post(tap: .cghidEventTap)
            
            // Simple success feedback - brief status bar update
            updateStatusIcon(success: true, count: conversionCount)
        } else {
            // Text didn't need conversion - subtle feedback
            updateStatusIcon(success: false, count: 0)
        }
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showAlert(title: "Turkish Deasciifier", message: "Please grant accessibility permissions to enable global hotkey (⌥⌘T)")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func updateStatusIcon(success: Bool, count: Int) {
        guard let button = statusItem.button else { return }
        
        // Create the original tü icon with underlined t
        let createOriginalIcon = {
            let attributedTitle = NSMutableAttributedString(string: "tü")
            attributedTitle.addAttribute(.font, value: NSFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: 2))
            attributedTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: 1))
            return attributedTitle
        }
        
        if success {
            // Briefly show success feedback, then revert to original
            button.title = "✓\(count)"
            button.attributedTitle = NSAttributedString()
            button.image = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                button.title = ""
                button.attributedTitle = createOriginalIcon()
                button.image = nil
            }
        } else {
            // Brief visual feedback for no changes
            button.title = "−"
            button.attributedTitle = NSAttributedString()
            button.image = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                button.title = ""
                button.attributedTitle = createOriginalIcon()
                button.image = nil
            }
        }
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handler(event)
        }
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}