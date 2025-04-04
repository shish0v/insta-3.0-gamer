import Cocoa

// Создание и настройка главного контроллера
class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var mainViewController: MainViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаем основное окно
        let windowRect = NSRect(x: 100, y: 100, width: 650, height: 650)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Blue Emoji Tracker \(Config.appVersion)"
        window.center()
        
        // Создаем и настраиваем контроллер
        mainViewController = MainViewController()
        
        // Устанавливаем представление контроллера как содержимое окна
        window.contentView = mainViewController.view
        
        // Отображаем окно
        window.makeKeyAndOrderFront(nil)
        
        // Загружаем настройки из файла
        Config.loadSettings()
        
        // Логируем запуск
        Logger.shared.log("Приложение запущено. Версия: \(Config.appVersion)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Сохраняем настройки при выходе
        Config.saveSettings()
        Logger.shared.log("Приложение завершено")
    }
}

// Запуск приложения
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 