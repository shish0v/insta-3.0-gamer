import Cocoa

class WindowManager {
    // Структура для представления окна
    struct WindowInfo {
        let windowID: CGWindowID
        let name: String
        let ownerName: String
        let bounds: CGRect
        
        var displayName: String {
            return "\(ownerName): \(name)"
        }
    }
    
    // Кэширование окон
    private static var windowCache: [CGWindowID: WindowInfo] = [:]
    private static let cacheUpdateInterval: TimeInterval = 1.0
    private static var lastCacheUpdate = Date()
    private static var lastWindowUpdate = Date()
    private static let updateInterval: TimeInterval = 0.1
    
    private static func shouldUpdateCache() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastWindowUpdate) >= updateInterval {
            lastWindowUpdate = now
            return true
        }
        return false
    }
    
    static func updateCache() {
        let now = Date()
        if now.timeIntervalSince(lastCacheUpdate) >= cacheUpdateInterval {
            windowCache.removeAll()
            let windows = getActiveWindows()
            windows.forEach { windowCache[$0.windowID] = $0 }
            lastCacheUpdate = now
        }
    }
    
    // Получить список всех активных окон
    static func getActiveWindows() -> [WindowInfo] {
        var windowList = [WindowInfo]()
        
        // Получаем список всех окон
        let windowsListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray?
        
        guard let windows = windowsListInfo else { return windowList }
        
        // Перебираем все окна и формируем список
        for windowInfo in windows {
            guard let info = windowInfo as? NSDictionary else { continue }
            
            if let window = createWindowInfo(from: info) {
                windowList.append(window)
            }
        }
        
        return windowList
    }
    
    private static func createWindowInfo(from info: NSDictionary) -> WindowInfo? {
        guard let ownerName = info[kCGWindowOwnerName as String] as? String,
              ownerName != "Window Server",
              let windowID = info[kCGWindowNumber as String] as? CGWindowID,
              let bounds = info[kCGWindowBounds as String] as? NSDictionary,
              let name = info[kCGWindowName as String] as? String,
              !name.isEmpty else {
            return nil
        }
        
        let rect = CGRect(
            x: bounds["X"] as? CGFloat ?? 0,
            y: bounds["Y"] as? CGFloat ?? 0,
            width: bounds["Width"] as? CGFloat ?? 0,
            height: bounds["Height"] as? CGFloat ?? 0
        )
        
        guard rect.width > 50, rect.height > 50 else {
            return nil
        }
        
        return WindowInfo(
            windowID: windowID,
            name: name,
            ownerName: ownerName,
            bounds: rect
        )
    }
    
    // Проверить, существует ли окно с заданным ID
    static func isWindowAvailable(windowID: CGWindowID) -> Bool {
        updateCache()
        return windowCache[windowID] != nil
    }
    
    // Получить информацию о конкретном окне
    static func getWindowInfo(windowID: CGWindowID) -> WindowInfo? {
        if !shouldUpdateCache() {
            return windowCache[windowID]
        }
        
        updateCache()
        return windowCache[windowID]
    }
}