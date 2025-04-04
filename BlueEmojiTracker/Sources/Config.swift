import Cocoa

/// Класс для хранения и управления настройками приложения
class Config {
    // Константы
    static let userDefaultsKey = "BlueEmojiTrackerSettings"
    
    // Настройки области захвата
    static var captureRect: CGRect = CGRect(x: 100, y: 100, width: 800, height: 600)
    
    // Настройки для определения синего цвета
    static var blueMinValue: Int = 200
    static var redMaxValue: Int = 100
    static var greenMaxValue: Int = 100
    static var minBluePixels: Int = 5
    
    // Настройки для движения
    static var movementThreshold: CGFloat = 3.0
    static var smoothingFactor: CGFloat = 0.5
    
    // Настройки для режима захвата
    static var useWindowMode: Bool = false
    static var selectedScreen: NSScreen?
    static var selectedWindowID: CGWindowID?
    static var selectedWindowName: String?
    static var currentWindowBounds: CGRect?
    
    // Настройки прогнозирования движения
    static var useMotionPrediction: Bool = true
    
    // Настройки игрового режима
    static var isGameModeEnabled: Bool = false
    static var gameBounds: CGRect = .zero
    
    // Настройки для отладки
    static var showDebugOverlay: Bool = false
    
    /// Загружает настройки из UserDefaults
    static func loadSettings() {
        guard let savedSettings = UserDefaults.standard.dictionary(forKey: userDefaultsKey) else {
            // Устанавливаем настройки по умолчанию
            setDefaultSettings()
            return
        }
        
        // Загружаем настройки из сохраненных данных
        if let captureX = savedSettings["captureX"] as? CGFloat,
           let captureY = savedSettings["captureY"] as? CGFloat,
           let captureWidth = savedSettings["captureWidth"] as? CGFloat,
           let captureHeight = savedSettings["captureHeight"] as? CGFloat {
            captureRect = CGRect(x: captureX, y: captureY, width: captureWidth, height: captureHeight)
        }
        
        blueMinValue = savedSettings["blueMinValue"] as? Int ?? 200
        redMaxValue = savedSettings["redMaxValue"] as? Int ?? 100
        greenMaxValue = savedSettings["greenMaxValue"] as? Int ?? 100
        minBluePixels = savedSettings["minBluePixels"] as? Int ?? 5
        
        movementThreshold = savedSettings["movementThreshold"] as? CGFloat ?? 3.0
        smoothingFactor = savedSettings["smoothingFactor"] as? CGFloat ?? 0.5
        
        useWindowMode = savedSettings["useWindowMode"] as? Bool ?? false
        selectedWindowID = savedSettings["selectedWindowID"] as? CGWindowID
        selectedWindowName = savedSettings["selectedWindowName"] as? String
        
        if let screenIndex = savedSettings["selectedScreenIndex"] as? Int,
           screenIndex >= 0, screenIndex < NSScreen.screens.count {
            selectedScreen = NSScreen.screens[screenIndex]
        } else {
            selectedScreen = NSScreen.main
        }
        
        useMotionPrediction = savedSettings["useMotionPrediction"] as? Bool ?? true
        
        isGameModeEnabled = savedSettings["isGameModeEnabled"] as? Bool ?? false
        
        if let gameBoundsX = savedSettings["gameBoundsX"] as? CGFloat,
           let gameBoundsY = savedSettings["gameBoundsY"] as? CGFloat,
           let gameBoundsWidth = savedSettings["gameBoundsWidth"] as? CGFloat,
           let gameBoundsHeight = savedSettings["gameBoundsHeight"] as? CGFloat {
            gameBounds = CGRect(x: gameBoundsX, y: gameBoundsY, width: gameBoundsWidth, height: gameBoundsHeight)
        }
        
        showDebugOverlay = savedSettings["showDebugOverlay"] as? Bool ?? false
    }
    
    /// Сохраняет текущие настройки в UserDefaults
    static func saveSettings() {
        var settingsDict: [String: Any] = [:]
        
        // Сохраняем настройки области захвата
        settingsDict["captureX"] = captureRect.origin.x
        settingsDict["captureY"] = captureRect.origin.y
        settingsDict["captureWidth"] = captureRect.width
        settingsDict["captureHeight"] = captureRect.height
        
        // Сохраняем настройки определения синего
        settingsDict["blueMinValue"] = blueMinValue
        settingsDict["redMaxValue"] = redMaxValue
        settingsDict["greenMaxValue"] = greenMaxValue
        settingsDict["minBluePixels"] = minBluePixels
        
        // Сохраняем настройки движения
        settingsDict["movementThreshold"] = movementThreshold
        settingsDict["smoothingFactor"] = smoothingFactor
        
        // Сохраняем настройки режима захвата
        settingsDict["useWindowMode"] = useWindowMode
        settingsDict["selectedWindowID"] = selectedWindowID
        settingsDict["selectedWindowName"] = selectedWindowName
        
        // Сохраняем индекс выбранного экрана
        if let screen = selectedScreen {
            let screenIndex = NSScreen.screens.firstIndex(of: screen) ?? 0
            settingsDict["selectedScreenIndex"] = screenIndex
        }
        
        // Сохраняем настройки прогнозирования
        settingsDict["useMotionPrediction"] = useMotionPrediction
        
        // Сохраняем настройки игрового режима
        settingsDict["isGameModeEnabled"] = isGameModeEnabled
        settingsDict["gameBoundsX"] = gameBounds.origin.x
        settingsDict["gameBoundsY"] = gameBounds.origin.y
        settingsDict["gameBoundsWidth"] = gameBounds.width
        settingsDict["gameBoundsHeight"] = gameBounds.height
        
        // Сохраняем настройки отладки
        settingsDict["showDebugOverlay"] = showDebugOverlay
        
        // Сохраняем в UserDefaults
        UserDefaults.standard.set(settingsDict, forKey: userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Устанавливает настройки по умолчанию
    static func setDefaultSettings() {
        // Определяем область захвата по умолчанию (центр главного экрана)
        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.frame
            
            // Устанавливаем область в центре экрана
            let captureWidth = screenRect.width * 0.7
            let captureHeight = screenRect.height * 0.4
            let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
            let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
            
            captureRect = CGRect(
                x: captureX,
                y: captureY,
                width: captureWidth,
                height: captureHeight
            )
            
            // Устанавливаем границы игры равными области захвата
            gameBounds = captureRect
        }
        
        // Выбираем главный экран по умолчанию
        selectedScreen = NSScreen.main
        
        // Сохраняем настройки
        saveSettings()
    }
    
    /// Сбрасывает настройки до значений по умолчанию
    static func resetSettings() {
        setDefaultSettings()
    }
    
    /// Включает игровой режим и устанавливает границы игры
    static func enableGameMode() {
        isGameModeEnabled = true
        
        // Если границы игры не установлены, используем текущую область захвата
        if gameBounds.width <= 0 || gameBounds.height <= 0 {
            if useWindowMode {
                if let windowID = selectedWindowID {
                    if let info = WindowManager.getWindowInfoByID(windowID) {
                        gameBounds = info.bounds
                    }
                }
            } else {
                gameBounds = captureRect
            }
        }
        
        Logger.shared.log("Игровой режим включен. Границы игры: \(gameBounds)")
    }
    
    /// Выключает игровой режим
    static func disableGameMode() {
        isGameModeEnabled = false
        Logger.shared.log("Игровой режим выключен")
    }
} 