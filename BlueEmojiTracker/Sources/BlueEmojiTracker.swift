import Cocoa
import Numerics

/// Основной класс трекера синего эмодзи
class BlueEmojiTracker {
    // MARK: - Свойства
    private var trackingTimer: Timer?
    private var windowImage: CGImage?
    private var windowBounds: CGRect = .zero
    private var bluePosition: CGPoint = .zero
    private var blueSize: CGSize = .zero
    
    // Для отслеживания траектории мяча
    private var positionHistory: [CGPoint] = []
    private var velocityVector: CGVector = .zero
    private var lastFrameTime: Date?
    
    // Для игрового режима
    private var platformPosition: CGPoint = .zero
    private var platformWidth: CGFloat = 0
    private var predictedLandingPoint: CGPoint?
    private var predictedTrajectory: [CGPoint] = []
    
    // Флаг, указывающий, активно ли отслеживание
    private(set) var isTracking = false
    
    // MARK: - Публичные методы
    
    /// Запускает отслеживание синего объекта
    func startTracking() {
        guard !isTracking else { return }
        
        Logger.shared.log("Запуск отслеживания")
        
        // Сбрасываем предыдущие данные
        positionHistory.removeAll()
        velocityVector = .zero
        lastFrameTime = nil
        
        // Создаем таймер для регулярного захвата экрана
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.processFrame()
        }
        
        isTracking = true
    }
    
    /// Останавливает отслеживание синего объекта
    func stopTracking() {
        guard isTracking else { return }
        
        Logger.shared.log("Остановка отслеживания")
        
        // Останавливаем таймер
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        isTracking = false
    }
    
    /// Возвращает текущую траекторию движения мяча
    func getBallTrajectory() -> [CGPoint] {
        return positionHistory
    }
    
    /// Возвращает предсказанную траекторию движения мяча
    func getPredictedTrajectory() -> [CGPoint] {
        return predictedTrajectory
    }
    
    /// Возвращает предсказанную точку приземления мяча
    func getPredictedLandingPoint() -> CGPoint? {
        return predictedLandingPoint
    }
    
    /// Возвращает текущее положение мяча
    func getBallPosition() -> CGPoint {
        return bluePosition
    }
    
    /// Возвращает информацию о платформе
    func getPaddleInfo() -> (position: CGPoint, width: CGFloat) {
        return (platformPosition, platformWidth)
    }
    
    // MARK: - Методы для обработки кадров
    
    /// Основной метод обработки кадра
    private func processFrame() {
        // Захватываем изображение экрана или окна
        captureWindow()
        
        guard let capturedImage = windowImage else {
            Logger.shared.log("Ошибка: не удалось захватить изображение")
            return
        }
        
        // Текущее время для расчета скорости
        let currentTime = Date()
        
        // Обнаруживаем синий объект (мяч)
        detectBlueObject(in: capturedImage)
        
        // Если обнаружен синий объект, обрабатываем его
        if blueSize.width > 0 && blueSize.height > 0 {
            // Вычисляем центр объекта
            let objectCenter = CGPoint(
                x: bluePosition.x + blueSize.width / 2,
                y: bluePosition.y + blueSize.height / 2
            )
            
            // Добавляем позицию в историю
            updatePositionHistory(with: objectCenter)
            
            // Вычисляем скорость, только если у нас есть предыдущее время
            if let lastTime = lastFrameTime {
                let deltaTime = currentTime.timeIntervalSince(lastTime)
                calculateVelocity(currentPosition: objectCenter, deltaTime: deltaTime)
            }
            
            // Если включен игровой режим, выполняем соответствующие действия
            if Config.isGameModeEnabled {
                // Предсказываем траекторию движения мяча
                if Config.useMotionPrediction {
                    predictTrajectory()
                }
                
                // Получаем информацию о платформе из нижней части экрана
                detectPlatform()
                
                // Перемещаем курсор для отбивания мяча
                moveCursorToInterceptBall()
            } else {
                // В обычном режиме просто перемещаем курсор к позиции синего объекта
                moveCursorToBlueObject()
            }
        }
        
        // Обновляем время последнего кадра
        lastFrameTime = currentTime
    }
    
    /// Захватывает изображение экрана или окна для анализа
    private func captureWindow() {
        if Config.useWindowMode {
            // Захват конкретного окна
            if let windowID = Config.selectedWindowID {
                // Обновляем информацию о позиции окна
                if let windowInfo = WindowManager.getWindowInfoByID(windowID) {
                    windowBounds = windowInfo.bounds
                    Config.currentWindowBounds = windowBounds
                    
                    // Захватываем изображение окна
                    if let cgImage = CGWindowListCreateImage(
                        .zero,
                        .optionIncludingWindow,
                        windowID,
                        [.boundsIgnoreFraming, .nominalResolution]
                    ) {
                        windowImage = cgImage
                    }
                }
            }
        } else {
            // Захват области экрана
            windowBounds = Config.captureRect
            
            if let cgImage = CGWindowListCreateImage(
                windowBounds,
                .optionOnScreenOnly,
                kCGNullWindowID,
                [.boundsIgnoreFraming, .nominalResolution]
            ) {
                windowImage = cgImage
            }
        }
    }
    
    /// Обнаруживает синий объект на изображении
    private func detectBlueObject(in image: CGImage) {
        // Сбрасываем предыдущие данные о синем объекте
        bluePosition = .zero
        blueSize = .zero
        
        // Получаем данные изображения
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let buffer = CFDataGetBytePtr(data) else {
            return
        }
        
        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var bluePixelsCount = 0
        
        // Сканируем изображение в поисках синих пикселей
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                
                // Получаем компоненты цвета (BGRA формат)
                let blue = buffer[offset]
                let green = buffer[offset + 1]
                let red = buffer[offset + 2]
                
                // Проверяем, является ли пиксель "синим" согласно нашим критериям
                if blue > Config.blueMinValue && red < Config.redMaxValue && green < Config.greenMaxValue {
                    // Обновляем границы синей области
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                    bluePixelsCount += 1
                }
            }
        }
        
        // Проверяем, был ли найден синий объект
        if bluePixelsCount > Config.minBluePixels && maxX >= minX && maxY >= minY {
            bluePosition = CGPoint(x: minX, y: minY)
            blueSize = CGSize(width: maxX - minX, height: maxY - minY)
        }
    }
    
    /// Обновляет историю позиций объекта
    private func updatePositionHistory(with position: CGPoint) {
        // Ограничиваем историю максимум 30 позициями
        if positionHistory.count > 30 {
            positionHistory.removeFirst()
        }
        
        // Добавляем новую позицию
        positionHistory.append(position)
    }
    
    /// Вычисляет скорость движения объекта
    private func calculateVelocity(currentPosition: CGPoint, deltaTime: TimeInterval) {
        // Если история позиций слишком короткая, не вычисляем скорость
        guard positionHistory.count >= 2 else {
            velocityVector = .zero
            return
        }
        
        // Берем предыдущую позицию для расчета
        let previousPosition = positionHistory[positionHistory.count - 2]
        
        // Вычисляем расстояние между позициями
        let dx = currentPosition.x - previousPosition.x
        let dy = currentPosition.y - previousPosition.y
        
        // Если движение слишком маленькое, считаем, что объект неподвижен
        let distance = sqrt(dx * dx + dy * dy)
        if distance < Config.movementThreshold {
            velocityVector = .zero
            return
        }
        
        // Вычисляем скорость в пикселях в секунду
        let vx = dx / CGFloat(deltaTime)
        let vy = dy / CGFloat(deltaTime)
        
        // Применяем сглаживание к значению скорости
        let smoothFactor = Config.smoothingFactor
        velocityVector = CGVector(
            dx: velocityVector.dx * smoothFactor + vx * (1 - smoothFactor),
            dy: velocityVector.dy * smoothFactor + vy * (1 - smoothFactor)
        )
    }
    
    /// Предсказывает траекторию движения мяча
    private func predictTrajectory() {
        // Сбрасываем предыдущие предсказания
        predictedTrajectory.removeAll()
        predictedLandingPoint = nil
        
        // Если скорость слишком мала или история позиций короткая, не делаем предсказаний
        guard positionHistory.count >= 3,
              abs(velocityVector.dx) > 0.1 || abs(velocityVector.dy) > 0.1 else {
            return
        }
        
        // Получаем текущую позицию
        guard let currentPosition = positionHistory.last else { return }
        
        // Симулируем движение мяча для предсказания траектории
        var simulatedPosition = currentPosition
        var simulatedVelocity = velocityVector
        let gravity: CGFloat = 9.8 * 60 // Пикселей в секунду в квадрате
        let timeStep: CGFloat = 1.0 / 30.0 // 30 кадров в секунду
        let maxSimulationSteps = 100
        
        // Границы игры
        let gameBounds = Config.gameBounds
        
        // Добавляем текущую позицию как начало траектории
        predictedTrajectory.append(simulatedPosition)
        
        for _ in 0..<maxSimulationSteps {
            // Обновляем позицию на основе скорости
            simulatedPosition.x += simulatedVelocity.dx * timeStep
            simulatedPosition.y += simulatedVelocity.dy * timeStep
            
            // Применяем гравитацию
            simulatedVelocity.dy += gravity * timeStep
            
            // Проверяем столкновение с вертикальными стенками
            if simulatedPosition.x < gameBounds.minX || simulatedPosition.x > gameBounds.maxX {
                simulatedVelocity.dx = -simulatedVelocity.dx * 0.8 // Отражение с потерей энергии
                
                // Корректируем позицию, чтобы остаться в пределах границ
                if simulatedPosition.x < gameBounds.minX {
                    simulatedPosition.x = gameBounds.minX
                } else {
                    simulatedPosition.x = gameBounds.maxX
                }
            }
            
            // Проверяем столкновение с верхней стенкой
            if simulatedPosition.y < gameBounds.minY {
                simulatedVelocity.dy = -simulatedVelocity.dy * 0.8 // Отражение с потерей энергии
                simulatedPosition.y = gameBounds.minY
            }
            
            // Добавляем точку в траекторию
            predictedTrajectory.append(simulatedPosition)
            
            // Если мяч достиг нижней границы, это конец траектории
            if simulatedPosition.y > gameBounds.maxY {
                // Сохраняем точку приземления (где мяч пересекает нижнюю границу)
                predictedLandingPoint = simulatedPosition
                break
            }
        }
    }
    
    /// Обнаруживает платформу в нижней части игровой области
    private func detectPlatform() {
        // В простой реализации просто берем нижнюю часть изображения
        guard let image = windowImage else { return }
        
        let gameBounds = Config.gameBounds
        let platformHeight: CGFloat = 10 // Высота области, в которой ищем платформу
        
        // Область для поиска платформы - нижняя часть игрового поля
        let platformDetectionArea = CGRect(
            x: gameBounds.origin.x,
            y: gameBounds.maxY - platformHeight,
            width: gameBounds.width,
            height: platformHeight
        )
        
        // Получаем данные изображения
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let buffer = CFDataGetBytePtr(data) else {
            return
        }
        
        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8
        
        var platformStartX = Int.max
        var platformEndX = 0
        
        // Сканируем нижнюю часть изображения в поисках платформы
        let y = Int(platformDetectionArea.origin.y)
        if y >= 0 && y < height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                
                // Получаем компоненты цвета (BGRA формат)
                let blue = buffer[offset]
                let green = buffer[offset + 1]
                let red = buffer[offset + 2]
                
                // Определяем платформу как яркий объект (например, белый)
                if red > 200 && green > 200 && blue > 200 {
                    platformStartX = min(platformStartX, x)
                    platformEndX = max(platformEndX, x)
                }
            }
        }
        
        // Проверяем, была ли найдена платформа
        if platformEndX > platformStartX {
            platformPosition = CGPoint(
                x: (platformStartX + platformEndX) / 2,
                y: Int(platformDetectionArea.origin.y + platformDetectionArea.height / 2)
            )
            platformWidth = CGFloat(platformEndX - platformStartX)
        }
    }
    
    /// Перемещает курсор к позиции синего объекта
    private func moveCursorToBlueObject() {
        guard blueSize.width > 0 && blueSize.height > 0 else { return }
        
        // Вычисляем центр объекта
        let objectCenter = CGPoint(
            x: bluePosition.x + blueSize.width / 2,
            y: bluePosition.y + blueSize.height / 2
        )
        
        // Преобразуем координаты из локальных в глобальные
        var globalPoint = CGPoint(
            x: windowBounds.origin.x + objectCenter.x,
            y: windowBounds.origin.y + objectCenter.y
        )
        
        // Перемещаем курсор
        moveCursorTo(point: globalPoint)
    }
    
    /// Перемещает курсор для перехвата мяча
    private func moveCursorToInterceptBall() {
        // Если есть предсказанная точка приземления, перемещаем курсор туда
        if let landingPoint = predictedLandingPoint {
            // Преобразуем координаты из локальных в глобальные
            let globalPoint = CGPoint(
                x: windowBounds.origin.x + landingPoint.x,
                y: windowBounds.origin.y + Config.gameBounds.maxY - 5 // Немного выше нижней границы
            )
            
            // Перемещаем курсор
            moveCursorTo(point: globalPoint)
        }
    }
    
    /// Перемещает курсор в указанную точку
    private func moveCursorTo(point: CGPoint) {
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
} 