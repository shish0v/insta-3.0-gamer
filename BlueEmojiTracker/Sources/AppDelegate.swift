import Cocoa

// MARK: - Делегат для приложения
class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: NSWindow!
    private var mainViewController: MainViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаем контроллер
        mainViewController = MainViewController()
        
        // Определяем размеры окна
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 500
        
        // Создаем окно в центре экрана
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let windowRect = NSRect(
                x: (screenRect.width - windowWidth) / 2,
                y: (screenRect.height - windowHeight) / 2,
                width: windowWidth,
                height: windowHeight
            )
            
            // Создаем окно с нужными настройками
            mainWindow = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            mainWindow.title = "BlueEmojiTracker"
            mainWindow.contentViewController = mainViewController
            mainWindow.setFrameAutosaveName("MainWindow")
            mainWindow.isReleasedWhenClosed = false
            mainWindow.center()
            mainWindow.makeKeyAndOrderFront(nil)
        }
        
        // Активируем приложение
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Сохраняем настройки при закрытии
        Config.saveSettings()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
} 