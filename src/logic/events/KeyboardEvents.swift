import Cocoa
import Carbon.HIToolbox.Events

class KeyboardEvents {
    static var eventTap: CFMachPort!
    static var eventTapShouldBeEnabled: Bool!

    static func observe() {
        observe_()
    }

    static func startObserving() {
        eventTapShouldBeEnabled = true
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    static func stopObserving() {
        eventTapShouldBeEnabled = false
        CGEvent.tapEnable(tap: eventTap, enable: false)
    }
}


private func observe_() {
    DispatchQueues.keyboardEvents.async {
        let eventMask = [CGEventType.keyDown, CGEventType.keyUp, CGEventType.flagsChanged].reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })
        // CGEvent.tapCreate returns null if ensureAccessibilityCheckboxIsChecked() didn't pass
        KeyboardEvents.eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: keyboardHandler,
            userInfo: nil)
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, KeyboardEvents.eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CFRunLoopRun()
    }
}

private func keyboardHandler(proxy: CGEventTapProxy, type: CGEventType, cgEvent: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .keyDown || type == .keyUp || type == .flagsChanged {
        if let event_ = NSEvent(cgEvent: cgEvent),
           // workaround: NSEvent.characters is not safe outside of the main thread; this is not documented by Apple
            // see https://github.com/Kentzo/ShortcutRecorder/issues/114#issuecomment-606465340
           let event = NSEvent.keyEvent(with: event_.type, location: event_.locationInWindow, modifierFlags: event_.modifierFlags,
               timestamp: event_.timestamp, windowNumber: event_.windowNumber, context: nil, characters: "",
               charactersIgnoringModifiers: "", isARepeat: type == .flagsChanged ? false : event_.isARepeat, keyCode: event_.keyCode) {
            let appWasBeingUsed = App.app.appIsBeingUsed
            App.shortcutMonitor.handle(event, withTarget: nil)
            if appWasBeingUsed || App.app.appIsBeingUsed {
                return nil // focused app won't receive the event
            }
        }
    } else if (type == .tapDisabledByUserInput || type == .tapDisabledByTimeout) && KeyboardEvents.eventTapShouldBeEnabled {
        KeyboardEvents.startObserving()
    }
//    let event = NSEvent(cgEvent: cgEvent)
//    debugPrint("louis", type == .keyDown, type == .keyUp, type == .flagsChanged, event?.modifierFlags, event?.keyCode)
    return Unmanaged.passRetained(cgEvent) // focused app will receive the event
}
