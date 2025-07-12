import Foundation
import CoreGraphics
import ApplicationServices
import OpenMultitouchSupport

class ThreeFingers {
    private let manager = OMSManager.shared
    
    // Configuration (matching MiddleClick defaults)
    private let minimumFingers = 3
    private let maxTimeDelta: TimeInterval = 0.3
    
    // Touch tracking state
    private var touchStartTime: Date?
    private var activeTouches: [Int32: OMSTouchData] = [:]
    private var isTouchActive = false
    private var resetTimer: Timer?
    
    // Fallback click detection variables
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var clickTimes: [TimeInterval] = []
    private var clickLocations: [CGPoint] = []
    private let maxTimeBetweenClicks: TimeInterval = 0.15
    private let maxDistanceBetweenClicks: CGFloat = 10.0
    private let requiredClickCount = 3
    
    init() {
        setupSignalHandlers()
        print("🖱️  ThreeFingers initializing with OpenMultitouchSupport...")
    }
    
    func start() {
        print("🚀 Starting ThreeFingers with OpenMultitouchSupport...")
        
        guard checkAccessibilityPermissions() else {
            printPermissionInstructions()
            exit(1)
        }
        
        // Try multitouch first
        let multitouchSuccess = setupMultitouchTracking()
        
        if multitouchSuccess {
            print("✅ ThreeFingers is now running with REAL 3-finger detection!")
            print("📖 Instructions:")
            print("   • Touch trackpad with exactly 3 fingers simultaneously")
            print("   • Lift fingers quickly (within 0.3s) for middle click")
            print("   • This uses OpenMultitouchSupport library")
            print("   • Press Ctrl+C to quit")
        } else {
            print("⚠️  Multitouch setup failed, falling back to click detection")
            
            // Fallback to click detection
            guard setupClickDetection() else {
                print("❌ Failed to setup click detection fallback")
                exit(1)
            }
            
            print("✅ ThreeFingers is running in click detection mode")
            print("📖 Instructions:")
            print("   • Click rapidly 3 times in same spot for middle click")
            print("   • This is a fallback when multitouch isn't available")
            print("   • Press Ctrl+C to quit")
        }
        
        print("")
        
        // Keep running
        RunLoop.current.run()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func printPermissionInstructions() {
        print("❌ Accessibility permissions required!")
        print("")
        print("📋 Steps to enable:")
        print("   1. System Preferences → Security & Privacy → Privacy")
        print("   2. Select 'Accessibility' → Click lock → Enter password")
        print("   3. Add 'threefingers' and enable it")
        print("   4. Restart this app")
        print("")
    }
    
    private func setupMultitouchTracking() -> Bool {
        do {
            // Start listening for touch events
            manager.startListening()
            
            // Set up async touch data processing
            Task { [weak self] in
                guard let self = self else { return }
                
                for await touchDataArray in self.manager.touchDataStream {
                    await MainActor.run {
                        self.handleTouchDataArray(touchDataArray)
                    }
                }
            }
            
            print("✅ Started multitouch tracking")
            return true
            
        } catch {
            print("❌ Failed to start multitouch tracking: \(error)")
            return false
        }
    }
    
    @MainActor
    private func handleTouchDataArray(_ touchDataArray: [OMSTouchData]) {
        // Update active touches based on the current frame
        let currentTouchIds = Set(touchDataArray.map { $0.id })
        
        // Remove touches that are no longer present
        for existingId in activeTouches.keys {
            if !currentTouchIds.contains(existingId) {
                activeTouches.removeValue(forKey: existingId)
            }
        }
        
        // Process each touch in the array
        for touchData in touchDataArray {
            handleTouchData(touchData)
        }
        
        // Check if we have zero fingers (all lifted)
        let currentFingerCount = activeTouches.count
        if currentFingerCount == 0 && isTouchActive {
            handleTouchEnd()
        }
    }
    
    @MainActor
    private func handleTouchData(_ touchData: OMSTouchData) {
        // Update active touches based on touch state
        switch touchData.state {
        case .starting, .making, .touching:
            activeTouches[touchData.id] = touchData
            
        case .breaking, .leaving, .notTouching:
            activeTouches.removeValue(forKey: touchData.id)
            
        case .hovering, .lingering:
            // Don't count hover/linger as active touches
            break
        }
        
        let currentFingerCount = activeTouches.count
        
        // Handle touch state changes
        if currentFingerCount == minimumFingers && !isTouchActive {
            // Exactly 3 fingers down, start tracking
            handleTouchStart()
        } else if currentFingerCount != minimumFingers && isTouchActive && currentFingerCount > 0 {
            // Wrong number of fingers (but not zero), start a timer to reset
            // This gives a brief tolerance for finger lifting variations
            resetTimer?.invalidate()
            resetTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                if let self = self, self.isTouchActive {
                    print("❌ Wrong finger count (\(currentFingerCount)), resetting after delay")
                    self.resetTracking()
                }
            }
        } else if currentFingerCount == minimumFingers && isTouchActive {
            // Back to 3 fingers, cancel any pending reset
            resetTimer?.invalidate()
            resetTimer = nil
        }
    }
    
    private func handleTouchStart() {
        print("▶️  Starting 3-finger touch sequence")
        
        isTouchActive = true
        touchStartTime = Date()
        
        // Print initial positions
        let positions = activeTouches.values.map { 
            "(\(String(format: "%.3f", $0.position.x)), \(String(format: "%.3f", $0.position.y)))" 
        }
        print("📍 Initial positions: \(positions.joined(separator: ", "))")
    }
    
    private func handleTouchEnd() {
        guard isTouchActive else { return }
        guard let startTime = touchStartTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("⏱️  Touch duration: \(String(format: "%.3f", elapsedTime))s")
        
        // Reset state
        resetTracking()
        
        // Check if this qualifies as a middle click
        if elapsedTime <= maxTimeDelta {
            print("🎯 Valid 3-finger tap detected! Generating middle click...")
            generateMiddleClick()
        } else {
            print("❌ Touch too long (\(String(format: "%.3f", elapsedTime))s > \(maxTimeDelta)s)")
        }
    }
    
    private func resetTracking() {
        isTouchActive = false
        touchStartTime = nil
        resetTimer?.invalidate()
        resetTimer = nil
    }
    
    private func generateMiddleClick() {
        // Get current cursor position
        let location = CGEvent(source: nil)?.location ?? CGPoint.zero
        
        print("🖱️  Generating middle click at (\(Int(location.x)), \(Int(location.y)))")
        
        // Create a more reliable middle click using CGEventCreateMouseEvent
        let eventSource = CGEventSource(stateID: .hidSystemState)
        
        guard let mouseDown = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .otherMouseDown,
            mouseCursorPosition: location,
            mouseButton: .center
        ) else {
            print("❌ Failed to create mouse down event")
            return
        }
        
        guard let mouseUp = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .otherMouseUp,
            mouseCursorPosition: location,
            mouseButton: .center
        ) else {
            print("❌ Failed to create mouse up event")
            return
        }
        
        // Set the click count to 1
        mouseDown.setIntegerValueField(.mouseEventClickState, value: 1)
        mouseUp.setIntegerValueField(.mouseEventClickState, value: 1)
        
        // Post events directly to the system
        print("📤 Posting middle click events...")
        
        mouseDown.post(tap: .cghidEventTap)
        
        // Small delay between down and up
        usleep(16_000) // 16ms delay
        
        mouseUp.post(tap: .cghidEventTap)
        
        print("✅ Middle click generated!")
        print("🧪 Test: Move cursor over a link in Safari and try 3-finger tap")
        
        // Simple confirmation without beep
        print("🔔 Middle click event sent!")
    }
    
    // MARK: - Fallback Click Detection
    
    private func setupClickDetection() -> Bool {
        let eventMask = CGEventMask(
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue)
        )
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let threeFingers = Unmanaged<ThreeFingers>.fromOpaque(refcon!).takeUnretainedValue()
                return threeFingers.handleClickEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            return false
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            return false
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        return true
    }
    
    private func handleClickEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .leftMouseDown || type == .rightMouseDown {
            handleClickDown(event: event)
        }
        return Unmanaged.passUnretained(event)
    }
    
    private func handleClickDown(event: CGEvent) {
        let location = event.location
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Clean up old clicks
        cleanupOldClicks(currentTime: currentTime)
        
        // Check if click is in same area
        if isClickInSameArea(location: location) {
            clickTimes.append(currentTime)
            clickLocations.append(location)
            
            print("🖱️  Click \(clickTimes.count) at (\(Int(location.x)), \(Int(location.y)))")
            
            if clickTimes.count >= requiredClickCount {
                let firstClickTime = clickTimes.first!
                let timeDelta = currentTime - firstClickTime
                
                if timeDelta <= maxTimeBetweenClicks * Double(requiredClickCount - 1) {
                    print("🎯 Rapid clicks detected! Generating middle click...")
                    generateMiddleClick()
                    resetClickTracking()
                } else {
                    // Keep only most recent click
                    clickTimes = [currentTime]
                    clickLocations = [location]
                }
            }
        } else {
            // Start fresh
            clickTimes = [currentTime]
            clickLocations = [location]
            print("🖱️  Click 1 at (\(Int(location.x)), \(Int(location.y))) - new sequence")
        }
    }
    
    private func cleanupOldClicks(currentTime: TimeInterval) {
        let cutoffTime = currentTime - (maxTimeBetweenClicks * Double(requiredClickCount))
        while !clickTimes.isEmpty && clickTimes.first! < cutoffTime {
            clickTimes.removeFirst()
            clickLocations.removeFirst()
        }
    }
    
    private func isClickInSameArea(location: CGPoint) -> Bool {
        guard let lastLocation = clickLocations.last else { return true }
        let distance = sqrt(pow(location.x - lastLocation.x, 2) + pow(location.y - lastLocation.y, 2))
        return distance <= maxDistanceBetweenClicks
    }
    
    private func resetClickTracking() {
        clickTimes.removeAll()
        clickLocations.removeAll()
    }
    
    private func setupSignalHandlers() {
        signal(SIGINT) { _ in
            print("\n🛑 Shutting down...")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            print("\n🛑 Terminating...")
            exit(0)
        }
    }
    
    deinit {
        manager.stopListening()
        resetTimer?.invalidate()
    }
}

// MARK: - Main Entry Point
func main() {
    let arguments = CommandLine.arguments
    
    if arguments.count > 1 {
        let command = arguments[1].lowercased()
        
        switch command {
        case "--help", "-h", "help":
            showHelp()
        case "--version", "-v", "version":
            showVersion()
        case "setup":
            runSetup()
        case "daemon", "service", "run":
            // Run as service (for Homebrew services)
            runService()
        default:
            print("❌ Unknown command: \(command)")
            showHelp()
            exit(1)
        }
    } else {
        // No arguments - run the service directly
        runService()
    }
}

func showHelp() {
    print("🖱️  ThreeFingers v1.0.0")
    print("   3-finger tap to middle click for macOS trackpads")
    print("")
    print("Usage:")
    print("  threefingers              - Run the service")
    print("  threefingers setup        - Interactive setup (grants permissions)")
    print("  threefingers daemon       - Run as daemon (for Homebrew services)")
    print("  threefingers --help       - Show this help")
    print("  threefingers --version    - Show version")
    print("")
    print("Homebrew service commands:")
    print("  brew services start threefingers   - Start background service")
    print("  brew services stop threefingers    - Stop background service")
    print("  brew services restart threefingers - Restart service")
    print("")
    print("Note: Requires Accessibility permissions in System Preferences")
}

func showVersion() {
    print("ThreeFingers v1.0.0")
}

func runSetup() {
    print("🚀 ThreeFingers Setup")
    print("==================")
    print("")
    
    // Check current permission status
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
    let hasPermissions = AXIsProcessTrustedWithOptions(options as CFDictionary)
    
    if hasPermissions {
        print("✅ Accessibility permissions are already granted!")
        print("")
        print("🎉 Setup complete! You can now:")
        print("   • Run: threefingers")
        print("   • Or install as service: brew services start threefingers")
        return
    }
    
    print("🔐 Accessibility permissions are required for ThreeFingers to work.")
    print("")
    print("📋 Please follow these steps:")
    print("   1. A macOS dialog should appear asking for permission")
    print("   2. If not, go to: System Settings → Privacy & Security → Accessibility")
    print("   3. Click the '+' button and add 'threefingers'")
    print("   4. Enable the checkbox next to 'threefingers'")
    print("")
    print("⚡ Opening permission dialog...")
    
    // First, trigger the permission dialog - this should show the macOS dialog
    // and automatically add the app to System Settings > Privacy & Security > Accessibility
    let promptOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
    let initialCheck = AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
    
    if initialCheck {
        print("✅ Permissions were already granted!")
        print("")
        print("🎉 Setup complete! ThreeFingers is ready to use.")
        return
    }
    
    // Give the system a moment to show the dialog
    Thread.sleep(forTimeInterval: 1.0)
    
    print("")
    print("📱 If the permission dialog appeared:")
    print("   → Click 'Open System Settings' and enable threefingers")
    print("")
    print("🔧 If no dialog appeared, manually:")
    print("   → Go to: System Settings → Privacy & Security → Accessibility")
    print("   → Click '+' and add the threefingers app")
    print("   → Enable the checkbox")
    print("")
    print("⏳ Waiting for you to grant permissions...")
    print("   (Press Ctrl+C to cancel)")
    
    // Poll for permission changes
    var attempts = 0
    let maxAttempts = 60 // 60 seconds
    
    while attempts < maxAttempts {
        Thread.sleep(forTimeInterval: 1.0)
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        let nowHasPermissions = AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
        
        if nowHasPermissions {
            print("✅ Permissions granted successfully!")
            print("")
            print("🎉 Setup complete! ThreeFingers is ready to use.")
            print("")
            print("🚀 Next steps:")
            print("   • Test it: threefingers")
            print("   • Install as service: brew services start threefingers")
            print("   • View help: threefingers --help")
            print("")
            print("💡 Tip: The service will start automatically on boot once installed.")
            return
        }
        
        attempts += 1
        if attempts % 10 == 0 {
            print("   Still waiting... (\(60 - attempts)s remaining)")
        }
    }
    
    print("⏰ Timed out waiting for permissions.")
    print("")
    print("🔄 If you granted permissions, try running setup again:")
    print("   threefingers setup")
    print("")
    print("❓ If you're having trouble, visit System Settings manually:")
    print("   System Settings → Privacy & Security → Accessibility")
}

func runService() {
    print("🖱️  ThreeFingers v1.0.0")
    print("   Background service for 3-finger middle click")
    print("")

    let threeFingers = ThreeFingers()
    threeFingers.start()
}

// Start the application
main()

/*
 * HOW THIS WORKS NOW:
 * 
 * 1. CLEAN API: Uses OMSManager.shared() and touchDataStream
 * 2. ASYNC HANDLING: Processes touch events asynchronously  
 * 3. STATE TRACKING: Tracks individual touch states (starting, touching, breaking, etc.)
 * 4. FINGER COUNTING: Counts active touches to detect 3-finger gestures
 * 
 * This should work much more reliably with the proper OpenMultitouchSupport API!
 */