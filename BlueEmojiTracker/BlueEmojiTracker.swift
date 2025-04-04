import Cocoa
import simd

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
            return nil
        }
        
        // Создаем копию области захвата для использования внутри метода
        let captureArea = Config.captureRect
        
        // Получаем выбранный экран
        guard let selectedScreen = Config.selectedScreen else {
            print("⚠️ Не выбран экран для захвата")
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
        
        // Захватываем часть экрана
        let image = CGWindowListCreateImage(
            flippedRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        
        if image == nil {
            print("⚠️ Не удалось захватить изображение экрана")
        }
        
        return image
    }
    
    // Оптимизированный алгоритм поиска синего объекта
    private func findBlueObject(in image: CGImage) -> CGPoint? {
        // Используем vImage для быстрой обработки изображения
        guard let context = createOptimizedContext(for: image) else { return nil }
        
        // Используем SIMD для параллельных вычислений
        return findBlueObjectUsingSimd(context: context, image: image)
    }
    
    private func createOptimizedContext(for image: CGImage) -> CGContext? {
        // Оптимизированное создание контекста
        let width = image.width
        let height = image.height
        
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        return CGContext(data: nil,
                        width: width,
                        height: height,
                        bitsPerComponent: bitsPerComponent,
                        bytesPerRow: bytesPerRow,
                        space: colorSpace,
                        bitmapInfo: bitmapInfo)
    }
    
    private func findBlueObjectUsingSimd(context: CGContext, image: CGImage) -> CGPoint? {
        guard let data = context.data else { return nil }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        let width = image.width
        let height = image.height
        
        // Use SIMD vectors for parallel processing
        let step = Config.scanStep
        let pixelsPerChunk = 16 // Process 16 pixels at once using SIMD
        
        var totalBlueX: Float = 0
        var totalBlueY: Float = 0
        var bluePixelCount = 0
        var maxBlueValue: UInt8 = 0
        var maxBluePos = CGPoint.zero
        
        // Process image in chunks using SIMD
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width - pixelsPerChunk, by: pixelsPerChunk) {
                var blueValues = SIMD16<UInt8>()
                var redValues = SIMD16<UInt8>()
                var greenValues = SIMD16<UInt8>()
                
                // Load pixel data into SIMD vectors
                for i in 0..<pixelsPerChunk {
                    let pixelIndex = ((y * width) + x + i) * 4
                    redValues[i] = pixelData[pixelIndex]
                    greenValues[i] = pixelData[pixelIndex + 1]
                    blueValues[i] = pixelData[pixelIndex + 2]
                }
                
                // Apply color thresholds using SIMD operations
                let blueMask = blueValues .>= Config.blueMinValue
                let redMask = redValues .<= Config.redMaxValue
                let greenMask = greenValues .<= Config.greenMaxValue
                let matches = blueMask .& redMask .& greenMask
                
                // Process matching pixels
                for i in 0..<pixelsPerChunk where matches[i] {
                    let px = x + i
                    totalBlueX += Float(px)
                    totalBlueY += Float(y)
                    bluePixelCount += 1
                    
                    if blueValues[i] > maxBlueValue {
                        maxBlueValue = blueValues[i]
                        maxBluePos = CGPoint(x: px, y: y)
                    }
                }
            }
        }
        
        return processBlueObjectResults(
            totalBlueX: totalBlueX,
            totalBlueY: totalBlueY, 
            bluePixelCount: bluePixelCount,
            maxBlueValue: maxBlueValue,
            maxBluePos: maxBluePos,
            imageWidth: width,
            imageHeight: height
        )
    }
    
    private func processBlueObjectResults(
        totalBlueX: Float,
        totalBlueY: Float,
        bluePixelCount: Int,
        maxBlueValue: UInt8,
        maxBluePos: CGPoint,
        imageWidth: Int,
        imageHeight: Int
    ) -> CGPoint? {
        // Обработка результатов поиска синего объекта
        guard bluePixelCount > 0 else { return nil }
        
        let averageX = totalBlueX / Float(bluePixelCount)
        let averageY = totalBlueY / Float(bluePixelCount)
        
        let normalizedX = averageX / Float(imageWidth)
        let normalizedY = averageY / Float(imageHeight)
        
        print("Найден синий объект. Средняя позиция: (\(averageX), \(averageY)), Нормализованная позиция: (\(normalizedX), \(normalizedY))")
        
        return CGPoint(x: averageX, y: averageY)
    }
}