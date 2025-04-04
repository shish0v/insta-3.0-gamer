import Cocoa
import simd

class BlueEmojiTracker {
    // Состояние отслеживания
    public private(set) var isRunning = false
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
        
        Logger.shared.log("Область отслеживания: \(Config.captureRect)")
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
            let windowBounds = windowInfo.bounds
            
            // Логируем несоответствие размеров, если оно есть
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
            let expectedWidth = windowBounds.width * scaleFactor
            let expectedHeight = windowBounds.height * scaleFactor
            
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
    
    // Метод захвата области экрана
    private func captureScreenArea() -> CGImage? {
        // Проверяем, что область захвата корректна
        guard Config.captureRect.width > 0 && Config.captureRect.height > 0 else {
            Logger.shared.log("⚠️ Некорректные размеры области захвата")
            return nil
        }
        
        // Создаем копию области захвата для использования внутри метода
        let captureArea = Config.captureRect
        
        // Получаем выбранный экран
        guard let selectedScreen = Config.selectedScreen else {
            Logger.shared.log("⚠️ Не выбран экран для захвата")
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
            Logger.shared.log("⚠️ Не удалось захватить изображение экрана")
        }
        
        return image
    }
    
    // Оптимизированный алгоритм поиска синего объекта
    private func findBlueObject(in image: CGImage) -> CGPoint? {
        // Создаем контекст для быстрой обработки изображения
        guard let context = createOptimizedContext(for: image),
              let data = context.data else {
            return nil
        }
        
        let width = image.width
        let height = image.height
        let bytesPerRow = context.bytesPerRow
        let bytesPerPixel = 4
        
        var blueSum = 0
        var xSum: Int = 0
        var ySum: Int = 0
        var bluePixelCount = 0
        
        // Преобразуем указатель на данные в массив байтов
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        // Шаг сканирования (для оптимизации)
        let scanStep = Config.scanStep
        
        // Сканируем изображение с заданным шагом
        for y in stride(from: 0, to: height, by: scanStep) {
            for x in stride(from: 0, to: width, by: scanStep) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                
                // Получаем компоненты цвета
                let blue = buffer[offset]
                let green = buffer[offset + 1]
                let red = buffer[offset + 2]
                
                // Проверяем, соответствует ли пиксель критериям "синего"
                // blue > threshold && red < maxRed && green < maxGreen
                if blue >= Config.blueMinValue && red <= Config.redMaxValue && green <= Config.greenMaxValue {
                    xSum += Int(x)
                    ySum += Int(y)
                    blueSum += Int(blue)
                    bluePixelCount += 1
                }
            }
        }
        
        // Если нашли достаточное количество синих пикселей
        if bluePixelCount >= Config.minBluePixels {
            // Вычисляем средние координаты синего объекта
            let avgX = CGFloat(xSum) / CGFloat(bluePixelCount)
            let avgY = CGFloat(ySum) / CGFloat(bluePixelCount)
            
            // Учет адаптивной чувствительности
            adaptiveSensitivity = min(1.0, max(0.1, CGFloat(bluePixelCount) / 100.0))
            
            return CGPoint(x: avgX, y: avgY)
        } else {
            // Если не нашли достаточное количество синих пикселей
            return nil
        }
    }
    
    private func createOptimizedContext(for image: CGImage) -> CGContext? {
        // Оптимизированное создание контекста
        let width = image.width
        let height = image.height
        
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        let context = CGContext(data: nil,
                              width: width,
                              height: height,
                              bitsPerComponent: bitsPerComponent,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo)
        
        // Отрисовываем изображение в контекст
        if let context = context {
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(image, in: rect)
        }
        
        return context
    }
    
    // Преобразование координат изображения в координаты экрана
    private func imageToScreenCoordinates(point: CGPoint, imageSize: CGSize) -> CGPoint {
        if Config.useWindowMode {
            // В режиме окна используем границы окна для преобразования
            guard let windowBounds = Config.currentWindowBounds else {
                return point
            }
            
            let scaleX = Config.customScaleX ?? 1.0
            let scaleY = Config.customScaleY ?? 1.0
            
            // Нормализуем координаты изображения и преобразуем их в координаты окна
            let normalizedX = point.x / scaleX
            let normalizedY = point.y / scaleY
            
            // Возвращаем абсолютные координаты экрана
            return CGPoint(
                x: windowBounds.origin.x + normalizedX,
                y: windowBounds.origin.y + normalizedY
            )
        } else {
            // В режиме области экрана просто добавляем смещение области захвата
            return CGPoint(
                x: Config.captureRect.origin.x + point.x,
                y: Config.captureRect.origin.y + point.y
            )
        }
    }
    
    // Обновление положения курсора с учетом сглаживания движения
    private func updateCursorPosition(_ point: CGPoint?) {
        guard let targetPoint = point else {
            // Если синий объект не найден, увеличиваем счетчик
            consecutiveNoMoveCount += 1
            
            // Если долго нет объекта, сбрасываем скорость
            if consecutiveNoMoveCount > 5 {
                velocityX = 0
                velocityY = 0
            }
            return
        }
        
        // Сбрасываем счетчик, так как нашли объект
        consecutiveNoMoveCount = 0
        
        // Получаем текущее положение курсора
        let currentPosition = NSEvent.mouseLocation
        
        // Сглаживание и стабилизация движения
        let smoothingFactor = Config.smoothingFactor
        let movementThreshold = Config.movementThreshold
        
        // Преобразуем координаты из изображения в координаты экрана
        let imageSize = CGSize(width: Config.captureRect.width, height: Config.captureRect.height)
        let screenPoint = imageToScreenCoordinates(point: targetPoint, imageSize: imageSize)
        
        // Рассчитываем разницу между текущими и целевыми координатами
        let deltaX = screenPoint.x - currentPosition.x
        let deltaY = screenPoint.y - currentPosition.y
        
        // Применяем порог движения для устранения дрожания
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        if distance < movementThreshold {
            return
        }
        
        // Расчет скорости движения
        let now = Date()
        let elapsed = now.timeIntervalSince(lastMoveTime)
        
        // Обновляем значения скорости
        if elapsed > 0 {
            let newVelocityX = deltaX / CGFloat(elapsed)
            let newVelocityY = deltaY / CGFloat(elapsed)
            
            velocityX = velocityX * 0.7 + newVelocityX * 0.3
            velocityY = velocityY * 0.7 + newVelocityY * 0.3
        }
        
        lastMoveTime = now
        
        // Рассчитываем новое положение с учетом сглаживания
        let newX = currentPosition.x + deltaX * smoothingFactor * adaptiveSensitivity
        let newY = currentPosition.y + deltaY * smoothingFactor * adaptiveSensitivity
        
        // Применяем прогнозирование движения, если включено
        var finalX = newX
        var finalY = newY
        
        if Config.useMotionPrediction && elapsed > 0 {
            // Прогнозируем положение на основе скорости
            let predictionFactor: CGFloat = 0.1
            finalX += velocityX * predictionFactor
            finalY += velocityY * predictionFactor
        }
        
        // Добавляем новую позицию в историю
        lastPositions.append(CGPoint(x: finalX, y: finalY))
        if lastPositions.count > positionsHistorySize {
            lastPositions.removeFirst()
        }
        
        // Перемещаем курсор
        let point = CGPoint(x: finalX, y: finalY)
        moveCursor(to: point)
        
        lastPosition = point
    }
    
    // Перемещение курсора
    private func moveCursor(to point: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)
        event?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Публичные методы
    
    // Запуск отслеживания
    func startTracking() {
        guard !isRunning else { return }
        
        isRunning = true
        Logger.shared.log("Запуск отслеживания")
        
        // Таймер для обновления каждые 1/30 секунды
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.update()
        }
        
        // Запускаем периодическую проверку экрана (для окон)
        startScreenChecking()
    }
    
    // Остановка отслеживания
    func stopTracking() {
        guard isRunning else { return }
        
        isRunning = false
        Logger.shared.log("Остановка отслеживания")
        
        timer?.invalidate()
        timer = nil
        
        stopScreenChecking()
    }
    
    // Основной метод обновления
    private func update() {
        // Захватываем изображение экрана
        guard let image = captureScreen() else {
            Logger.shared.log("Не удалось захватить экран")
            return
        }
        
        // Ищем синий объект
        let blueObjectPosition = findBlueObject(in: image)
        
        // Обновляем положение курсора
        updateCursorPosition(blueObjectPosition)
    }
    
    // Методы для периодической проверки экрана
    private func startScreenChecking() {
        screenCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkScreenState()
        }
    }
    
    private func stopScreenChecking() {
        screenCheckTimer?.invalidate()
        screenCheckTimer = nil
    }
    
    private func checkScreenState() {
        // Проверяем доступность окна, если используем режим окна
        if Config.useWindowMode, let windowID = Config.selectedWindowID {
            let isAvailable = WindowManager.isWindowAvailable(windowID: windowID)
            if !isAvailable {
                Logger.shared.log("⚠️ Окно больше не доступно: \(windowID)")
            }
        }
    }
} 