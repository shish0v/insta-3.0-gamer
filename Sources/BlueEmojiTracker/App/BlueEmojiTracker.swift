import Cocoa
import simd

struct TrackerConfig {
    var useWindowMode: Bool
    var selectedWindowID: CGWindowID?
    var selectedScreen: NSScreen?
    var captureRect: CGRect
    var currentWindowBounds: CGRect?

    var blueMinValue: UInt8
    var redMaxValue: UInt8
    var greenMaxValue: UInt8
    var minBluePixels: Int

    var movementThreshold: CGFloat
    var smoothingFactor: CGFloat
    var useMotionPrediction: Bool

    var customScaleX: CGFloat?
    var customScaleY: CGFloat?

    static let defaultScanStep = 2
}

class BlueEmojiTracker {

    public private(set) var isRunning = false
    private var config: TrackerConfig

    private var timer: Timer?
    private var lastPosition = CGPoint.zero
    private var velocityX: CGFloat = 0
    private var velocityY: CGFloat = 0
    private var lastMoveTime = Date()
    
    init(config: TrackerConfig) {
        self.config = config
    }
    
    func startTracking() {
        guard !isRunning else { return }
        isRunning = true
        Logger.shared.log("Запуск отслеживания с конфигурацией: \(config)")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stopTracking() {
        guard isRunning else { return }
        isRunning = false
        Logger.shared.log("Остановка отслеживания")
        
        timer?.invalidate()
        timer = nil
    }

    func updateConfig(newConfig: TrackerConfig) {
        self.config = newConfig
    }

    private func update() {
        guard let image = captureScreen() else {
            Logger.shared.log("Не удалось захватить экран")
            return
        }
        
        let blueObjectPosition = findBlueObject(in: image)
        updateCursorPosition(blueObjectPosition, imageSize: CGSize(width: image.width, height: image.height))
    }
    
    private func captureScreen() -> CGImage? {
        if config.useWindowMode {
            return captureWindow()
        } else {
            return captureScreenArea()
        }
    }
    
    private func captureWindow() -> CGImage? {
        guard let windowID = config.selectedWindowID else { return nil }
        
        guard let windowInfo = WindowManager.getWindowInfo(windowID: windowID) else {
            Logger.shared.log("⚠️ Выбранное окно больше не доступно (ID: \(windowID))")
            return nil
        }
        
        config.currentWindowBounds = windowInfo.bounds
        
        let cgOptions: CGWindowImageOption = [.boundsIgnoreFraming, .bestResolution]
        return CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, cgOptions)
    }
    
    private func captureScreenArea() -> CGImage? {
        guard let selectedScreen = config.selectedScreen else { return nil }
        
        let flippedRect = CGRect(
            x: config.captureRect.origin.x,
            y: selectedScreen.frame.height - config.captureRect.origin.y - config.captureRect.height,
            width: config.captureRect.width,
            height: config.captureRect.height
        )
        
        return CGWindowListCreateImage(flippedRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
    }
    
    private func findBlueObject(in image: CGImage) -> CGPoint? {
        guard let data = image.dataProvider?.data,
              let buffer = CFDataGetBytePtr(data) else {
            return nil
        }
        
        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bytesPerPixel = image.bitsPerPixel / 8
        
        var xSum = 0
        var ySum = 0
        var bluePixelCount = 0
        
        for y in stride(from: 0, to: height, by: TrackerConfig.defaultScanStep) {
            for x in stride(from: 0, to: width, by: TrackerConfig.defaultScanStep) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                
                let blue = buffer[offset]
                let green = buffer[offset + 1]
                let red = buffer[offset + 2]
                
                if blue >= config.blueMinValue && red <= config.redMaxValue && green <= config.greenMaxValue {
                    xSum += x
                    ySum += y
                    bluePixelCount += 1
                }
            }
        }
        
        if bluePixelCount >= config.minBluePixels {
            let avgX = CGFloat(xSum) / CGFloat(bluePixelCount)
            let avgY = CGFloat(ySum) / CGFloat(bluePixelCount)
            return CGPoint(x: avgX, y: avgY)
        }

        return nil
    }
    
    private func updateCursorPosition(_ point: CGPoint?, imageSize: CGSize) {
        guard let targetPoint = point else { return }
        
        let currentPosition = NSEvent.mouseLocation
        let screenPoint = imageToScreenCoordinates(point: targetPoint, imageSize: imageSize)
        
        let deltaX = screenPoint.x - currentPosition.x
        let deltaY = screenPoint.y - currentPosition.y
        
        if sqrt(deltaX * deltaX + deltaY * deltaY) < config.movementThreshold {
            return
        }
        
        let newX = currentPosition.x + deltaX * config.smoothingFactor
        let newY = currentPosition.y + deltaY * config.smoothingFactor

        moveCursor(to: CGPoint(x: newX, y: newY))
    }
    
    private func imageToScreenCoordinates(point: CGPoint, imageSize: CGSize) -> CGPoint {
        if config.useWindowMode {
            guard let windowBounds = config.currentWindowBounds else { return .zero }
            
            let scaleX = imageSize.width / windowBounds.width
            let scaleY = imageSize.height / windowBounds.height
            
            let normalizedX = point.x / scaleX
            let normalizedY = point.y / scaleY
            
            return CGPoint(
                x: windowBounds.origin.x + normalizedX,
                y: windowBounds.origin.y + (windowBounds.height - normalizedY)
            )
        } else {
            let scaleX = imageSize.width / config.captureRect.width
            let scaleY = imageSize.height / config.captureRect.height

            return CGPoint(
                x: config.captureRect.origin.x + (point.x / scaleX),
                y: config.captureRect.origin.y + (point.y / scaleY)
            )
        }
    }
    
    private func moveCursor(to point: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)
        event?.post(tap: .cghidEventTap)
    }
} 