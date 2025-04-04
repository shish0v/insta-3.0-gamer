import Cocoa

struct Config {
    // Версия приложения
    static let appVersion = "3.5"
    
    // Параметры обнаружения синего цвета
    static var blueMinValue: UInt8 = 180
    static var redMaxValue: UInt8 = 100
    static var greenMaxValue: UInt8 = 120
    
    // Параметры для стабилизации движения
    static var movementThreshold: CGFloat = 5.0
    static var smoothingFactor: CGFloat = 0.5
    
    // Использовать прогнозирование движения
    static var useMotionPrediction: Bool = true
    
    // Размер области захвата
    static var captureRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    // Шаг сканирования (больше - быстрее, но менее точно)
    static let scanStep = 4
    
    // Минимальное количество синих пикселей для перемещения курсора
    static var minBluePixels = 10
    
    // Показывать подсветку области захвата
    static var showHighlight = true
    
    // Выбранный экран для отслеживания
    static var selectedScreen: NSScreen?
    
    // Информация о выбранном окне
    static var selectedWindowID: CGWindowID?
    static var selectedWindowName: String?
    
    // Использовать окно вместо области экрана
    static var useWindowMode: Bool = false
    
    // Текущие границы выбранного окна
    static var currentWindowBounds: CGRect?
    
    // Кастомные коэффициенты масштабирования для преобразования координат
    static var customScaleX: CGFloat?
    static var customScaleY: CGFloat?
    
    // Сохранение настроек в UserDefaults
    static func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Сохраняем область захвата
        defaults.set(captureRect.origin.x, forKey: "captureRectX")
        defaults.set(captureRect.origin.y, forKey: "captureRectY")
        defaults.set(captureRect.width, forKey: "captureRectWidth")
        defaults.set(captureRect.height, forKey: "captureRectHeight")
        
        // Сохраняем настройки цвета
        defaults.set(blueMinValue, forKey: "blueMinValue")
        defaults.set(redMaxValue, forKey: "redMaxValue")
        defaults.set(greenMaxValue, forKey: "greenMaxValue")
        
        // Сохраняем настройки движения
        defaults.set(movementThreshold, forKey: "movementThreshold")
        defaults.set(smoothingFactor, forKey: "smoothingFactor")
        defaults.set(minBluePixels, forKey: "minBluePixels")
        defaults.set(useMotionPrediction, forKey: "useMotionPrediction")
        
        // Сохраняем настройки подсветки
        defaults.set(showHighlight, forKey: "showHighlight")
        
        // Сохраняем идентификатор выбранного экрана, если он существует
        if let screenID = selectedScreen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            defaults.set(screenID.intValue, forKey: "selectedScreenID")
        }
        
        // Сохраняем настройки режима окна
        defaults.set(useWindowMode, forKey: "useWindowMode")
        
        // Сохраняем информацию о выбранном окне, если есть
        if let windowID = selectedWindowID {
            defaults.set(windowID, forKey: "selectedWindowID")
        }
        
        if let windowName = selectedWindowName {
            defaults.set(windowName, forKey: "selectedWindowName")
        }
        
        defaults.synchronize()
    }
    
    // Загрузка настроек из UserDefaults
    static func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Загружаем область захвата
        let x = defaults.double(forKey: "captureRectX")
        let y = defaults.double(forKey: "captureRectY")
        let width = defaults.double(forKey: "captureRectWidth")
        let height = defaults.double(forKey: "captureRectHeight")
        
        // Проверяем, что настройки уже были сохранены ранее
        if width > 0 && height > 0 {
            captureRect = CGRect(x: x, y: y, width: width, height: height)
        }
        
        // Загружаем настройки цвета
        if let blueMin = defaults.object(forKey: "blueMinValue") as? UInt8 {
            blueMinValue = blueMin
        }
        
        if let redMax = defaults.object(forKey: "redMaxValue") as? UInt8 {
            redMaxValue = redMax
        }
        
        if let greenMax = defaults.object(forKey: "greenMaxValue") as? UInt8 {
            greenMaxValue = greenMax
        }
        
        // Загружаем настройки движения
        if let threshold = defaults.object(forKey: "movementThreshold") as? CGFloat {
            movementThreshold = threshold
        }
        
        if let smoothing = defaults.object(forKey: "smoothingFactor") as? CGFloat {
            smoothingFactor = smoothing
        }
        
        if let minPixels = defaults.object(forKey: "minBluePixels") as? Int {
            minBluePixels = minPixels
        }
        
        if let prediction = defaults.object(forKey: "useMotionPrediction") as? Bool {
            useMotionPrediction = prediction
        }
        
        // Загружаем настройки подсветки
        if let highlight = defaults.object(forKey: "showHighlight") as? Bool {
            showHighlight = highlight
        }
        
        // Загружаем выбранный экран
        if let screenID = defaults.object(forKey: "selectedScreenID") as? Int {
            selectedScreen = NSScreen.screens.first(where: { 
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.intValue == screenID
            })
        } else {
            selectedScreen = NSScreen.main
        }
        
        // Загружаем настройки режима окна
        useWindowMode = defaults.bool(forKey: "useWindowMode")
        
        // Загружаем информацию о выбранном окне
        if let windowID = defaults.object(forKey: "selectedWindowID") as? CGWindowID {
            selectedWindowID = windowID
        }
        
        if let windowName = defaults.string(forKey: "selectedWindowName") {
            selectedWindowName = windowName
        }
    }
    
    // Добавляем в структуру Config метод для логирования настроек
    static func logCurrentSettings() {
        Logger.shared.log("Текущие настройки:")
        Logger.shared.log("  Режим: \(useWindowMode ? "Окно" : "Область экрана")")
        Logger.shared.log("  Область захвата: \(captureRect)")
        
        if let screen = selectedScreen {
            Logger.shared.log("  Выбранный экран: \(screen.frame), масштаб: \(screen.backingScaleFactor)")
        } else {
            Logger.shared.log("  Выбранный экран: не задан")
        }
        
        if let windowID = selectedWindowID, let windowName = selectedWindowName {
            Logger.shared.log("  Выбранное окно: \(windowName) (ID: \(windowID))")
            if let windowBounds = currentWindowBounds {
                Logger.shared.log("  Границы окна: \(windowBounds)")
            }
        }
        
        if let scaleX = customScaleX, let scaleY = customScaleY {
            Logger.shared.log("  Кастомные коэффициенты масштабирования: X=\(scaleX), Y=\(scaleY)")
        }
        
        Logger.shared.log("  Параметры цвета: blue ≥ \(blueMinValue), red ≤ \(redMaxValue), green ≤ \(greenMaxValue)")
        Logger.shared.log("  Параметры движения: порог \(movementThreshold), сглаживание \(smoothingFactor)")
        Logger.shared.log("  Прогнозирование движения: \(useMotionPrediction ? "Включено" : "Выключено")")
    }
    
    // Добавляем валидацию значений
    enum ValidationError: Error {
        case invalidColorValue(String)
        case invalidMovementValue(String)
        case invalidCaptureRect
    }
    
    static func validateSettings() throws {
        guard (0...255).contains(blueMinValue) else {
            throw ValidationError.invalidColorValue("Blue min value must be between 0 and 255")
        }
        
        guard (0...255).contains(redMaxValue) else {
            throw ValidationError.invalidColorValue("Red max value must be between 0 and 255")
        }
        
        guard (0...255).contains(greenMaxValue) else {
            throw ValidationError.invalidColorValue("Green max value must be between 0 and 255")
        }
        
        guard movementThreshold > 0 else {
            throw ValidationError.invalidMovementValue("Movement threshold must be positive")
        }
        
        guard (0.1...0.9).contains(smoothingFactor) else {
            throw ValidationError.invalidMovementValue("Smoothing factor must be between 0.1 and 0.9")
        }
        
        guard captureRect.width > 0, captureRect.height > 0 else {
            throw ValidationError.invalidCaptureRect
        }
    }
    
    static func applyAndValidateSettings() -> Bool {
        do {
            try validateSettings()
            return true
        } catch let error as ValidationError {
            Logger.shared.log("Validation error: \(error)")
            return false
        } catch {
            Logger.shared.log("Unexpected error: \(error)")
            return false
        }
    }
}