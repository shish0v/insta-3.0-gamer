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
    
    // Новые параметры для отслеживания траектории мяча
    private var ballTracker = BallTracker()
    private var gameFieldBounds = CGRect.zero  // Границы игрового поля
    private let predictionTimeMs: Double = 150.0  // Время упреждения в миллисекундах
    private var ballRadius: Double = 10.0  // Примерный радиус мяча в пикселях
    
    // Параметры для интеллектуального управления курсором
    private var paddleWidth: Double = 60.0  // Ширина платформы в пикселях
    private var paddleHeight: Double = 15.0 // Высота платформы в пикселях
    private var lastCursorPosition = CGPoint.zero
    private var isMouseDown = false
    private var paddlePosition: Double = 0.0 // X-координата центра платформы
    private var platformInOptimalPosition = false
    
    // Пороги скорости для разных стратегий перехвата
    private let slowVelocityThreshold: Double = 300.0  // пикс/сек
    private let highVelocityThreshold: Double = 800.0  // пикс/сек
    
    // Параметры отладочной визуализации
    private var enableDebugVisualization = false // Включение/выключение визуализации
    private var lastDebugContext: CGContext? // Сохраняем контекст для рисования
    private var predictedTrajectory: [(x: Double, y: Double)] = [] // Точки траектории
    private var landingPoint: Double? // Точка падения мяча
    private var lastPredictedPosition: (x: Double, y: Double)? // Последняя предсказанная позиция
    private var keyboardMonitor: Any? // Монитор клавиатуры для переключения режима
    
    init() {
        setupCaptureRect()
        setupGameField()
        setupKeyboardMonitor()
    }
    
    deinit {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    // Настройка монитора клавиатуры для переключения режима отладки
    private func setupKeyboardMonitor() {
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            // Проверяем нажатие клавиши 'D' для включения/выключения отладки
            if event.keyCode == 2 { // 'D' на клавиатуре
                self.enableDebugVisualization.toggle()
                print("Отладочная визуализация \(self.enableDebugVisualization ? "включена" : "выключена")")
            }
        }
    }
    
    // Настройка границ игрового поля на основе области захвата
    private func setupGameField() {
        gameFieldBounds = CGRect(
            x: 0,
            y: 0,
            width: Config.captureRect.width,
            height: Config.captureRect.height
        )
        
        // Устанавливаем начальную позицию платформы в центр нижней границы
        paddlePosition = Double(gameFieldBounds.width) / 2.0
        
        print("Границы игрового поля: \(gameFieldBounds)")
    }
    
    // Отрисовка отладочной информации
    private func drawDebugVisualization(on context: CGContext, currentPosition: CGPoint) {
        guard enableDebugVisualization else { return }
        
        // Сохраняем контекст для отладки
        lastDebugContext = context
        
        // Рисуем текущую позицию мяча (синий круг)
        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 0.5))
        context.setLineWidth(2)
        
        let ballRect = CGRect(
            x: currentPosition.x - CGFloat(ballRadius),
            y: currentPosition.y - CGFloat(ballRadius),
            width: CGFloat(ballRadius * 2),
            height: CGFloat(ballRadius * 2)
        )
        context.strokeEllipse(in: ballRect)
        context.fillEllipse(in: ballRect)
        
        // Рисуем предсказанную траекторию
        if !predictedTrajectory.isEmpty {
            context.setStrokeColor(CGColor(red: 1, green: 0.5, blue: 0, alpha: 0.8))
            context.setLineWidth(2)
            
            // Начинаем с текущей позиции
            context.move(to: currentPosition)
            
            // Рисуем линию через все точки траектории
            for point in predictedTrajectory {
                context.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            
            context.strokePath()
        }
        
        // Рисуем предсказанную позицию (если есть)
        if let predictedPos = lastPredictedPosition {
            context.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
            
            let predictedRect = CGRect(
                x: predictedPos.x - CGFloat(ballRadius) * 0.8,
                y: predictedPos.y - CGFloat(ballRadius) * 0.8,
                width: CGFloat(ballRadius) * 1.6,
                height: CGFloat(ballRadius) * 1.6
            )
            context.strokeEllipse(in: predictedRect)
            context.fillEllipse(in: predictedRect)
        }
        
        // Рисуем точку падения мяча (если есть)
        if let landing = landingPoint {
            context.setStrokeColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1))
            context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 0.7))
            
            let landingY = Double(gameFieldBounds.height) - ballRadius
            let landingRect = CGRect(
                x: landing - ballRadius,
                y: landingY - ballRadius,
                width: ballRadius * 2,
                height: ballRadius * 2
            )
            context.strokeEllipse(in: landingRect)
            context.fillEllipse(in: landingRect)
            
            // Рисуем линию от текущей позиции к точке падения
            context.setStrokeColor(CGColor(red: 0, green: 0.7, blue: 0, alpha: 0.5))
            context.setLineWidth(1.5)
            context.setLineDash(phase: 0, lengths: [5, 3])
            
            context.move(to: currentPosition)
            context.addLine(to: CGPoint(x: landing, y: landingY))
            context.strokePath()
            
            // Сбрасываем пунктир
            context.setLineDash(phase: 0, lengths: [])
        }
        
        // Рисуем платформу
        context.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))
        context.setFillColor(CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8))
        
        let paddleRect = CGRect(
            x: lastCursorPosition.x - CGFloat(paddleWidth/2),
            y: lastCursorPosition.y - CGFloat(paddleHeight/2),
            width: CGFloat(paddleWidth),
            height: CGFloat(paddleHeight)
        )
        context.fillRect(paddleRect)
        context.strokeRect(paddleRect)
    }
    
    // Обновление отладочных данных для визуализации
    private func updateDebugData() {
        guard enableDebugVisualization else { return }
        
        // Очищаем предыдущие данные
        predictedTrajectory.removeAll()
        
        // Симулируем траекторию для визуализации
        if let velocity = ballTracker.getVelocity(),
           ballTracker.positions.count >= 1 {
            
            let latest = ballTracker.positions.last!
            let simulationSteps = 10 // Количество шагов симуляции
            let timeStep = predictionTimeMs / 1000.0 / Double(simulationSteps)
            
            // Начальные значения для симуляции
            var currentX = latest.x
            var currentY = latest.y
            var currentVx = velocity.vx
            var currentVy = velocity.vy
            
            // Симулируем движение по шагам
            for _ in 0..<simulationSteps {
                // Проверяем столкновения со стенками
                if currentX <= ballRadius || currentX >= Double(gameFieldBounds.width) - ballRadius {
                    currentVx = -currentVx  // Отскок от боковой стенки
                }
                
                if currentY <= ballRadius || currentY >= Double(gameFieldBounds.height) - ballRadius {
                    currentVy = -currentVy  // Отскок от верхней/нижней стенки
                }
                
                // Обновляем позицию
                currentX += currentVx * timeStep
                currentY += currentVy * timeStep
                
                // Добавляем точку в траекторию
                predictedTrajectory.append((x: currentX, y: currentY))
            }
            
            // Обновляем последнюю предсказанную позицию
            if let predicted = predictBallPositionWithBounce() {
                lastPredictedPosition = predicted
            }
            
            // Обновляем точку падения
            landingPoint = calculateLandingPoint()
        }
    }
    
    // Метод для обработки обнаруженной позиции мяча
    private func processBallPosition(_ position: CGPoint) {
        // Сохраняем позицию в трекере
        ballTracker.addPosition(x: Double(position.x), y: Double(position.y))
        
        // Обновляем данные для отладочной визуализации
        updateDebugData()
        
        // Проверяем скорость мяча для выбора стратегии
        let ballVelocity = ballTracker.getVelocity()
        let speedMagnitude = calculateSpeedMagnitude(ballVelocity)
        
        // Определяем оптимальную позицию курсора в зависимости от скорости
        if let optimalPosition = calculateOptimalInterceptionPoint(currentPosition: position, velocity: ballVelocity, speedMagnitude: speedMagnitude) {
            // Перемещаем курсор в оптимальную позицию
            moveCursorToPosition(optimalPosition)
            
            // Проверяем необходимость нажатия кнопки мыши
            checkMouseClickTiming(position: position, optimalPosition: optimalPosition)
            
            // Обновляем последнюю позицию
            lastPosition = position
        } else {
            // Если не удалось рассчитать оптимальную позицию, следуем за мячом
            let defaultPosition = CGPoint(x: position.x, y: gameFieldBounds.height - paddleHeight/2)
            moveCursorToPosition(defaultPosition)
            lastPosition = position
        }
    }
    
    // Расчет оптимальной точки перехвата в зависимости от скорости мяча
    private func calculateOptimalInterceptionPoint(
        currentPosition: CGPoint, 
        velocity: (vx: Double, vy: Double)?, 
        speedMagnitude: Double
    ) -> CGPoint? {
        guard let velocity = velocity, ballTracker.positions.count >= 1 else {
            // Если не можем рассчитать скорость, просто возвращаем текущую позицию
            return CGPoint(x: currentPosition.x, y: gameFieldBounds.height - paddleHeight/2)
        }
        
        // Y-позиция курсора (нижняя часть игрового поля)
        let cursorY = gameFieldBounds.height - paddleHeight / 2
        var targetX: Double
        
        // Стратегия в зависимости от скорости
        if speedMagnitude < slowVelocityThreshold {
            // При медленном движении - просто следуем за мячом с небольшим упреждением
            print("Стратегия медленного движения: следование за мячом")
            targetX = Double(currentPosition.x) + velocity.vx * 0.1  // небольшое упреждение
        } else if speedMagnitude < highVelocityThreshold {
            // При средней скорости - упреждаем с использованием предсказания
            print("Стратегия средней скорости: умеренное упреждение")
            if let predictedPos = predictBallPositionWithBounce() {
                targetX = predictedPos.x
                
                // Добавляем небольшое смещение в направлении движения
                if abs(velocity.vx) > 50.0 {
                    let directionFactor = velocity.vx > 0 ? 1.0 : -1.0
                    targetX += directionFactor * paddleWidth * 0.2
                }
            } else {
                targetX = Double(currentPosition.x) + velocity.vx * 0.2
            }
        } else {
            // При высокой скорости - активное упреждение и расчет точки падения
            print("Стратегия высокой скорости: активное упреждение")
            if let landingPoint = calculateLandingPoint() {
                targetX = landingPoint
                
                // Добавляем смещение в направлении движения
                if abs(velocity.vx) > 100.0 {
                    let directionFactor = velocity.vx > 0 ? 1.0 : -1.0
                    targetX += directionFactor * paddleWidth * 0.3
                }
            } else if let predictedPos = predictBallPositionWithBounce() {
                targetX = predictedPos.x + velocity.vx * 0.3
            } else {
                targetX = Double(currentPosition.x) + velocity.vx * 0.4
            }
        }
        
        // Ограничиваем позицию курсора в пределах игрового поля
        targetX = max(paddleWidth / 2, min(Double(gameFieldBounds.width) - paddleWidth / 2, targetX))
        
        return CGPoint(x: targetX, y: cursorY)
    }
    
    // Расчет модуля скорости мяча
    private func calculateSpeedMagnitude(_ velocity: (vx: Double, vy: Double)?) -> Double {
        guard let velocity = velocity else { return 0.0 }
        return sqrt(velocity.vx * velocity.vx + velocity.vy * velocity.vy)
    }
    
    // Проверка необходимости нажатия кнопки мыши
    private func checkMouseClickTiming(position: CGPoint, optimalPosition: CGPoint) {
        // Получаем скорость мяча
        guard let velocity = ballTracker.getVelocity() else { return }
        
        // Проверяем, движется ли мяч вниз
        if velocity.vy > 0 {
            // Рассчитываем предполагаемое время до достижения платформы
            let distanceToPlateform = Double(gameFieldBounds.height - paddleHeight - position.y)
            let timeToReachPlatform = distanceToPlateform / velocity.vy
            
            // Если мяч приближается к платформе в течение 100 мс
            if timeToReachPlatform < 0.1 && !isMouseDown {
                // Удостоверимся, что мяч будет над платформой
                let expectedBallX = Double(position.x) + velocity.vx * timeToReachPlatform
                let platformLeftEdge = Double(optimalPosition.x) - paddleWidth / 2
                let platformRightEdge = Double(optimalPosition.x) + paddleWidth / 2
                
                if expectedBallX >= platformLeftEdge && expectedBallX <= platformRightEdge {
                    // Позиция оптимальна, нажимаем мышь
                    platformInOptimalPosition = true
                    
                    // Имитируем нажатие кнопки мыши
                    performMouseClick(down: true)
                    isMouseDown = true
                    print("Нажатие кнопки мыши - мяч приближается к платформе")
                }
            }
        } else if isMouseDown {
            // Если мяч движется вверх и кнопка нажата, отпускаем
            performMouseClick(down: false)
            isMouseDown = false
            platformInOptimalPosition = false
            print("Отпускание кнопки мыши - мяч движется вверх")
        }
    }
    
    // Перемещение курсора мыши
    private func moveCursorToPosition(_ position: CGPoint) {
        // Проверяем, нужно ли перемещать курсор
        let distanceThreshold: CGFloat = 5.0 // минимальное расстояние для перемещения
        let distance = hypot(position.x - lastCursorPosition.x, position.y - lastCursorPosition.y)
        
        if distance > distanceThreshold || platformInOptimalPosition {
            // Преобразуем координаты из игрового поля в координаты экрана
            let screenPosition = convertToScreenCoordinates(position)
            
            // Перемещаем курсор
            let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                   mouseCursorPosition: screenPosition, mouseButton: .left)
            moveEvent?.post(tap: .cghidEventTap)
            
            // Сохраняем позицию курсора
            lastCursorPosition = position
            
            print("Курсор перемещен на позицию: \(screenPosition)")
        }
    }
    
    // Имитация нажатия/отпускания кнопки мыши
    private func performMouseClick(down: Bool) {
        let screenPosition = convertToScreenCoordinates(lastCursorPosition)
        let eventType: CGEventType = down ? .leftMouseDown : .leftMouseUp
        
        let mouseEvent = CGEvent(mouseEventSource: nil, mouseType: eventType,
                                mouseCursorPosition: screenPosition, mouseButton: .left)
        mouseEvent?.post(tap: .cghidEventTap)
        
        print("Выполнено \(down ? "нажатие" : "отпускание") кнопки мыши на позиции: \(screenPosition)")
    }
    
    // Преобразование координат из игрового поля в координаты экрана
    private func convertToScreenCoordinates(_ position: CGPoint) -> CGPoint {
        if Config.useWindowMode && Config.selectedWindowID != nil && Config.currentWindowBounds != nil {
            // Для оконного режима
            let windowBounds = Config.currentWindowBounds!
            
            // Применяем масштабирование
            let scaleX = Config.customScaleX
            let scaleY = Config.customScaleY
            
            let screenX = windowBounds.origin.x + (position.x / CGFloat(scaleX))
            let screenY = windowBounds.origin.y + (position.y / CGFloat(scaleY))
            
            return CGPoint(x: screenX, y: screenY)
        } else {
            // Для полноэкранного режима
            return CGPoint(
                x: Config.captureRect.origin.x + position.x,
                y: Config.captureRect.origin.y + position.y
            )
        }
    }
    
    // Предсказание позиции мяча с учетом отскоков от стенок
    private func predictBallPositionWithBounce() -> (x: Double, y: Double)? {
        guard let velocity = ballTracker.getVelocity(),
              let initialPrediction = ballTracker.predictPosition(afterMs: predictionTimeMs),
              ballTracker.positions.count >= 1 else {
            return nil
        }
        
        let latest = ballTracker.positions.last!
        let timeSeconds = predictionTimeMs / 1000.0
        
        // Начальные значения для симуляции
        var currentX = latest.x
        var currentY = latest.y
        var currentVx = velocity.vx
        var currentVy = velocity.vy
        var remainingTime = timeSeconds
        
        // Цикл симуляции движения с отскоками
        while remainingTime > 0.001 {  // Минимальный порог для предотвращения бесконечного цикла
            // Рассчитываем время до следующего столкновения
            let timeToXCollision = calculateTimeToXCollision(x: currentX, vx: currentVx)
            let timeToYCollision = calculateTimeToYCollision(y: currentY, vy: currentVy)
            
            // Определяем ближайшее столкновение
            if timeToXCollision < 0 && timeToYCollision < 0 {
                // Нет столкновений, двигаемся до конца оставшегося времени
                currentX += currentVx * remainingTime
                currentY += currentVy * remainingTime
                break
            }
            
            if (timeToXCollision >= 0 && timeToXCollision < timeToYCollision) || timeToYCollision < 0 {
                // Столкновение с вертикальной стенкой
                if timeToXCollision <= remainingTime {
                    // Двигаемся до точки столкновения
                    currentX += currentVx * timeToXCollision
                    currentY += currentVy * timeToXCollision
                    remainingTime -= timeToXCollision
                    
                    // Меняем направление по X (отскок)
                    currentVx = -currentVx
                } else {
                    // Времени на столкновение не хватает, двигаемся до конца
                    currentX += currentVx * remainingTime
                    currentY += currentVy * remainingTime
                    break
                }
            } else {
                // Столкновение с горизонтальной стенкой
                if timeToYCollision <= remainingTime {
                    // Двигаемся до точки столкновения
                    currentX += currentVx * timeToYCollision
                    currentY += currentVy * timeToYCollision
                    remainingTime -= timeToYCollision
                    
                    // Меняем направление по Y (отскок)
                    currentVy = -currentVy
                } else {
                    // Времени на столкновение не хватает, двигаемся до конца
                    currentX += currentVx * remainingTime
                    currentY += currentVy * remainingTime
                    break
                }
            }
        }
        
        // Возвращаем предсказанную позицию
        return (x: currentX, y: currentY)
    }
    
    // Рассчитываем время до столкновения с вертикальной стенкой
    private func calculateTimeToXCollision(x: Double, vx: Double) -> Double {
        if vx > 0 {
            // Движение вправо, проверяем правую границу
            let distanceToRightWall = Double(gameFieldBounds.width) - ballRadius - x
            return distanceToRightWall / vx
        } else if vx < 0 {
            // Движение влево, проверяем левую границу
            let distanceToLeftWall = x - ballRadius
            return distanceToLeftWall / -vx
        }
        return -1 // Нет движения по X
    }
    
    // Рассчитываем время до столкновения с горизонтальной стенкой
    private func calculateTimeToYCollision(y: Double, vy: Double) -> Double {
        if vy > 0 {
            // Движение вниз, проверяем нижнюю границу
            let distanceToBottomWall = Double(gameFieldBounds.height) - ballRadius - y
            return distanceToBottomWall / vy
        } else if vy < 0 {
            // Движение вверх, проверяем верхнюю границу
            let distanceToTopWall = y - ballRadius
            return distanceToTopWall / -vy
        }
        return -1 // Нет движения по Y
    }
    
    // Расчет точки падения мяча на нижнюю границу
    private func calculateLandingPoint() -> Double? {
        guard let velocity = ballTracker.getVelocity(),
              velocity.vy > 0, // Мяч должен двигаться вниз
              ballTracker.positions.count >= 1 else {
            return nil
        }
        
        let latest = ballTracker.positions.last!
        
        // Если мяч уже у нижней границы
        if latest.y >= Double(gameFieldBounds.height) - ballRadius {
            return latest.x
        }
        
        // Рассчитываем время до падения на нижнюю границу
        let timeToBottom = (Double(gameFieldBounds.height) - ballRadius - latest.y) / velocity.vy
        
        // Рассчитываем количество отскоков от боковых стенок
        var currentX = latest.x
        var currentVx = velocity.vx
        var remainingTime = timeToBottom
        
        while remainingTime > 0 {
            // Время до следующего отскока от боковой стенки
            let timeToXCollision = calculateTimeToXCollision(x: currentX, vx: currentVx)
            
            if timeToXCollision < 0 || timeToXCollision > remainingTime {
                // Нет отскоков или времени не хватает на отскок
                currentX += currentVx * remainingTime
                break
            }
            
            // Двигаемся до точки отскока
            currentX += currentVx * timeToXCollision
            remainingTime -= timeToXCollision
            
            // Меняем направление по X
            currentVx = -currentVx
        }
        
        return currentX
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
        let result = findBlueObjectUsingSimd(context: context, image: image)
        
        // Рисуем отладочную информацию, если она включена
        if let position = result {
            drawDebugVisualization(on: context, currentPosition: position)
        }
        
        return result
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
        
        // Если есть контекст, рисуем изображение для оптимизации работы с пикселями
        if let context = context {
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(image, in: rect)
        }
        
        return context
    }
    
    private func findBlueObjectUsingSimd(context: CGContext, image: CGImage) -> CGPoint? {
        guard let data = context.data else { return nil }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        let width = image.width
        let height = image.height
        
        // Оптимизированные пороговые значения для синего мяча на желтом фоне
        let redMaxValue: UInt8 = 50    // R < 50
        let greenMaxValue: UInt8 = 100 // G < 100
        let blueMinValue: UInt8 = 200  // B > 200
        
        // Параметры для проверки формы и размера
        let minBlueBlobSize = 20   // Минимальный размер синего объекта в пикселях
        let maxBlueBlobSize = 500  // Максимальный размер синего объекта в пикселях
        let aspectRatioTolerance: Float = 0.3 // Допустимое отклонение от идеального круга
        
        // Определяем область поиска, оптимизируя вокруг последнего известного положения
        var searchArea = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Исключаем верхнюю часть экрана со счетом (примерно 15% верхней части)
        let scoreboardHeight = Int(Float(height) * 0.15)
        searchArea.origin.y = CGFloat(scoreboardHeight)
        searchArea.size.height -= CGFloat(scoreboardHeight)
        
        // Если есть предыдущая позиция, сужаем область поиска
        if lastPosition.x > 0 && lastPosition.y > 0 {
            // Определяем радиус поиска в зависимости от времени с последнего обнаружения
            let timeSinceLastDetection = Date().timeIntervalSince(lastMoveTime)
            let searchRadius = min(max(100, Int(timeSinceLastDetection * 300)), Int(width / 2))
            
            // Центр области поиска
            let centerX = Int(lastPosition.x)
            let centerY = Int(lastPosition.y)
            
            // Создаем ограниченную область поиска
            let left = max(0, centerX - searchRadius)
            let top = max(scoreboardHeight, centerY - searchRadius)
            let right = min(width, centerX + searchRadius)
            let bottom = min(height, centerY + searchRadius)
            
            searchArea = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        }
        
        // Округляем границы области поиска до целых чисел
        let searchLeft = Int(searchArea.origin.x)
        let searchTop = Int(searchArea.origin.y)
        let searchRight = Int(searchArea.origin.x + searchArea.width)
        let searchBottom = Int(searchArea.origin.y + searchArea.height)
        
        // Оптимизируем шаг сканирования в зависимости от размера области поиска
        let areaSize = searchArea.width * searchArea.height
        let step = areaSize > 90000 ? 4 : (areaSize > 40000 ? 2 : 1)
        
        let pixelsPerChunk = 16 // Process 16 pixels at once using SIMD
        
        // Переменные для накопления данных о синих пикселях
        var totalBlueX: Float = 0
        var totalBlueY: Float = 0
        var bluePixelCount = 0
        var maxBlueValue: UInt8 = 0
        var maxBluePos = CGPoint.zero
        
        // Переменные для отслеживания границ синего объекта (для проверки формы)
        var minX = Int.max, maxX = 0, minY = Int.max, maxY = 0
        
        // Process image in chunks using SIMD
        for y in stride(from: searchTop, to: searchBottom, by: step) {
            for x in stride(from: searchLeft, to: searchRight - pixelsPerChunk, by: pixelsPerChunk) {
                var blueValues = SIMD16<UInt8>()
                var redValues = SIMD16<UInt8>()
                var greenValues = SIMD16<UInt8>()
                
                // Load pixel data into SIMD vectors
                for i in 0..<pixelsPerChunk {
                    let px = x + i
                    if px < searchRight {
                        let pixelIndex = ((y * width) + px) * 4
                        redValues[i] = pixelData[pixelIndex]
                        greenValues[i] = pixelData[pixelIndex + 1]
                        blueValues[i] = pixelData[pixelIndex + 2]
                    } else {
                        // За пределами изображения
                        redValues[i] = 0
                        greenValues[i] = 0
                        blueValues[i] = 0
                    }
                }
                
                // Apply color thresholds using SIMD operations
                let blueMask = blueValues .>= blueMinValue
                let redMask = redValues .<= redMaxValue
                let greenMask = greenValues .<= greenMaxValue
                let matches = blueMask .& redMask .& greenMask
                
                // Process matching pixels
                for i in 0..<pixelsPerChunk where matches[i] {
                    let px = x + i
                    if px >= searchRight { continue } // Проверка границ
                    
                    totalBlueX += Float(px)
                    totalBlueY += Float(y)
                    bluePixelCount += 1
                    
                    // Обновляем границы объекта для проверки формы
                    minX = min(minX, px)
                    maxX = max(maxX, px)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                    
                    if blueValues[i] > maxBlueValue {
                        maxBlueValue = blueValues[i]
                        maxBluePos = CGPoint(x: px, y: y)
                    }
                }
            }
        }
        
        // Проверка минимального размера объекта
        if bluePixelCount < minBlueBlobSize {
            print("Обнаружен слишком маленький синий объект (пикселей: \(bluePixelCount))")
            return nil
        }
        
        // Проверка максимального размера объекта
        if bluePixelCount > maxBlueBlobSize {
            print("Обнаружен слишком большой синий объект (пикселей: \(bluePixelCount))")
            return nil
        }
        
        // Проверка формы объекта (соотношение ширина/высота должно быть близко к 1 для круга)
        if minX < Int.max && maxX > 0 && minY < Int.max && maxY > 0 {
            let width = Float(maxX - minX)
            let height = Float(maxY - minY)
            
            // Предотвращаем деление на ноль
            if width > 0 && height > 0 {
                let aspectRatio = width / height
                // Проверяем близость к идеальному кругу (aspectRatio = 1.0)
                if abs(aspectRatio - 1.0) > aspectRatioTolerance {
                    print("Обнаруженный объект не похож на круг. Соотношение: \(aspectRatio)")
                    return nil
                }
                
                // Обновляем оценочный радиус мяча для расчетов отскока
                let estimatedRadius = (width + height) / 4.0
                ballRadius = Double(estimatedRadius)
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
        
        // Обновляем время последнего обнаружения
        lastMoveTime = Date()
        
        print("Найден синий объект. Средняя позиция: (\(averageX), \(averageY)), Нормализованная позиция: (\(normalizedX), \(normalizedY)), Пикселей: \(bluePixelCount)")
        
        let position = CGPoint(x: averageX, y: averageY)
        
        // Обрабатываем позицию мяча для предсказания траектории
        processBallPosition(position)
        
        return position
    }
}

class BallTracker {
    private var positions: [(x: Double, y: Double, timestamp: TimeInterval)] = []
    private let maxPositions = 10
    
    func addPosition(x: Double, y: Double) {
        let position = (x: x, y: y, timestamp: Date().timeIntervalSince1970)
        positions.append(position)
        if positions.count > maxPositions {
            positions.removeFirst()
        }
    }
    
    func getVelocity() -> (vx: Double, vy: Double)? {
        guard positions.count >= 2 else { return nil }
        
        let latest = positions.last!
        let previous = positions[positions.count - 2]
        
        let timeDiff = latest.timestamp - previous.timestamp
        guard timeDiff > 0 else { return nil }
        
        let vx = (latest.x - previous.x) / timeDiff
        let vy = (latest.y - previous.y) / timeDiff
        
        return (vx, vy)
    }
    
    func predictPosition(afterMs: Double) -> (x: Double, y: Double)? {
        guard let velocity = getVelocity(), positions.count >= 1 else { return nil }
        
        let latest = positions.last!
        let seconds = afterMs / 1000.0
        
        let predictedX = latest.x + velocity.vx * seconds
        let predictedY = latest.y + velocity.vy * seconds
        
        return (x: predictedX, y: predictedY)
    }
}