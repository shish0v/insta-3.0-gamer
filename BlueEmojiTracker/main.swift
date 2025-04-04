import Cocoa
import CoreGraphics
import CoreImage
import Foundation
import Metal
import MetalKit
@preconcurrency import ScreenCaptureKit

// Проверка версии macOS
func checkMacOSVersion() -> Bool {
    if #available(macOS 12.3, *) {
        return true
    } else {
        // Показываем предупреждение для старых версий macOS
        let alert = NSAlert()
        alert.messageText = "Несовместимая версия macOS"
        alert.informativeText = "Для работы BlueEmojiTracker v\(Config.appVersion) требуется macOS 12.3 или новее. Пожалуйста, обновите вашу операционную систему или используйте альтернативную версию приложения."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        // Выводим сообщение в консоль
        print("❌ Ошибка: BlueEmojiTracker требует macOS 12.3 или новее.")
        print("   Ваша версия macOS несовместима с данным приложением.")
        
        return false
    }
}

// Настраиваемые параметры
struct Config {
    // Версия приложения
    static let appVersion = "3.5"
    
    // Параметры обнаружения синего цвета
    static var blueMinValue: UInt8 = 160 // Уменьшаем порог для синего цвета
    static var redMaxValue: UInt8 = 120 // Увеличиваем допустимый красный
    static var greenMaxValue: UInt8 = 130 // Увеличиваем допустимый зеленый
    
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
    static var minBluePixels = 5 // Уменьшаем необходимое количество пикселей
    
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
    
    // Добавляем метод для сброса настроек в структуру Config
    static func resetSettings() {
        let defaults = UserDefaults.standard
        
        // Список ключей, которые нужно удалить
        let keysToReset = [
            "captureRectX", "captureRectY", "captureRectWidth", "captureRectHeight",
            "blueMinValue", "redMaxValue", "greenMaxValue",
            "movementThreshold", "smoothingFactor", "minBluePixels", "useMotionPrediction",
            "showHighlight", "selectedScreenID", "useWindowMode",
            "selectedWindowID", "selectedWindowName"
        ]
        
        // Удаляем каждый ключ
        for key in keysToReset {
            defaults.removeObject(forKey: key)
        }
        
        // Устанавливаем значения по умолчанию
        blueMinValue = 160
        redMaxValue = 120
        greenMaxValue = 130
        movementThreshold = 5.0
        smoothingFactor = 0.5
        minBluePixels = 5
        useMotionPrediction = true
        showHighlight = true
        useWindowMode = false
        selectedScreen = NSScreen.main
        selectedWindowID = nil
        selectedWindowName = nil
        customScaleX = nil
        customScaleY = nil
        
        // Устанавливаем область в центре главного экрана
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let captureWidth = screenRect.width * 0.6
            let captureHeight = screenRect.height * 0.3
            let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
            let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
            
            captureRect = CGRect(
                x: captureX,
                y: captureY,
                width: captureWidth,
                height: captureHeight
            )
        }
        
        Logger.shared.log("Настройки сброшены до значений по умолчанию")
        
        // Сохраняем настройки по умолчанию
        saveSettings()
    }
}

// Класс для отслеживания и детектирования
class BlueEmojiTracker {
    // Состояние отслеживания
    public private(set) var isTracking = false
    private var timer: Timer?
    private var lastPosition = CGPoint.zero
    
    // Параметры предиктивного движения
    private var lastMoveTime = Date()
    private var velocityX: CGFloat = 0
    private var velocityY: CGFloat = 0
    private var lastPositions: [CGPoint] = []
    private let positionsHistorySize = 5
    private var adaptiveSensitivity: CGFloat = 1.0
    private var consecutiveNoMoveCount = 0
    
    // UI элементы
    private var statusLabel: NSTextField?
    private var previewView: NSImageView?
    
    private var screenCheckTimer: Timer?
    
    init() {
        setupCaptureRect()
    }
    
    // Настройка области захвата экрана
    private func setupCaptureRect() {
        // Загружаем сохраненные настройки
        Config.loadSettings()
        
        // Если область захвата не была задана или некорректна, устанавливаем значения по умолчанию
        if Config.captureRect.width <= 0 || Config.captureRect.height <= 0 {
            let screen = Config.selectedScreen ?? NSScreen.main!
            let screenRect = screen.frame
            
            // По умолчанию используем область в центре экрана
            let captureWidth = screenRect.width * 0.6
            let captureHeight = screenRect.height * 0.3
            let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
            let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
            
            Config.captureRect = CGRect(
                x: captureX,
                y: captureY,
                width: captureWidth,
                height: captureHeight
            )
        }
        
        print("Область отслеживания: \(Config.captureRect)")
    }
    
    // Захват экрана с помощью CGWindowListCreateImage
    private func captureScreen() -> CGImage? {
        if Config.useWindowMode && Config.selectedWindowID != nil {
            // Режим окна: захватываем только выбранное окно
            return captureWindow()
        } else {
            // Обычный режим: захватываем область экрана
            return captureScreenArea()
        }
    }
    
    // Метод для захвата конкретного окна
    private func captureWindow() -> CGImage? {
        guard let windowID = Config.selectedWindowID else {
            Logger.shared.log("⚠️ Не выбрано окно для захвата")
            return nil
        }
        
        // Проверяем, что окно всё ещё существует и получаем его границы
        guard let windowInfo = WindowManager.getWindowInfo(windowID: windowID) else {
            Logger.shared.log("⚠️ Выбранное окно больше не доступно (ID: \(windowID))")
            
            // Автоматически переключаемся в режим области экрана, если окно недоступно
            Config.useWindowMode = false
            Logger.shared.log("⚠️ Автоматическое переключение в режим области экрана")
            
            // Возвращаем nil, чтобы перейти к следующему кадру
            return nil
        }
        
        // Сохраняем границы окна для последующего преобразования координат
        Config.currentWindowBounds = windowInfo.bounds
        Logger.shared.log("Границы окна: \(windowInfo.bounds)")
        
        // Захватываем изображение окна с дополнительной диагностикой
        let cgOptions: CGWindowImageOption = [.boundsIgnoreFraming, .bestResolution]
        let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            cgOptions
        )
        
        if let image = image {
            Logger.shared.log("Успешно захвачено изображение окна. Размер: \(image.width)x\(image.height)")
            
            // Дополнительная проверка соответствия размеров
            let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            let windowBounds = windowInfo.bounds
            
            // Логируем несоответствие размеров, если оно есть
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
            let expectedWidth = windowBounds.width * scaleFactor
            let expectedHeight = windowBounds.height * scaleFactor
            
            Logger.shared.log("Масштабный коэффициент экрана: \(scaleFactor)")
            Logger.shared.log("Границы окна: \(windowBounds.width)x\(windowBounds.height)")
            Logger.shared.log("Ожидаемый размер изображения с учетом масштаба: \(expectedWidth)x\(expectedHeight)")
            Logger.shared.log("Фактический размер изображения: \(image.width)x\(image.height)")
            
            // Исправляем типы: приводим к CGFloat
            let imgWidth = CGFloat(image.width)
            let imgHeight = CGFloat(image.height)
            
            // Если есть значительное несоответствие, рассчитываем коэффициент масштаба
            if abs(imgWidth - expectedWidth) > 5 || abs(imgHeight - expectedHeight) > 5 {
                let scaleX = imgWidth / windowBounds.width
                let scaleY = imgHeight / windowBounds.height
                Logger.shared.log("Обнаружено несоответствие размеров. Рассчитанные коэффициенты масштаба: X=\(scaleX), Y=\(scaleY)")
                
                // Сохраняем в конфигурацию для использования в преобразованиях координат
                Config.customScaleX = scaleX
                Config.customScaleY = scaleY
            } else {
                // Если размеры соответствуют ожидаемым, используем системный масштаб
                Config.customScaleX = scaleFactor
                Config.customScaleY = scaleFactor
            }
        } else {
            Logger.shared.log("⚠️ Не удалось захватить изображение окна \(windowID)")
        }
        
        return image
    }
    
    // Переименовываем существующий метод захвата для ясности
    private func captureScreenArea() -> CGImage? {
        // Проверяем, что область захвата корректна
        guard Config.captureRect.width > 0 && Config.captureRect.height > 0 else {
            print("⚠️ Некорректные размеры области захвата")
            
            // Автоматически устанавливаем область захвата по центру экрана
            if let screen = Config.selectedScreen ?? NSScreen.main {
                let screenRect = screen.frame
                
                // По умолчанию используем область в центре экрана
                let captureWidth = screenRect.width * 0.6
                let captureHeight = screenRect.height * 0.3
                let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
                let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
                
                Config.captureRect = CGRect(
                    x: captureX,
                    y: captureY,
                    width: captureWidth,
                    height: captureHeight
                )
                
                Logger.shared.log("⚠️ Автоматически установлена область захвата: \(Config.captureRect)")
            }
            
            return nil
        }
        
        // Создаем копию области захвата для использования внутри метода
        let captureArea = Config.captureRect
        
        // Получаем выбранный экран
        guard let selectedScreen = Config.selectedScreen else {
            print("⚠️ Не выбран экран для захвата")
            
            // Автоматически выбираем главный экран
            Config.selectedScreen = NSScreen.main
            Logger.shared.log("⚠️ Автоматически выбран главный экран")
            
            return nil
        }
        
        // Проверяем, что экран все еще доступен
        if !NSScreen.screens.contains(selectedScreen) {
            Logger.shared.log("⚠️ Выбранный экран больше не доступен")
            
            // Автоматически выбираем главный экран
            Config.selectedScreen = NSScreen.main
            Logger.shared.log("⚠️ Автоматически выбран главный экран")
            
            return nil
        }
        
        // Преобразуем в флиппированные координаты
        // Для этого API координата Y отсчитывается снизу экрана
        let flippedRect = CGRect(
            x: captureArea.origin.x,
            y: selectedScreen.frame.height - captureArea.origin.y - captureArea.height,
            width: captureArea.width, 
            height: captureArea.height
        )
        
        Logger.shared.log("Захват области: \(captureArea), флиппированный прямоугольник: \(flippedRect)")
        
        // Захватываем часть экрана
        let image = CGWindowListCreateImage(
            flippedRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        
        if image == nil {
            Logger.shared.log("⚠️ Не удалось захватить изображение экрана. Проверьте разрешения в настройках системы.")
        } else {
            Logger.shared.log("Успешно захвачено изображение экрана. Размер: \(image!.width)x\(image!.height)")
        }
        
        return image
    }
    
    // Поиск синего объекта на изображении
    private func findBlueObject(in image: CGImage) -> CGPoint? {
        // Получаем размеры изображения
        let width = image.width
        let height = image.height
        
        Logger.shared.log("Анализ изображения размером \(width)x\(height)")
        
        // Создаем контекст для работы с изображением
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            Logger.shared.log("Не удалось создать контекст для обработки изображения")
            return nil
        }
        
        // Отрисовываем изображение в контекст
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        
        // Получаем данные изображения
        guard let data = context.data else {
            Logger.shared.log("Не удалось получить данные изображения")
            return nil
        }
        
        // Приводим данные к нужному типу
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        
        // Для хранения найденного синего объекта
        var totalBlueX = 0
        var totalBlueY = 0
        var bluePixelCount = 0
        var maxBlueValue: UInt8 = 0
        var maxBluePos = CGPoint.zero
        
        // Для bounding box
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        // Шаг сканирования из настроек
        let step = Config.scanStep
        
        // Сканируем изображение
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                // Получаем индекс пикселя (4 байта на пиксель: R, G, B, A)
                let pixelIndex = (y * width + x) * 4
                
                // Проверяем, что не выходим за границы массива
                if pixelIndex + 2 < width * height * 4 {
                    // Получаем компоненты цвета
                    let red = pixelData[pixelIndex]
                    let green = pixelData[pixelIndex + 1]
                    let blue = pixelData[pixelIndex + 2]
                    
                    // Проверяем, соответствует ли цвет критериям "синего"
                    // Используем более либеральные критерии для улучшения обнаружения
                    if blue >= Config.blueMinValue && 
                       red <= Config.redMaxValue && 
                       green <= Config.greenMaxValue && 
                       blue > red + 50 && // Добавляем условие: синий должен быть заметно больше красного
                       blue > green + 50 { // Добавляем условие: синий должен быть заметно больше зеленого
                        
                        // Учитываем этот пиксель в расчете центра масс
                        totalBlueX += x
                        totalBlueY += y
                        bluePixelCount += 1
                        
                        // Обновляем bounding box
                        minX = min(minX, x)
                        minY = min(minY, y)
                        maxX = max(maxX, x)
                        maxY = max(maxY, y)
                        
                        // Отслеживаем пиксель с максимальным значением синего
                        if blue > maxBlueValue {
                            maxBlueValue = blue
                            maxBluePos = CGPoint(x: x, y: y)
                        }
                    }
                }
            }
        }
        
        Logger.shared.log("Найдено синих пикселей: \(bluePixelCount)")
        
        // Проверяем, что найдено достаточное количество синих пикселей
        if bluePixelCount >= Config.minBluePixels {
            // Сначала определяем координаты лучшей точки внутри захваченного изображения
            let pointInImage: CGPoint
            
            if minX < maxX && minY < maxY {
                // Используем центр bounding box
                pointInImage = CGPoint(
                    x: (minX + maxX) / 2,
                    y: (minY + maxY) / 2
                )
                Logger.shared.log("Используем центр bounding box: \(pointInImage)")
            } else if maxBlueValue > 0 {
                // Используем точку с максимальным значением синего
                pointInImage = maxBluePos
                Logger.shared.log("Используем точку с максимальным синим: \(pointInImage)")
            } else {
                // Используем центр масс
                pointInImage = CGPoint(
                    x: CGFloat(totalBlueX) / CGFloat(bluePixelCount),
                    y: CGFloat(totalBlueY) / CGFloat(bluePixelCount)
                )
                Logger.shared.log("Используем центр масс: \(pointInImage)")
            }
            
            // Преобразуем координаты изображения в координаты экрана
            let screenPoint: CGPoint
            
            if Config.useWindowMode, let windowBounds = Config.currentWindowBounds {
                // Для режима окна: учитываем масштабирование при преобразовании координат
                let scaleX = Config.customScaleX ?? 1.0
                let scaleY = Config.customScaleY ?? 1.0
                
                // Координаты в изображении могут быть масштабированы, возвращаем их к реальным
                let adjustedX = pointInImage.x / scaleX
                let adjustedY = pointInImage.y / scaleY
                
                // Преобразуем в координаты экрана
                screenPoint = CGPoint(
                    x: windowBounds.origin.x + adjustedX,
                    y: windowBounds.origin.y + adjustedY
                )
                
                Logger.shared.log("Преобразование координат (окно): \(pointInImage) -> \(screenPoint)")
                Logger.shared.log("Формула: масштабирование \(pointInImage.x)/\(scaleX), \(pointInImage.y)/\(scaleY)")
                Logger.shared.log("Финальные координаты: (\(windowBounds.origin.x) + \(adjustedX), \(windowBounds.origin.y) + \(adjustedY))")
            } else {
                // Для режима области: обрабатываем случай инвертированной оси Y
                // Убираем неиспользуемую переменную
                _ = Config.selectedScreen ?? NSScreen.main!
                
                // Проверяем, нужна ли инверсия координаты Y
                // Для CGWindowListCreateImage с флипом координаты Y начинаются снизу
                // Для NSScreen координаты начинаются сверху
                screenPoint = CGPoint(
                    x: Config.captureRect.origin.x + pointInImage.x,
                    y: Config.captureRect.origin.y + pointInImage.y
                )
                
                Logger.shared.log("Преобразование координат (область): \(pointInImage) -> \(screenPoint)")
                Logger.shared.log("Формула: (\(Config.captureRect.origin.x) + \(pointInImage.x), \(Config.captureRect.origin.y) + \(pointInImage.y))")
            }
            
            Logger.shared.log("Найден синий объект (пикселей: \(bluePixelCount)). Координаты: \(screenPoint)")
            return screenPoint
        } else if bluePixelCount > 0 {
            Logger.shared.log("Недостаточно синих пикселей: \(bluePixelCount) < \(Config.minBluePixels)")
        }
        
        return nil
    }
    
    // Перемещение курсора к новой позиции с плавностью движения
    private func moveCursorTo(point: CGPoint) {
        Logger.shared.log("Перемещение курсора к точке: \(point)")
        
        // Определяем область, в которой можно перемещать курсор
        let targetArea: CGRect
        
        if Config.useWindowMode, let windowBounds = Config.currentWindowBounds {
            // В режиме окна используем границы окна
            targetArea = windowBounds
            Logger.shared.log("Используем границы окна: \(windowBounds)")
        } else if let selectedScreen = Config.selectedScreen {
            // В режиме экрана используем границы экрана
            targetArea = selectedScreen.frame
            Logger.shared.log("Используем границы экрана: \(selectedScreen.frame)")
        } else {
            Logger.shared.log("Не определена область для перемещения курсора")
            return
        }
        
        // Проверяем, что точка находится в допустимой области
        if !targetArea.contains(point) {
            Logger.shared.log("Точка \(point) находится за пределами допустимой области \(targetArea)")
            return
        }
        
        // Получаем текущее положение курсора
        let currentMouseLocation = NSEvent.mouseLocation
        Logger.shared.log("Текущее положение курсора: \(currentMouseLocation)")
        
        // Вычисляем расстояние до цели
        let actualDistance = hypot(point.x - currentMouseLocation.x, point.y - currentMouseLocation.y)
        
        // Если расстояние очень маленькое, можно не перемещать курсор
        let minMeaningfulDistance: CGFloat = 3.0  // 3 пикселя как минимальное значимое расстояние
        if actualDistance < minMeaningfulDistance {
            print("Курсор уже достаточно близко к цели (расстояние: \(actualDistance) < \(minMeaningfulDistance))")
            consecutiveNoMoveCount += 1
            return
        }
        
        // Сбрасываем счетчик, если курсор перемещается
        consecutiveNoMoveCount = 0
        
        // Рассчитываем время с момента последнего перемещения
        let currentTime = Date()
        let elapsedTime = currentTime.timeIntervalSince(lastMoveTime)
        lastMoveTime = currentTime
        
        // Адаптивная чувствительность в зависимости от скорости движения объекта
        adaptiveSensitivity = min(max(1.0 - (actualDistance / 200.0), 0.5), 1.5)
        
        // Вычисляем расстояние между последней обработанной позицией и целевой точкой
        let calculatedDistance = hypot(point.x - lastPosition.x, point.y - lastPosition.y)
        
        // Добавляем текущую точку в историю для предсказания движения
        if lastPositions.count >= positionsHistorySize {
            lastPositions.removeFirst()
        }
        lastPositions.append(point)
        
        // Рассчитываем скорость движения
        if elapsedTime > 0 && lastPosition != .zero {
            velocityX = (point.x - lastPosition.x) / CGFloat(elapsedTime)
            velocityY = (point.y - lastPosition.y) / CGFloat(elapsedTime)
        }
        
        // Прогнозируем следующую позицию на основе истории движений
        var predictedPoint = point
        
        if lastPositions.count >= 3 && abs(velocityX) + abs(velocityY) > 10 {
            // Используем предсказание только при значительном движении
            // Простая линейная экстраполяция на основе средней скорости
            let predictionFactor: CGFloat = 0.1 // 100мс предсказания
            predictedPoint = CGPoint(
                x: point.x + velocityX * predictionFactor,
                y: point.y + velocityY * predictionFactor
            )
            
            // Проверяем, что предсказанная точка находится в разумных пределах
            let maxPredictionDistance: CGFloat = 50.0
            let predictionDistance = hypot(predictedPoint.x - point.x, predictedPoint.y - point.y)
            if predictionDistance > maxPredictionDistance {
                // Ограничиваем предсказание, если оно слишком далеко
                let ratio = maxPredictionDistance / predictionDistance
                predictedPoint = CGPoint(
                    x: point.x + (predictedPoint.x - point.x) * ratio,
                    y: point.y + (predictedPoint.y - point.y) * ratio
                )
            }
            
            print("Предсказанная точка: \(predictedPoint), на основе скорости: (\(velocityX), \(velocityY))")
        }
        
        // Проверяем, превышает ли расстояние порог движения или это первое перемещение
        if calculatedDistance > Config.movementThreshold * adaptiveSensitivity || lastPosition == .zero {
            // Решаем, использовать ли прямое перемещение или сглаживание
            // Если расстояние большое или наблюдается значительное отклонение, используем прямое перемещение
            let useDirect = actualDistance > 50.0 || abs(calculatedDistance - actualDistance) > 20.0
            
            // Определяем целевую точку (обычную или предсказанную)
            let targetPoint = (Config.useMotionPrediction && !useDirect) ? predictedPoint : point
            
            // Вычисляем новую позицию
            let newPosition: CGPoint
            if useDirect {
                // Прямое перемещение для большого расстояния
                newPosition = targetPoint
                print("Используем прямое перемещение из-за большого расстояния")
            } else {
                // Применяем адаптивное сглаживание для плавного движения
                // При высокой скорости используем меньшее сглаживание
                let maxVelocity: CGFloat = 1000
                let velocityMagnitude = min(hypot(velocityX, velocityY), maxVelocity)
                let velocityFactor = velocityMagnitude / maxVelocity // 0-1
                
                // Адаптируем сглаживание в зависимости от скорости
                let adaptedSmoothingFactor = max(0.3, min(0.9, Config.smoothingFactor * (1.0 - velocityFactor * 0.4)))
                
                // Рассчитываем новую позицию с учетом адаптивного сглаживания
                let smoothedX = currentMouseLocation.x + (point.x - currentMouseLocation.x) * adaptedSmoothingFactor
                let smoothedY = currentMouseLocation.y + (point.y - currentMouseLocation.y) * adaptedSmoothingFactor
                newPosition = CGPoint(x: smoothedX, y: smoothedY)
                print("Используем сглаживание с фактором \(adaptedSmoothingFactor)")
            }
            
            // Создаем событие перемещения мыши
            if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPosition, mouseButton: .left) {
                // Отправляем событие
                moveEvent.post(tap: .cghidEventTap)
                
                // Обновляем последнюю позицию
                lastPosition = newPosition
                
                Logger.shared.log("Курсор перемещен в: \(newPosition)")
            } else {
                print("Не удалось создать событие перемещения мыши")
            }
        } else {
            print("Расстояние \(calculatedDistance) меньше порога \(Config.movementThreshold), пропускаем перемещение")
        }
    }
    
    // Проверка доступности выбранного экрана
    private func isSelectedScreenAvailable() -> Bool {
        guard let selectedScreen = Config.selectedScreen else {
            // Если экран не выбран, используем главный
            Config.selectedScreen = NSScreen.main
            return NSScreen.main != nil
        }
        
        // Проверяем, что выбранный экран всё ещё в списке доступных экранов
        return NSScreen.screens.contains(selectedScreen)
    }
    
    // Проверка доступности выбранного окна
    private func isSelectedWindowAvailable() -> Bool {
        guard Config.useWindowMode, let windowID = Config.selectedWindowID else {
            return true // Если не используем режим окна, то всё в порядке
        }
        
        return WindowManager.isWindowAvailable(windowID: windowID)
    }
    
    // Модифицируем метод проверки доступности ресурсов
    private func isTrackingResourceAvailable() -> Bool {
        if Config.useWindowMode {
            return isSelectedWindowAvailable()
        } else {
            return isSelectedScreenAvailable()
        }
    }
    
    // Начало отслеживания
    func startTracking() {
        guard !isTracking else { return }
        
        Logger.shared.log("Запуск отслеживания")
        Config.logCurrentSettings()
        
        // Проверяем доступность ресурсов (экрана или окна)
        if !isTrackingResourceAvailable() {
            Logger.shared.log("⚠️ Ресурсы для отслеживания недоступны, пытаемся исправить автоматически")
            
            // Пытаемся автоматически исправить проблему
            if Config.useWindowMode {
                // Если окно недоступно, переключаемся в режим области экрана
                Config.useWindowMode = false
                Logger.shared.log("⚠️ Автоматическое переключение в режим области экрана")
            }
            
            // Проверяем выбранный экран
            if Config.selectedScreen == nil || !NSScreen.screens.contains(Config.selectedScreen!) {
                Config.selectedScreen = NSScreen.main
                Logger.shared.log("⚠️ Автоматически выбран главный экран")
            }
            
            // Еще раз проверяем доступность ресурсов
            if !isTrackingResourceAvailable() {
                let alert = NSAlert()
                
                alert.messageText = "Невозможно начать отслеживание"
                alert.informativeText = "Не удалось получить доступ к необходимым ресурсам. Пожалуйста, проверьте настройки и разрешения приложения в Системных настройках → Конфиденциальность и безопасность → Запись экрана."
                
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
                // Обновляем статус
                statusLabel?.stringValue = "Отслеживание невозможно: проверьте разрешения"
                return
            }
        }
        
        // Показываем область захвата перед началом отслеживания
        if !Config.useWindowMode {
            showCaptureArea()
        }
        
        isTracking = true
        
        // Сбрасываем кэшированные данные
        lastPosition = .zero
        lastPositions.removeAll()
        velocityX = 0
        velocityY = 0
        consecutiveNoMoveCount = 0
        
        // Обновляем статус
        statusLabel?.stringValue = "Отслеживание активно"
        
        // Создаем очередь для асинхронной обработки изображений
        let processingQueue = DispatchQueue(label: "com.blueemojitracker.processing", qos: .userInteractive)
        
        // Используем более высокую частоту захвата (50 Гц вместо 20 Гц)
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }
            
            // Захватываем изображение синхронно, так как это быстрая операция
            guard let capturedImage = self.captureScreen() else {
                print("Не удалось захватить изображение экрана")
                return
            }
            
            // Передаем изображение для обработки в асинхронную очередь
            processingQueue.async { [weak self] in
                guard let self = self, self.isTracking else { return }
                
                // Ищем синий объект в захваченном изображении
                if let blueObjectPoint = self.findBlueObject(in: capturedImage) {
                    // Возвращаемся в основной поток для перемещения курсора
                    DispatchQueue.main.async {
                        guard self.isTracking else { return }
                        // Если синий объект найден, перемещаем к нему курсор
                        self.moveCursorTo(point: blueObjectPoint)
                    }
                } else {
                    // Увеличиваем счетчик, если не нашли объект
                    DispatchQueue.main.async {
                        self.consecutiveNoMoveCount += 1
                        if self.consecutiveNoMoveCount > 10 {
                            // Если объект не найден в 10 последовательных кадрах,
                            // сбрасываем скорость, чтобы избежать инерции
                            self.velocityX = 0
                            self.velocityY = 0
                        }
                    }
                }
            }
        }
        
        // Модифицируем таймер проверки доступности ресурсов
        screenCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }
            
            if !self.isTrackingResourceAvailable() {
                self.stopTracking()
                
                // Показываем уведомление
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    
                    if Config.useWindowMode {
                        alert.messageText = "Отслеживание остановлено"
                        alert.informativeText = "Выбранное окно больше не доступно. Отслеживание было автоматически остановлено."
                    } else {
                        alert.messageText = "Отслеживание остановлено"
                        alert.informativeText = "Выбранный экран больше не доступен. Отслеживание было автоматически остановлено."
                    }
                    
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                    // Обновляем статус
                    self.statusLabel?.stringValue = Config.useWindowMode ? 
                        "Отслеживание остановлено: окно недоступно" : 
                        "Отслеживание остановлено: экран недоступен"
                }
            }
        }
    }
    
    // Остановка отслеживания
    func stopTracking() {
        guard isTracking else { return }
        
        Logger.shared.log("Остановка отслеживания")
        
        isTracking = false
        
        // Останавливаем таймер
        timer?.invalidate()
        timer = nil
        
        // Сбрасываем последнюю позицию
        lastPosition = .zero
        
        // Обновляем статус
        statusLabel?.stringValue = "Отслеживание остановлено"
        
        // Останавливаем таймер проверки экрана
        screenCheckTimer?.invalidate()
        screenCheckTimer = nil
    }
    
    // Установка ссылок на UI элементы
    func setStatusLabel(_ label: NSTextField) {
        statusLabel = label
    }
    
    func setPreviewView(_ view: NSImageView) {
        previewView = view
    }
    
    // Показать область захвата с подсветкой
    func showCaptureArea() {
        guard Config.showHighlight else { return }
        
        // Добавляем отладочную информацию
        Logger.shared.log("Показываем область захвата: \(Config.captureRect)")
        
        let highlightWindow = NSWindow(
            contentRect: Config.captureRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        highlightWindow.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.3)
        highlightWindow.level = .floating
        highlightWindow.isOpaque = false
        highlightWindow.hasShadow = false
        
        highlightWindow.orderFront(nil)
        
        // Автоматически закрываем окно через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            highlightWindow.close()
        }
    }
    
    // Функция для диагностики захвата экрана
    func diagnoseScreenCapture() {
        Logger.shared.log("Запуск диагностики захвата экрана...")
        
        // Проверяем режим отслеживания
        if Config.useWindowMode {
            Logger.shared.log("Текущий режим: отслеживание окна")
            
            // Проверяем выбранное окно
            if let windowID = Config.selectedWindowID, let windowName = Config.selectedWindowName {
                Logger.shared.log("Выбранное окно: \(windowName) (ID: \(windowID))")
                
                // Проверяем, доступно ли окно
                if WindowManager.isWindowAvailable(windowID: windowID) {
                    Logger.shared.log("Окно доступно на экране")
                    
                    // Попытка захвата окна
                    if let capturedImage = captureWindow() {
                        Logger.shared.log("✅ Успешно захвачено изображение окна размером \(capturedImage.width)x\(capturedImage.height)")
                    } else {
                        Logger.shared.log("❌ Не удалось захватить изображение окна, несмотря на его доступность")
                        Logger.shared.log("   Переключаемся в режим области экрана...")
                        Config.useWindowMode = false
                    }
                } else {
                    Logger.shared.log("❌ Выбранное окно недоступно на экране")
                    Logger.shared.log("   Переключаемся в режим области экрана...")
                    Config.useWindowMode = false
                }
            } else {
                Logger.shared.log("❌ Не выбрано окно для отслеживания")
                Logger.shared.log("   Переключаемся в режим области экрана...")
                Config.useWindowMode = false
            }
        }
        
        // Если мы в режиме области или переключились в него
        if !Config.useWindowMode {
            Logger.shared.log("Текущий режим: отслеживание области экрана")
            
            // Проверяем выбранный экран
            if let screen = Config.selectedScreen {
                Logger.shared.log("Выбранный экран: \(screen.frame), масштаб: \(screen.backingScaleFactor)")
                
                // Проверяем область захвата
                if Config.captureRect.width > 0 && Config.captureRect.height > 0 {
                    Logger.shared.log("Область захвата: \(Config.captureRect)")
                    
                    // Попытка захвата области
                    if let capturedImage = captureScreenArea() {
                        Logger.shared.log("✅ Успешно захвачено изображение области размером \(capturedImage.width)x\(capturedImage.height)")
                        
                        // Анализируем изображение на наличие синего
                        let context = analyzeBluePixels(in: capturedImage)
                        Logger.shared.log("Найдено синих пикселей: \(context.count)/\(context.total) (\(Int(Double(context.count) / Double(context.total) * 100))%)")
                        
                        if context.count > 0 {
                            Logger.shared.log("✅ В захваченной области обнаружены синие пиксели")
                        } else {
                            Logger.shared.log("⚠️ В захваченной области не обнаружено синих пикселей")
                            Logger.shared.log("   Возможно, синий объект находится вне области отслеживания")
                        }
                    } else {
                        Logger.shared.log("❌ Не удалось захватить изображение области экрана")
                        Logger.shared.log("   Проверьте разрешения в Системных настройках → Конфиденциальность и безопасность → Запись экрана")
                    }
                } else {
                    Logger.shared.log("❌ Некорректная область захвата: \(Config.captureRect)")
                    Logger.shared.log("   Устанавливаем область захвата по центру экрана...")
                    
                    // Устанавливаем область в центре экрана
                    let screenRect = screen.frame
                    let captureWidth = screenRect.width * 0.6
                    let captureHeight = screenRect.height * 0.3
                    let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
                    let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
                    
                    Config.captureRect = CGRect(
                        x: captureX,
                        y: captureY,
                        width: captureWidth,
                        height: captureHeight
                    )
                    
                    Logger.shared.log("✅ Установлена новая область захвата: \(Config.captureRect)")
                }
            } else {
                Logger.shared.log("❌ Не выбран экран для отслеживания")
                Logger.shared.log("   Выбираем главный экран...")
                
                Config.selectedScreen = NSScreen.main
                if let screen = Config.selectedScreen {
                    Logger.shared.log("✅ Выбран главный экран: \(screen.frame)")
                } else {
                    Logger.shared.log("❌ Невозможно получить главный экран")
                }
            }
        }
        
        // Итоговый диагноз
        Logger.shared.log("Диагностика захвата экрана завершена.")
    }
    
    // Анализ синих пикселей в изображении (для диагностики)
    private func analyzeBluePixels(in image: CGImage) -> (count: Int, total: Int) {
        let width = image.width
        let height = image.height
        
        // Создаем контекст
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0, width * height)
        }
        
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        
        guard let data = context.data else {
            return (0, width * height)
        }
        
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        var bluePixelCount = 0
        
        // Шаг сканирования
        let step = Config.scanStep
        var totalPixelsChecked = 0
        
        // Сканируем изображение с заданным шагом
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let pixelIndex = (y * width + x) * 4
                totalPixelsChecked += 1
                
                if pixelIndex + 2 < width * height * 4 {
                    let red = pixelData[pixelIndex]
                    let green = pixelData[pixelIndex + 1]
                    let blue = pixelData[pixelIndex + 2]
                    
                    if blue >= Config.blueMinValue && 
                       red <= Config.redMaxValue && 
                       green <= Config.greenMaxValue &&
                       blue > red + 50 &&
                       blue > green + 50 {
                        bluePixelCount += 1
                    }
                }
            }
        }
        
        return (bluePixelCount, totalPixelsChecked)
    }
}

// Класс для настройки и управления приложением
class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var tracker: BlueEmojiTracker!
    
    // UI элементы
    private var xField: NSTextField!
    private var yField: NSTextField!
    private var widthField: NSTextField!
    private var heightField: NSTextField!
    private var blueMinField: NSTextField!
    private var redMaxField: NSTextField!
    private var greenMaxField: NSTextField!
    private var thresholdField: NSTextField!
    private var smoothingField: NSTextField!
    private var minPixelsField: NSTextField!
    private var predictionCheckbox: NSButton!
    private var statusLabel: NSTextField!
    private var startStopButton: NSButton!
    private var screenPopup: NSPopUpButton!
    private var windowPopup: NSPopUpButton!
    private var trackingModeSegment: NSSegmentedControl!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Инициализируем логгер
        _ = Logger.shared
        Logger.shared.log("Приложение запущено")
        
        // Инициализируем трекер
        tracker = BlueEmojiTracker()
        
        // Создаем окно настроек
        createWindow()
        
        // Обновляем поля ввода текущими настройками
        updateUIWithSettings()
    }
    
    private func createWindow() {
        // Определяем размеры окна
        let windowWidth: CGFloat = 450
        let windowHeight: CGFloat = 500
        
        // Рассчитываем позицию окна (по центру экрана)
        let screenRect = NSScreen.main!.frame
        let windowRect = NSRect(
            x: (screenRect.width - windowWidth) / 2,
            y: (screenRect.height - windowHeight) / 2,
            width: windowWidth,
            height: windowHeight
        )
        
        // Создаем окно
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "BlueEmojiTracker v\(Config.appVersion)"
        window.isReleasedWhenClosed = false
        
        // Создаем контейнер для элементов управления
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.contentView = contentView
        
        // Создаем элементы интерфейса
        setupUI(in: contentView)
        
        // Связываем трекер с UI элементами
        tracker.setStatusLabel(statusLabel)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    private func setupUI(in view: NSView) {
        // Создаем заголовок
        let titleLabel = NSTextField(labelWithString: "BlueEmojiTracker - Настройки")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: view.frame.height - 40, width: view.frame.width - 40, height: 20)
        view.addSubview(titleLabel)
        
        // Раздел: Область захвата
        let captureAreaLabel = NSTextField(labelWithString: "Область захвата:")
        captureAreaLabel.font = NSFont.boldSystemFont(ofSize: 14)
        captureAreaLabel.frame = NSRect(x: 20, y: view.frame.height - 80, width: view.frame.width - 40, height: 20)
        view.addSubview(captureAreaLabel)
        
        // X позиция
        let xLabel = NSTextField(labelWithString: "X:")
        xLabel.frame = NSRect(x: 20, y: view.frame.height - 110, width: 20, height: 20)
        view.addSubview(xLabel)
        
        xField = NSTextField(frame: NSRect(x: 45, y: view.frame.height - 110, width: 60, height: 22))
        xField.placeholderString = "X"
        view.addSubview(xField)
        
        // Y позиция
        let yLabel = NSTextField(labelWithString: "Y:")
        yLabel.frame = NSRect(x: 120, y: view.frame.height - 110, width: 20, height: 20)
        view.addSubview(yLabel)
        
        yField = NSTextField(frame: NSRect(x: 145, y: view.frame.height - 110, width: 60, height: 22))
        yField.placeholderString = "Y"
        view.addSubview(yField)
        
        // Ширина
        let widthLabel = NSTextField(labelWithString: "Ширина:")
        widthLabel.frame = NSRect(x: 220, y: view.frame.height - 110, width: 60, height: 20)
        view.addSubview(widthLabel)
        
        widthField = NSTextField(frame: NSRect(x: 285, y: view.frame.height - 110, width: 60, height: 22))
        widthField.placeholderString = "Ширина"
        view.addSubview(widthField)
        
        // Высота
        let heightLabel = NSTextField(labelWithString: "Высота:")
        heightLabel.frame = NSRect(x: 220, y: view.frame.height - 140, width: 60, height: 20)
        view.addSubview(heightLabel)
        
        heightField = NSTextField(frame: NSRect(x: 285, y: view.frame.height - 140, width: 60, height: 22))
        heightField.placeholderString = "Высота"
        view.addSubview(heightField)
        
        // Предустановки областей захвата
        let centerScreenButton = NSButton(frame: NSRect(x: 20, y: view.frame.height - 140, width: 180, height: 22))
        centerScreenButton.title = "По центру экрана"
        centerScreenButton.bezelStyle = .rounded
        centerScreenButton.target = self
        centerScreenButton.action = #selector(setCenterScreenArea)
        view.addSubview(centerScreenButton)
        
        // Кнопка выбора области
        let selectAreaButton = NSButton(frame: NSRect(x: 20, y: view.frame.height - 170, width: 180, height: 22))
        selectAreaButton.title = "Выбрать область мышью"
        selectAreaButton.bezelStyle = .rounded
        selectAreaButton.target = self
        selectAreaButton.action = #selector(selectAreaWithMouse)
        view.addSubview(selectAreaButton)
        
        // Выбор режима отслеживания (экран или окно)
        let trackingModeLabel = NSTextField(labelWithString: "Режим отслеживания:")
        trackingModeLabel.frame = NSRect(x: 220, y: view.frame.height - 170, width: 150, height: 20)
        view.addSubview(trackingModeLabel)
        
        trackingModeSegment = NSSegmentedControl(frame: NSRect(x: 220, y: view.frame.height - 200, width: 200, height: 24))
        trackingModeSegment.segmentCount = 2
        trackingModeSegment.setLabel("Область экрана", forSegment: 0)
        trackingModeSegment.setLabel("Окно приложения", forSegment: 1)
        trackingModeSegment.selectedSegment = Config.useWindowMode ? 1 : 0
        trackingModeSegment.target = self
        trackingModeSegment.action = #selector(trackingModeChanged)
        view.addSubview(trackingModeSegment)
        
        // Выбор экрана - добавляем tag
        let screenSelectionLabel = NSTextField(labelWithString: "Выбрать экран:")
        screenSelectionLabel.frame = NSRect(x: 20, y: view.frame.height - 230, width: 100, height: 20)
        screenSelectionLabel.tag = 101 // Добавляем тег
        view.addSubview(screenSelectionLabel)

        screenPopup = NSPopUpButton(frame: NSRect(x: 130, y: view.frame.height - 230, width: 270, height: 22))
        screenPopup.target = self
        screenPopup.action = #selector(screenSelected)
        updateScreensList()
        view.addSubview(screenPopup)
        
        // Выбор окна - добавляем tag
        let windowSelectionLabel = NSTextField(labelWithString: "Выбрать окно:")
        windowSelectionLabel.frame = NSRect(x: 20, y: view.frame.height - 260, width: 100, height: 20)
        windowSelectionLabel.tag = 102 // Добавляем тег
        view.addSubview(windowSelectionLabel)
        
        windowPopup = NSPopUpButton(frame: NSRect(x: 130, y: view.frame.height - 260, width: 270, height: 22))
        windowPopup.target = self
        windowPopup.action = #selector(windowSelected)
        updateWindowsList()
        view.addSubview(windowPopup)
        
        // Обновляем видимость элементов в зависимости от выбранного режима
        updateUIVisibility()
        
        // Раздел: Параметры определения синего цвета
        let blueParamsLabel = NSTextField(labelWithString: "Параметры определения синего цвета:")
        blueParamsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        blueParamsLabel.frame = NSRect(x: 20, y: view.frame.height - 290, width: view.frame.width - 40, height: 20)
        view.addSubview(blueParamsLabel)
        
        // Мин. синий
        let blueMinLabel = NSTextField(labelWithString: "Мин. синий (0-255):")
        blueMinLabel.frame = NSRect(x: 20, y: view.frame.height - 320, width: 120, height: 20)
        view.addSubview(blueMinLabel)
        
        blueMinField = NSTextField(frame: NSRect(x: 150, y: view.frame.height - 320, width: 60, height: 22))
        blueMinField.placeholderString = "160"
        view.addSubview(blueMinField)
        
        // Макс. красный
        let redMaxLabel = NSTextField(labelWithString: "Макс. красный (0-255):")
        redMaxLabel.frame = NSRect(x: 20, y: view.frame.height - 350, width: 120, height: 20)
        view.addSubview(redMaxLabel)
        
        redMaxField = NSTextField(frame: NSRect(x: 150, y: view.frame.height - 350, width: 60, height: 22))
        redMaxField.placeholderString = "120"
        view.addSubview(redMaxField)
        
        // Макс. зеленый
        let greenMaxLabel = NSTextField(labelWithString: "Макс. зеленый (0-255):")
        greenMaxLabel.frame = NSRect(x: 230, y: view.frame.height - 350, width: 120, height: 20)
        view.addSubview(greenMaxLabel)
        
        greenMaxField = NSTextField(frame: NSRect(x: 360, y: view.frame.height - 350, width: 60, height: 22))
        greenMaxField.placeholderString = "130"
        view.addSubview(greenMaxField)
        
        // Раздел: Параметры движения курсора
        let movementParamsLabel = NSTextField(labelWithString: "Параметры движения курсора:")
        movementParamsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        movementParamsLabel.frame = NSRect(x: 20, y: view.frame.height - 380, width: view.frame.width - 40, height: 20)
        view.addSubview(movementParamsLabel)
        
        // Порог движения
        let thresholdLabel = NSTextField(labelWithString: "Порог движения:")
        thresholdLabel.frame = NSRect(x: 20, y: view.frame.height - 410, width: 120, height: 20)
        view.addSubview(thresholdLabel)
        
        thresholdField = NSTextField(frame: NSRect(x: 150, y: view.frame.height - 410, width: 60, height: 22))
        thresholdField.placeholderString = "5.0"
        view.addSubview(thresholdField)
        
        // Сглаживание
        let smoothingLabel = NSTextField(labelWithString: "Сглаживание (0.1-0.9):")
        smoothingLabel.frame = NSRect(x: 230, y: view.frame.height - 410, width: 120, height: 20)
        view.addSubview(smoothingLabel)
        
        smoothingField = NSTextField(frame: NSRect(x: 360, y: view.frame.height - 410, width: 60, height: 22))
        smoothingField.placeholderString = "0.5"
        view.addSubview(smoothingField)
        
        // Мин. кол-во пикселей
        let minPixelsLabel = NSTextField(labelWithString: "Мин. кол-во пикселей:")
        minPixelsLabel.frame = NSRect(x: 20, y: view.frame.height - 440, width: 120, height: 20)
        view.addSubview(minPixelsLabel)
        
        minPixelsField = NSTextField(frame: NSRect(x: 150, y: view.frame.height - 440, width: 60, height: 22))
        minPixelsField.placeholderString = "5"
        view.addSubview(minPixelsField)
        
        // Прогнозирование движения
        predictionCheckbox = NSButton(checkboxWithTitle: "Использовать прогнозирование движения", target: self, action: #selector(toggleMotionPrediction))
        predictionCheckbox.frame = NSRect(x: 230, y: view.frame.height - 440, width: 210, height: 22)
        predictionCheckbox.state = Config.useMotionPrediction ? .on : .off
        view.addSubview(predictionCheckbox)
        
        // Добавляем кнопку для сброса настроек
        let resetButton = NSButton(frame: NSRect(x: 20, y: 30, width: 140, height: 28))
        resetButton.title = "Сбросить настройки"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetSettingsAction)
        view.addSubview(resetButton)
        
        // Кнопка применения настроек и сохранения
        let applyButton = NSButton(frame: NSRect(x: view.frame.width/2 - 70, y: 30, width: 140, height: 28))
        applyButton.title = "Применить"
        applyButton.bezelStyle = .rounded
        applyButton.target = self
        applyButton.action = #selector(applySettings)
        view.addSubview(applyButton)
        
        let saveButton = NSButton(frame: NSRect(x: view.frame.width - 160, y: 30, width: 140, height: 28))
        saveButton.title = "Сохранить настройки"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveSettings)
        view.addSubview(saveButton)
        
        // Разделитель перемещаем
        let separator = NSBox(frame: NSRect(x: 20, y: 70, width: view.frame.width - 40, height: 1))
        separator.boxType = .separator
        view.addSubview(separator)
        
        // Статус отслеживания
        statusLabel = NSTextField(labelWithString: "Статус: Ожидание")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 20, y: 80, width: view.frame.width - 40, height: 20)
        view.addSubview(statusLabel)
        
        // Кнопка запуска/остановки отслеживания
        startStopButton = NSButton(frame: NSRect(x: view.frame.width/2 - 100, y: 110, width: 200, height: 28))
        startStopButton.title = "Начать отслеживание"
        startStopButton.bezelStyle = .rounded
        startStopButton.target = self
        startStopButton.action = #selector(toggleTracking)
        view.addSubview(startStopButton)
        
        // Добавим новую кнопку в setupUI
        let logButton = NSButton(frame: NSRect(x: view.frame.width - 140, y: view.frame.height - 40, width: 120, height: 22))
        logButton.title = "Показать логи"
        logButton.bezelStyle = .rounded
        logButton.target = self
        logButton.action = #selector(showLogFile)
        view.addSubview(logButton)
    }
    
    @objc private func setCenterScreenArea() {
        // Используем выбранный экран вместо main
        let screen = Config.selectedScreen ?? NSScreen.main!
        let screenRect = screen.frame
        
        // Устанавливаем область в центре экрана
        let captureWidth = screenRect.width * 0.6
        let captureHeight = screenRect.height * 0.3
        let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
        let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
        
        Config.captureRect = CGRect(
            x: captureX,
            y: captureY,
            width: captureWidth,
            height: captureHeight
        )
        
        // Обновляем поля ввода
        updateUIWithSettings()
    }
    
    @objc private func selectAreaWithMouse() {
        let selectionWindow = AreaSelectionWindow { [weak self] rect in
            // Устанавливаем выбранную область
            Config.captureRect = rect
            
            // Обновляем поля ввода
            self?.updateUIWithSettings()
        }
        
        // Показываем окно выбора области
        selectionWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func showCaptureArea() {
        tracker.showCaptureArea()
    }
    
    @objc private func applySettings() {
        // Получаем значения из полей ввода
        if let x = Double(xField.stringValue),
           let y = Double(yField.stringValue),
           let width = Double(widthField.stringValue),
           let height = Double(heightField.stringValue) {
            
            // Проверяем корректность значений
            if width > 0 && height > 0 {
                Config.captureRect = CGRect(x: x, y: y, width: width, height: height)
            }
        }
        
        // Обновляем параметры цвета
        if let blueMin = UInt8(blueMinField.stringValue) {
            Config.blueMinValue = blueMin
        }
        
        if let redMax = UInt8(redMaxField.stringValue) {
            Config.redMaxValue = redMax
        }
        
        if let greenMax = UInt8(greenMaxField.stringValue) {
            Config.greenMaxValue = greenMax
        }
        
        // Обновляем параметры движения
        if let threshold = Double(thresholdField.stringValue) {
            Config.movementThreshold = CGFloat(threshold)
        }
        
        if let smoothing = Double(smoothingField.stringValue) {
            Config.smoothingFactor = CGFloat(min(max(smoothing, 0.1), 0.9))
        }
        
        if let minPixels = Int(minPixelsField.stringValue) {
            Config.minBluePixels = minPixels
        }
        
        // Обновляем настройку прогнозирования движения
        Config.useMotionPrediction = (predictionCheckbox.state == .on)
        
        // Спрашиваем, хочет ли пользователь сохранить настройки
        let alert = NSAlert()
        alert.messageText = "Настройки применены"
        alert.informativeText = "Хотите сохранить настройки для будущих запусков?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Да")
        alert.addButton(withTitle: "Нет")
        
        if alert.runModal() == .alertFirstButtonReturn {
            saveSettings()
        }
    }
    
    @objc private func saveSettings() {
        Config.saveSettings()
        
        // Уведомляем пользователя о сохранении
        let alert = NSAlert()
        alert.messageText = "Настройки сохранены"
        alert.informativeText = "Ваши настройки будут загружены при следующем запуске приложения."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func toggleTracking() {
        if tracker.isTracking {
            tracker.stopTracking()
            startStopButton.title = "Начать отслеживание"
        } else {
            // Добавляем диагностику перед запуском отслеживания
            tracker.diagnoseScreenCapture()
            
            // Запускаем отслеживание
            tracker.startTracking()
            startStopButton.title = "Остановить отслеживание"
        }
    }
    
    @objc private func toggleMotionPrediction() {
        Config.useMotionPrediction.toggle()
        updateUIWithSettings()
    }
    
    // Обновление полей ввода текущими настройками
    private func updateUIWithSettings() {
        // Область захвата
        xField.stringValue = String(format: "%.1f", Config.captureRect.origin.x)
        yField.stringValue = String(format: "%.1f", Config.captureRect.origin.y)
        widthField.stringValue = String(format: "%.1f", Config.captureRect.width)
        heightField.stringValue = String(format: "%.1f", Config.captureRect.height)
        
        // Параметры цвета
        blueMinField.stringValue = "\(Config.blueMinValue)"
        redMaxField.stringValue = "\(Config.redMaxValue)"
        greenMaxField.stringValue = "\(Config.greenMaxValue)"
        
        // Параметры движения
        thresholdField.stringValue = String(format: "%.1f", Config.movementThreshold)
        smoothingField.stringValue = String(format: "%.1f", Config.smoothingFactor)
        minPixelsField.stringValue = "\(Config.minBluePixels)"
        
        // Прогнозирование движения
        predictionCheckbox.state = Config.useMotionPrediction ? .on : .off
    }
    
    private func updateScreensList() {
        screenPopup.removeAllItems()
        
        for (index, screen) in NSScreen.screens.enumerated() {
            // Получаем размеры экрана
            let rect = screen.frame
            
            // Формируем название экрана
            let title = "Экран \(index + 1): \(Int(rect.width))x\(Int(rect.height))"
            
            screenPopup.addItem(withTitle: title)
            
            // Если это выбранный экран, выбираем его в меню
            if screen == Config.selectedScreen {
                screenPopup.selectItem(at: index)
            }
        }
        
        // Если нет выбранного экрана, выбираем первый в списке
        if Config.selectedScreen == nil && !NSScreen.screens.isEmpty {
            Config.selectedScreen = NSScreen.screens[0]
            screenPopup.selectItem(at: 0)
        }
    }
    
    @objc private func screenSelected() {
        let selectedIndex = screenPopup.indexOfSelectedItem
        
        if selectedIndex >= 0 && selectedIndex < NSScreen.screens.count {
            Config.selectedScreen = NSScreen.screens[selectedIndex]
            
            // Обновляем область захвата для выбранного экрана
            let screen = Config.selectedScreen!
            let screenRect = screen.frame
            
            // Устанавливаем область в центре экрана
            let captureWidth = screenRect.width * 0.6
            let captureHeight = screenRect.height * 0.3
            let captureX = screenRect.origin.x + (screenRect.width - captureWidth) / 2
            let captureY = screenRect.origin.y + (screenRect.height - captureHeight) / 2
            
            Config.captureRect = CGRect(
                x: captureX,
                y: captureY,
                width: captureWidth,
                height: captureHeight
            )
            
            // Обновляем поля ввода
            updateUIWithSettings()
        }
    }
    
    // Обновление списка доступных окон
    private func updateWindowsList() {
        windowPopup.removeAllItems()
        
        let windows = WindowManager.getActiveWindows()
        
        for (index, window) in windows.enumerated() {
            windowPopup.addItem(withTitle: window.displayName)
            
            // Если это выбранное окно, выбираем его в меню
            if let selectedID = Config.selectedWindowID, window.windowID == selectedID {
                windowPopup.selectItem(at: index)
            }
        }
        
        // Если нет выбранного окна, выбираем первое в списке
        if Config.selectedWindowID == nil && !windows.isEmpty {
            let firstWindow = windows.first!
            Config.selectedWindowID = firstWindow.windowID
            Config.selectedWindowName = firstWindow.displayName
            windowPopup.selectItem(at: 0)
        }
    }
    
    // Обработчик выбора окна
    @objc private func windowSelected() {
        let selectedIndex = windowPopup.indexOfSelectedItem
        let windows = WindowManager.getActiveWindows()
        
        if selectedIndex >= 0 && selectedIndex < windows.count {
            let selectedWindow = windows[selectedIndex]
            Config.selectedWindowID = selectedWindow.windowID
            Config.selectedWindowName = selectedWindow.displayName
            
            print("Выбрано окно: \(selectedWindow.displayName) с ID: \(selectedWindow.windowID)")
        }
    }
    
    // Обработчик изменения режима отслеживания
    @objc private func trackingModeChanged() {
        Config.useWindowMode = trackingModeSegment.selectedSegment == 1
        updateUIVisibility()
        
        // Обновляем списки, если необходимо
        if Config.useWindowMode {
            updateWindowsList()
        } else {
            updateScreensList()
        }
    }
    
    // Обновление видимости элементов интерфейса в зависимости от режима
    private func updateUIVisibility() {
        guard let contentView = window.contentView else { return }
        
        // Отображаем/скрываем элементы для выбора экрана
        screenPopup.isHidden = Config.useWindowMode
        contentView.viewWithTag(101)?.isHidden = Config.useWindowMode  // Tag для screenSelectionLabel
        
        // Отображаем/скрываем элементы для выбора окна
        windowPopup.isHidden = !Config.useWindowMode
        contentView.viewWithTag(102)?.isHidden = !Config.useWindowMode  // Tag для windowSelectionLabel
        
        // Если активен режим окна, скрываем элементы для выбора области экрана
        xField.isEnabled = !Config.useWindowMode
        yField.isEnabled = !Config.useWindowMode
        widthField.isEnabled = !Config.useWindowMode
        heightField.isEnabled = !Config.useWindowMode
    }
    
    // Добавим метод для открытия лог-файла
    @objc private func showLogFile() {
        // Получаем путь к лог-файлу
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsDirectory.appendingPathComponent("BlueEmojiTracker_log.txt")
        
        
        // Открываем лог-файл в Finder
        NSWorkspace.shared.selectFile(logFileURL.path, inFileViewerRootedAtPath: documentsDirectory.path)
        
        // Показываем путь к файлу
        let alert = NSAlert()
        alert.messageText = "Расположение лог-файла"
        alert.informativeText = "Лог-файл находится по пути:\n\(logFileURL.path)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Дополнительные методы для AppDelegate
    @objc private func resetSettingsAction() {
        // Показываем предупреждение
        let alert = NSAlert()
        alert.messageText = "Сбросить настройки"
        alert.informativeText = "Вы уверены, что хотите сбросить все настройки до значений по умолчанию? Этот процесс нельзя отменить."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Сбросить")
        alert.addButton(withTitle: "Отмена")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Сбрасываем настройки
            Config.resetSettings()
            
            // Обновляем интерфейс
            updateUIWithSettings()
            updateScreensList()
            updateWindowsList()
            updateUIVisibility()
            
            // Информируем пользователя
            let confirmationAlert = NSAlert()
            confirmationAlert.messageText = "Настройки сброшены"
            confirmationAlert.informativeText = "Все настройки были сброшены до значений по умолчанию."
            confirmationAlert.alertStyle = .informational
            confirmationAlert.addButton(withTitle: "OK")
            confirmationAlert.runModal()
            
            // Запускаем диагностику
            if !tracker.isTracking {
                tracker.diagnoseScreenCapture()
            }
        }
    }
}

// Класс для выбора области экрана мышью
class AreaSelectionWindow: NSWindow {
    private var initialPoint: NSPoint?
    private var completion: ((CGRect) -> Void)?
    
    init(completion: @escaping (CGRect) -> Void) {
        // Создаем окно на весь экран
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        super.init(
            contentRect: screenRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.completion = completion
        self.level = .floating
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = NSColor.blue.withAlphaComponent(0.1)
        
        // Создаем view для обработки мыши
        let contentView = SelectionView(frame: screenRect)
        self.contentView = contentView
    }
    
    func handleMouseDown(at point: NSPoint) {
        initialPoint = point
    }
    
    func handleMouseDragged(to point: NSPoint) {
        guard let initialPoint = initialPoint else { return }
        
        // Вычисляем прямоугольник выделения
        let minX = min(initialPoint.x, point.x)
        let minY = min(initialPoint.y, point.y)
        let width = abs(initialPoint.x - point.x)
        let height = abs(initialPoint.y - point.y)
        
        // Обновляем фрейм для подсветки
        if let contentView = contentView as? SelectionView {
            contentView.updateSelectionRect(NSRect(x: minX, y: minY, width: width, height: height))
        }
    }
    
    func handleMouseUp(at point: NSPoint) {
        guard let initialPoint = initialPoint else { 
            self.close()
            return 
        }
        
        // Вычисляем выбранную область
        let minX = min(initialPoint.x, point.x)
        let minY = min(initialPoint.y, point.y)
        let width = abs(initialPoint.x - point.x)
        let height = abs(initialPoint.y - point.y)
        
        // Используем только если размер достаточно большой
        if width > 10 && height > 10 {
            let selectedRect = CGRect(x: minX, y: minY, width: width, height: height)
            completion?(selectedRect)
        }
        
        // Закрываем окно
        self.close()
    }
}

// View для отображения выбора области
class SelectionView: NSView {
    private var selectionRect: NSRect?
    
    func updateSelectionRect(_ rect: NSRect) {
        selectionRect = rect
        self.needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        (self.window as? AreaSelectionWindow)?.handleMouseDown(at: point)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        (self.window as? AreaSelectionWindow)?.handleMouseDragged(to: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        (self.window as? AreaSelectionWindow)?.handleMouseUp(at: point)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let selectionRect = selectionRect {
            NSColor.white.setStroke()
            let path = NSBezierPath(rect: selectionRect)
            path.lineWidth = 2
            path.stroke()
            
            NSColor.blue.withAlphaComponent(0.3).setFill()
            path.fill()
        }
    }
}

// Добавляем класс для работы с окнами
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
    
    // Получить список всех активных окон
    static func getActiveWindows() -> [WindowInfo] {
        var windowList = [WindowInfo]()
        
        // Получаем список всех окон
        let windowsListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray?
        
        guard let windows = windowsListInfo else { return windowList }
        
        // Перебираем все окна и формируем список
        for windowInfo in windows {
            guard let info = windowInfo as? NSDictionary else { continue }
            
            // Пропускаем системные окна и окна без имени
            guard let ownerName = info[kCGWindowOwnerName as String] as? String,
                  ownerName != "Window Server" else { continue }
            
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                  let name = info[kCGWindowName as String] as? String,
                  !name.isEmpty else { continue }
            
            // Преобразуем границы окна из словаря в CGRect
            let x = bounds["X"] as? CGFloat ?? 0
            let y = bounds["Y"] as? CGFloat ?? 0
            let width = bounds["Width"] as? CGFloat ?? 0
            let height = bounds["Height"] as? CGFloat ?? 0
            let windowBounds = CGRect(x: x, y: y, width: width, height: height)
            
            // Добавляем окно в список, если его размеры достаточны
            if width > 50 && height > 50 {
                let window = WindowInfo(
                    windowID: windowID,
                    name: name,
                    ownerName: ownerName,
                    bounds: windowBounds
                )
                windowList.append(window)
            }
        }
        
        return windowList
    }
    
    // Проверить, существует ли окно с заданным ID
    static func isWindowAvailable(windowID: CGWindowID) -> Bool {
        let windows = getActiveWindows()
        return windows.contains { $0.windowID == windowID }
    }
    
    // Получить информацию о конкретном окне
    static func getWindowInfo(windowID: CGWindowID) -> WindowInfo? {
        let windowInfo = getActiveWindows().first { $0.windowID == windowID }
        if let info = windowInfo {
            Logger.shared.log("Получена информация об окне \(info.displayName) (ID: \(info.windowID)). Границы: \(info.bounds)")
        } else {
            Logger.shared.log("Не найдена информация об окне с ID: \(windowID)")
        }
        return windowInfo
    }
}

// Добавляем сразу после импортов
// Система для логирования
class Logger {
    static let shared = Logger()
    private var logFile: FileHandle?
    private let dateFormatter = DateFormatter()
    private let queue = DispatchQueue(label: "com.blueemojitracker.logger")
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Создаем путь к файлу логов
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Не удалось получить директорию документов")
            return
        }
        
        let logFileURL = documentsDirectory.appendingPathComponent("BlueEmojiTracker_log.txt")
        print("Логи будут сохранены в: \(logFileURL.path)")
        
        // Создаем или очищаем файл логов
        fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        
        do {
            logFile = try FileHandle(forWritingTo: logFileURL)
            log("Logger инициализирован. Версия приложения: \(Config.appVersion)")
        } catch {
            print("Ошибка открытия файла для логирования: \(error)")
        }
    }
    
    deinit {
        logFile?.closeFile()
    }
    
    func log(_ message: String, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fullMessage = "[\(timestamp)] [\(function):\(line)] \(message)\n"
        
        // Выводим в консоль
        print(fullMessage, terminator: "")
        
        // Записываем в файл асинхронно
        queue.async { [weak self] in
            guard let self = self, let logFile = self.logFile else { return }
            if let data = fullMessage.data(using: .utf8) {
                logFile.write(data)
                try? logFile.synchronize()
            }
        }
    }
}

// Основная точка входа
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
