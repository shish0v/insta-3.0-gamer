import Foundation

class Logger {
    static let shared = Logger()
    
    private var logFile: URL?
    private var isLogEnabled = true
    
    private init() {
        setupLogFile()
    }
    
    private func setupLogFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Ошибка: не удалось получить директорию документов")
            return
        }
        
        let logDirectory = documentsDirectory.appendingPathComponent("BlueEmojiTracker/Logs", isDirectory: true)
        
        // Создаем директорию, если она не существует
        do {
            try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Ошибка при создании директории логов: \(error)")
            return
        }
        
        // Имя файла содержит текущую дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        logFile = logDirectory.appendingPathComponent("log_\(dateString).txt")
    }
    
    func log(_ message: String) {
        guard isLogEnabled else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        
        let logMessage = "[\(timestamp)] \(message)\n"
        print(logMessage, terminator: "")
        
        // Записываем в файл, если доступен
        if let logFile = logFile {
            do {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    let fileHandle = try FileHandle(forWritingTo: logFile)
                    fileHandle.seekToEndOfFile()
                    if let data = logMessage.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                } else {
                    try logMessage.write(to: logFile, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Ошибка при записи лога: \(error)")
            }
        }
    }
    
    func enableLogging(_ enabled: Bool) {
        isLogEnabled = enabled
        log("Логирование \(enabled ? "включено" : "выключено")")
    }
    
    func clearLogs() {
        guard let logFile = logFile else { return }
        
        do {
            try "".write(to: logFile, atomically: true, encoding: .utf8)
            log("Логи очищены")
        } catch {
            print("Ошибка при очистке логов: \(error)")
        }
    }
} 