import Cocoa

/// Структура для хранения информации об окне
struct WindowInfo {
    let windowID: CGWindowID
    let displayName: String
    let bounds: CGRect
}

/// Класс для работы с окнами системы
class WindowManager {
    /// Получает список всех активных окон на экране
    /// - Returns: Массив информации об окнах
    static func getActiveWindows() -> [WindowInfo] {
        var windowInfoList = [WindowInfo]()
        
        // Получаем информацию обо всех окнах
        let windowsListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
        
        for windowInfo in windowsListInfo {
            guard let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  let windowName = windowInfo[kCGWindowName as String] as? String,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] else {
                continue
            }
            
            // Исключаем окна рабочего стола и меню
            if ownerName == "Dock" || ownerName == "Window Server" {
                continue
            }
            
            // Преобразуем данные о границах окна
            let bounds = CGRect(
                x: boundsDict["X"] as? CGFloat ?? 0,
                y: boundsDict["Y"] as? CGFloat ?? 0,
                width: boundsDict["Width"] as? CGFloat ?? 0,
                height: boundsDict["Height"] as? CGFloat ?? 0
            )
            
            // Формируем название окна
            let displayName = "\(ownerName): \(windowName)".trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Добавляем информацию об окне
            windowInfoList.append(WindowInfo(windowID: windowID, displayName: displayName, bounds: bounds))
        }
        
        return windowInfoList
    }
    
    /// Получает информацию о конкретном окне по его идентификатору
    /// - Parameter windowID: Идентификатор окна
    /// - Returns: Информация об окне или nil, если окно не найдено
    static func getWindowInfoByID(_ windowID: CGWindowID) -> WindowInfo? {
        // Получаем информацию о конкретном окне
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let windowInfo = windowInfoList.first,
              let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
              let windowName = windowInfo[kCGWindowName as String] as? String,
              let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] else {
            return nil
        }
        
        // Преобразуем данные о границах окна
        let bounds = CGRect(
            x: boundsDict["X"] as? CGFloat ?? 0,
            y: boundsDict["Y"] as? CGFloat ?? 0,
            width: boundsDict["Width"] as? CGFloat ?? 0,
            height: boundsDict["Height"] as? CGFloat ?? 0
        )
        
        // Формируем название окна
        let displayName = "\(ownerName): \(windowName)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        return WindowInfo(windowID: windowID, displayName: displayName, bounds: bounds)
    }
} 