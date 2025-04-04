import Cocoa

/// Класс для логирования событий приложения
class Logger {
    static let shared = Logger()
    
    private let logFileURL: URL
    private var logFileHandle: FileHandle?
    
    private init() {
        // Получаем путь к папке документов
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = documentsDirectory.appendingPathComponent("BlueEmojiTracker_log.txt")
        
        // Создаем файл, если его нет
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        // Открываем файл для записи
        do {
            logFileHandle = try FileHandle(forWritingTo: logFileURL)
            logFileHandle?.seekToEndOfFile()
            
            // Записываем заголовок при запуске
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let startMessage = "\n\n--- BlueEmojiTracker запущен \(dateFormatter.string(from: Date())) ---\n"
            
            if let data = startMessage.data(using: .utf8) {
                logFileHandle?.write(data)
            }
        } catch {
            print("Ошибка открытия лог-файла: \(error)")
        }
    }
    
    deinit {
        logFileHandle?.closeFile()
    }
    
    /// Записывает сообщение в лог с временной меткой
    /// - Parameter message: Текст сообщения для записи
    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // Выводим в консоль
        print(logMessage)
        
        // Записываем в файл
        if let data = logMessage.data(using: .utf8) {
            logFileHandle?.write(data)
        }
    }
} 