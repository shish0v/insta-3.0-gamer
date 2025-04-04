import Cocoa

/// Представление для отображения отладочной информации
class DebugOverlayView: NSView {
    
    // Данные для отображения
    private var ballPosition: CGPoint = .zero
    private var paddleInfo: (position: CGPoint, width: CGFloat) = (.zero, 0)
    private var ballTrajectory: [CGPoint] = []
    private var predictedTrajectory: [CGPoint] = []
    private var predictedLandingPoint: CGPoint?
    private var gameBounds: CGRect = .zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // Настраиваем представление
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Обновляет данные для отображения
    func updateWithData(
        ballPosition: CGPoint,
        paddleInfo: (position: CGPoint, width: CGFloat),
        ballTrajectory: [CGPoint],
        predictedTrajectory: [CGPoint],
        predictedLandingPoint: CGPoint?,
        gameBounds: CGRect
    ) {
        self.ballPosition = ballPosition
        self.paddleInfo = paddleInfo
        self.ballTrajectory = ballTrajectory
        self.predictedTrajectory = predictedTrajectory
        self.predictedLandingPoint = predictedLandingPoint
        self.gameBounds = gameBounds
        
        // Принудительно перерисовываем представление
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Очищаем фон
        context.setFillColor(NSColor.darkGray.withAlphaComponent(0.2).cgColor)
        context.fill(bounds)
        
        // Отрисовываем границы игры
        if gameBounds.width > 0 && gameBounds.height > 0 {
            // Масштабируем границы игры для отображения в отладочном окне
            let scale = min(bounds.width / gameBounds.width, bounds.height / gameBounds.height) * 0.9
            let offsetX = (bounds.width - gameBounds.width * scale) / 2
            let offsetY = (bounds.height - gameBounds.height * scale) / 2
            
            // Преобразуем координаты игры в координаты отладочного окна
            let scaledGameBounds = CGRect(
                x: offsetX,
                y: offsetY,
                width: gameBounds.width * scale,
                height: gameBounds.height * scale
            )
            
            // Отрисовываем рамку игровой области
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(2.0)
            context.stroke(scaledGameBounds)
            
            // Функция для преобразования координат
            func transformPoint(_ point: CGPoint) -> CGPoint {
                return CGPoint(
                    x: offsetX + (point.x - gameBounds.minX) * scale,
                    y: offsetY + (point.y - gameBounds.minY) * scale
                )
            }
            
            // Отрисовываем траекторию мяча
            if ballTrajectory.count > 1 {
                context.setStrokeColor(NSColor.yellow.cgColor)
                context.setLineWidth(1.0)
                context.beginPath()
                
                let firstPoint = transformPoint(ballTrajectory[0])
                context.move(to: firstPoint)
                
                for i in 1..<ballTrajectory.count {
                    let point = transformPoint(ballTrajectory[i])
                    context.addLine(to: point)
                }
                
                context.strokePath()
            }
            
            // Отрисовываем предсказанную траекторию
            if predictedTrajectory.count > 1 {
                context.setStrokeColor(NSColor.cyan.cgColor)
                context.setLineWidth(1.0)
                context.setLineDash(phase: 0, lengths: [4, 2])
                context.beginPath()
                
                let firstPoint = transformPoint(predictedTrajectory[0])
                context.move(to: firstPoint)
                
                for i in 1..<predictedTrajectory.count {
                    let point = transformPoint(predictedTrajectory[i])
                    context.addLine(to: point)
                }
                
                context.strokePath()
                context.setLineDash(phase: 0, lengths: [])
            }
            
            // Отрисовываем текущую позицию мяча
            if ballPosition.x != 0 || ballPosition.y != 0 {
                let transformedBallPosition = transformPoint(ballPosition)
                context.setFillColor(NSColor.blue.cgColor)
                context.fillEllipse(in: CGRect(
                    x: transformedBallPosition.x - 5,
                    y: transformedBallPosition.y - 5,
                    width: 10,
                    height: 10
                ))
            }
            
            // Отрисовываем предсказанную точку приземления
            if let landingPoint = predictedLandingPoint {
                let transformedLandingPoint = transformPoint(landingPoint)
                context.setFillColor(NSColor.red.cgColor)
                context.fillEllipse(in: CGRect(
                    x: transformedLandingPoint.x - 5,
                    y: transformedLandingPoint.y - 5,
                    width: 10,
                    height: 10
                ))
            }
            
            // Отрисовываем платформу
            if paddleInfo.width > 0 {
                let transformedPaddlePosition = transformPoint(paddleInfo.position)
                let paddleWidth = paddleInfo.width * scale
                
                context.setFillColor(NSColor.white.cgColor)
                context.fill(CGRect(
                    x: transformedPaddlePosition.x - paddleWidth / 2,
                    y: transformedPaddlePosition.y - 2,
                    width: paddleWidth,
                    height: 4
                ))
            }
        }
        
        // Отрисовываем текстовую информацию
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        
        let infoText = """
        Позиция мяча: (\(Int(ballPosition.x)), \(Int(ballPosition.y)))
        Размер окна: \(Int(gameBounds.width))x\(Int(gameBounds.height))
        Точки траектории: \(ballTrajectory.count)
        Предсказанные точки: \(predictedTrajectory.count)
        """
        
        infoText.draw(at: NSPoint(x: 10, y: bounds.height - 60), withAttributes: attributes)
    }
} 