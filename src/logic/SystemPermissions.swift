import Cocoa

// macOS has some privacy restrictions. The user needs to grant certain permissions, app by app, in System Preferences > Security & Privacy
class SystemPermissions {
    static var alert: NSAlert!
    static var appIsAlreadyRunning = false

    static func ensureAccessibilityCheckboxIsChecked() {
        guard #available(OSX 10.9, *) else { return }
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            // there is a delay between the notification and the permission being actually changed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                ensure()
            }
        }
        ensure()
    }

    static func ensure() {
        if AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary) {
            if appIsAlreadyRunning {
                KeyboardEvents.startObserving()
            } else {
                appIsAlreadyRunning = true
                KeyboardEvents.observe()
            }
        } else {
            if appIsAlreadyRunning {
                KeyboardEvents.stopObserving()
            } else {
                CFRunLoopRun()
            }
        }
    }

    static func ensureScreenRecordingCheckboxIsChecked() {
        guard #available(OSX 10.15, *) else { return }
        if SLSRequestScreenCaptureAccess() != 1 {
            debugPrint("Before using this app, you need to give permission in System Preferences > Security & Privacy > Privacy > Screen Recording.",
                "Please authorize and re-launch.",
                "See https://dropshare.zendesk.com/hc/en-us/articles/360033453434-Enabling-Screen-Recording-Permission-on-macOS-Catalina-10-15-",
                separator: "\n")
            App.shared.terminate(self)
        }
    }

//    static func show() {
//        alert = NSAlert()
//        alert.alertStyle = .warning
//        alert.messageText = NSLocalizedString("Accessibility permission required", comment: "")
//        alert.informativeText = NSLocalizedString("AltTab needs Accessibility permission to work.", comment: "")
////        alert.accessoryView = HyperlinkLabel("See tutorial", "https://help.rescuetime.com/article/59-how-do-i-enable-accessibility-permissions-on-mac-osx")
//        alert.addButton(withTitle: NSLocalizedString("Open Accessibility preferences…", comment: ""))
//        alert.addButton(withTitle: String(format: NSLocalizedString("Quit %@", comment: "Menubar option. %@ is AltTab"), App.name))
//        handleAlertInteraction()
//    }

    private static func handleAlertInteraction() {
        let userChoice = alert.runModal()
        if userChoice == NSApplication.ModalResponse.alertFirstButtonReturn {
            // x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            handleAlertInteraction()
        } else if userChoice == NSApplication.ModalResponse.alertSecondButtonReturn {
            App.shared.terminate(nil)
        }
    }
}
