import Cocoa

/// Главный контроллер представления для интерфейса приложения
class MainViewController: NSViewController {
    
    // MARK: - UI элементы
    
    // Базовые контролы
    var startStopButton: NSButton!
    var quitButton: NSButton!
    
    // Элементы настройки области захвата
    var captureSettingsBox: NSBox!
    var trackingModeSegment: NSSegmentedControl!
    var screenPopup: NSPopUpButton!
    var windowPopup: NSPopUpButton!
    var xField: NSTextField!
    var yField: NSTextField!
    var widthField: NSTextField!
    var heightField: NSTextField!
    var selectAreaButton: NSButton!
    
    // Элементы настройки цвета
    var colorSettingsBox: NSBox!
    var blueMinSlider: NSSlider!
    var redMaxSlider: NSSlider!
    var greenMaxSlider: NSSlider!
    var minBluePixelsSlider: NSSlider!
    
    // Элементы настройки движения
    var movementSettingsBox: NSBox!
    var movementThresholdSlider: NSSlider!
    var smoothingFactorSlider: NSSlider!
    var useMotionPredictionCheckbox: NSButton!
    
    // Элементы игрового режима
    var gameModeSettingsBox: NSBox!
    var gameModeCheckbox: NSButton!
    var gameBoundsButton: NSButton!
    var gameModeInfoLabel: NSTextField!
    
    // Элементы отладки
    var debugSettingsBox: NSBox!
    var showDebugOverlayCheckbox: NSButton!
    
    // Отладочное окно
    var debugOverlayWindow: NSWindow?
    var debugOverlayView: DebugOverlayView?
    
    // Трекер
    var tracker: BlueEmojiTracker!
    
    // MARK: - Жизненный цикл
    
    override func loadView() {
        // Создаем основное view
        let frame = NSRect(x: 0, y: 0, width: 650, height: 650)
        view = NSView(frame: frame)
        view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Инициализируем трекер
        tracker = BlueEmojiTracker()
        
        // Настраиваем пользовательский интерфейс
        setupUI()
        
        // Обновляем интерфейс текущими настройками
        updateUIFromSettings()
        
        // Проверяем разрешение на запись экрана
        requestScreenCapturePermission()
    }
    
    // MARK: - Обработчики действий
    
    @objc func startStopButtonClicked() {
        if tracker.isRunning {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    @objc func quitButtonClicked() {
        NSApp.terminate(nil)
    }
    
    @objc func trackingModeChanged() {
        let useWindowMode = trackingModeSegment.selectedSegment == 1
        Config.useWindowMode = useWindowMode
        
        // Обновляем видимость соответствующих элементов управления
        updateTrackingModeUI()
        
        // Если режим окна включен, обновляем список окон
        if useWindowMode {
            updateWindowList()
        }
    }
    
    @objc func screenSelected() {
        guard let selectedScreen = getSelectedScreen() else { return }
        Config.selectedScreen = selectedScreen
        updateScreenCoordinates()
    }
    
    @objc func windowSelected() {
        guard let selectedWindow = getSelectedWindow() else { return }
        
        Config.selectedWindowID = selectedWindow.windowID
        Config.selectedWindowName = selectedWindow.name
        
        // Обновляем поля координат
        xField.doubleValue = selectedWindow.bounds.origin.x
        yField.doubleValue = selectedWindow.bounds.origin.y
        widthField.doubleValue = selectedWindow.bounds.width
        heightField.doubleValue = selectedWindow.bounds.height
        
        // Сохраняем границы окна для последующего использования
        Config.currentWindowBounds = selectedWindow.bounds
        Config.captureRect = selectedWindow.bounds
    }
    
    // MARK: - Управление отслеживанием
    
    func startTracking() {
        // Обновляем настройки из UI
        updateSettingsFromUI()
        
        // Начинаем отслеживание
        tracker.startTracking()
        
        // Обновляем UI
        startStopButton.title = "⏹️ Остановить отслеживание"
        
        // Включаем оверлей отладки, если нужно
        if Config.showHighlight {
            showDebugOverlay()
        }
        
        Logger.shared.log("Отслеживание запущено")
    }
    
    func stopTracking() {
        // Останавливаем отслеживание
        tracker.stopTracking()
        
        // Обновляем UI
        startStopButton.title = "▶️ Запустить отслеживание"
        
        // Скрываем оверлей отладки
        hideDebugOverlay()
        
        Logger.shared.log("Отслеживание остановлено")
    }
} 