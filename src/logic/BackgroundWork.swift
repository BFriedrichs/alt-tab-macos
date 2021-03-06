import Foundation

// queues and dedicated threads to observe background events such as keyboard inputs, or accessibility events
class BackgroundWork {
    static let mainQueueConcurrentWorkQueue = DispatchQueue.globalConcurrent("mainQueueConcurrentWorkQueue", .userInteractive)
    static let accessibilityCommandsQueue = DispatchQueue.globalConcurrent("accessibilityCommandsQueue", .userInteractive)
    static let axCallsQueue = DispatchQueue.globalConcurrent("axCallsQueue", .userInteractive)
    static let accessibilityEventsThread = BackgroundThreadWithRunLoop("accessibilityEventsThread")
    static let keyboardEventsThread = BackgroundThreadWithRunLoop("keyboardEventsThread")

    // we cap concurrent tasks to .processorCount to avoid thread explosion on the .global queue
    static let globalSemaphore = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
    // AX calls may block for a long time. We use a big semaphore to avoid blocking the main thread in case the window server is busy
    static let axCallsGlobalSemaphore = DispatchSemaphore(value: 100)

    // swift static variables are lazy; we artificially force the threads to init
    static func start() {
        _ = accessibilityEventsThread
        _ = keyboardEventsThread
    }
}

extension DispatchQueue {
    static func globalConcurrent(_ label: String, _ qos: DispatchQoS) -> DispatchQueue {
        return DispatchQueue(label: label, target: .global(qos: qos.qosClass))
    }

    func asyncWithCap(_ deadline: DispatchTime? = nil, semaphore: DispatchSemaphore = BackgroundWork.globalSemaphore, _ fn: @escaping () -> Void) {
        let block = {
            fn()
            semaphore.signal()
        }
        semaphore.wait()
        if let deadline = deadline {
            asyncAfter(deadline: deadline, execute: block)
        } else {
            async(execute: block)
        }
    }
}

class BackgroundThreadWithRunLoop {
    var thread: Thread?
    var runLoop: CFRunLoop?

    init(_ name: String) {
        thread = Thread {
            self.runLoop = CFRunLoopGetCurrent()
            while !self.thread!.isCancelled {
                CFRunLoopRun()
            }
        }
        thread!.name = name
        thread!.start()
    }
}
