import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Blue Emoji Tracker"
        
        let mainView = MainView()
        window.contentView = NSHostingView(rootView: mainView)
        
        window.makeKeyAndOrderFront(nil)
        
        Logger.shared.log("Приложение запущено с SwiftUI интерфейсом.")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Config.saveSettings()
        Logger.shared.log("Приложение завершено.")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 