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
    
    // MARK: - Настройка UI
    
    private func setupUI() {
        // Создаем отступы
        let margin: CGFloat = 20
        let contentWidth = view.frame.width - (margin * 2)
        
        // Начинаем с верхней части экрана (с отступом)
        var yPos = view.frame.height - margin
        
        // Создаем кнопку запуска/остановки отслеживания
        startStopButton = NSButton(frame: NSRect(x: margin, y: yPos - 40, width: contentWidth / 1.4, height: 40))
        startStopButton.title = "▶️ Запустить отслеживание"
        startStopButton.bezelStyle = .rounded
        startStopButton.font = NSFont.boldSystemFont(ofSize: 14)
        startStopButton.target = self
        startStopButton.action = #selector(startStopButtonClicked)
        view.addSubview(startStopButton)
        
        // Создаем кнопку выхода
        let quitButtonWidth: CGFloat = 100
        quitButton = NSButton(frame: NSRect(
            x: view.frame.width - margin - quitButtonWidth,
            y: yPos - 30,
            width: quitButtonWidth,
            height: 30
        ))
        quitButton.title = "Выход"
        quitButton.bezelStyle = .rounded
        quitButton.target = self
        quitButton.action = #selector(quitButtonClicked)
        view.addSubview(quitButton)
        
        // Обновляем текущую позицию Y
        yPos -= 60
        
        // Создаем бокс настроек захвата экрана
        captureSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 120, width: contentWidth, height: 120))
        captureSettingsBox.title = "Область захвата"
        captureSettingsBox.titlePosition = .atTop
        captureSettingsBox.transparent = false
        view.addSubview(captureSettingsBox)
        
        // Контент в боксе настроек области захвата
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 90
        
        // Создаем переключатель режима захвата
        let modeLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        modeLabel.stringValue = "Режим захвата:"
        modeLabel.isEditable = false
        modeLabel.isBordered = false
        modeLabel.drawsBackground = false
        captureSettingsBox.addSubview(modeLabel)
        
        trackingModeSegment = NSSegmentedControl(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130,
            height: 20
        ))
        trackingModeSegment.segmentCount = 2
        trackingModeSegment.setLabel("Область экрана", forSegment: 0)
        trackingModeSegment.setLabel("Окно", forSegment: 1)
        trackingModeSegment.selectedSegment = Config.useWindowMode ? 1 : 0
        trackingModeSegment.target = self
        trackingModeSegment.action = #selector(trackingModeChanged)
        captureSettingsBox.addSubview(trackingModeSegment)
        
        boxYPos -= 25
        
        // Создаем выпадающие списки для выбора экрана или окна
        let screenLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        screenLabel.stringValue = "Выберите экран:"
        screenLabel.isEditable = false
        screenLabel.isBordered = false
        screenLabel.drawsBackground = false
        screenLabel.tag = 101 // для управления видимостью
        captureSettingsBox.addSubview(screenLabel)
        
        screenPopup = NSPopUpButton(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130,
            height: 20
        ))
        screenPopup.target = self
        screenPopup.action = #selector(screenSelected)
        screenPopup.tag = 101 // для управления видимостью
        captureSettingsBox.addSubview(screenPopup)
        
        let windowLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        windowLabel.stringValue = "Выберите окно:"
        windowLabel.isEditable = false
        windowLabel.isBordered = false
        windowLabel.drawsBackground = false
        windowLabel.tag = 102 // для управления видимостью
        captureSettingsBox.addSubview(windowLabel)
        
        windowPopup = NSPopUpButton(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130,
            height: 20
        ))
        windowPopup.target = self
        windowPopup.action = #selector(windowSelected)
        windowPopup.tag = 102 // для управления видимостью
        captureSettingsBox.addSubview(windowPopup)
        
        boxYPos -= 25
        
        // Создаем поля для координат
        let coordWidth = (boxContentWidth - 140) / 4
        
        let xLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 20, height: 20))
        xLabel.stringValue = "X:"
        xLabel.isEditable = false
        xLabel.isBordered = false
        xLabel.drawsBackground = false
        captureSettingsBox.addSubview(xLabel)
        
        xField = NSTextField(frame: NSRect(x: boxMargin + 25, y: boxYPos, width: coordWidth, height: 20))
        xField.stringValue = String(format: "%.0f", Config.captureRect.origin.x)
        captureSettingsBox.addSubview(xField)
        
        let yLabel = NSTextField(frame: NSRect(x: boxMargin + 30 + coordWidth, y: boxYPos, width: 20, height: 20))
        yLabel.stringValue = "Y:"
        yLabel.isEditable = false
        yLabel.isBordered = false
        yLabel.drawsBackground = false
        captureSettingsBox.addSubview(yLabel)
        
        yField = NSTextField(frame: NSRect(x: boxMargin + 55 + coordWidth, y: boxYPos, width: coordWidth, height: 20))
        yField.stringValue = String(format: "%.0f", Config.captureRect.origin.y)
        captureSettingsBox.addSubview(yField)
        
        let widthLabel = NSTextField(frame: NSRect(x: boxMargin + 60 + coordWidth * 2, y: boxYPos, width: 60, height: 20))
        widthLabel.stringValue = "Ширина:"
        widthLabel.isEditable = false
        widthLabel.isBordered = false
        widthLabel.drawsBackground = false
        captureSettingsBox.addSubview(widthLabel)
        
        widthField = NSTextField(frame: NSRect(x: boxMargin + 120 + coordWidth * 2, y: boxYPos, width: coordWidth, height: 20))
        widthField.stringValue = String(format: "%.0f", Config.captureRect.width)
        captureSettingsBox.addSubview(widthField)
        
        let heightLabel = NSTextField(frame: NSRect(x: boxMargin + 125 + coordWidth * 3, y: boxYPos, width: 60, height: 20))
        heightLabel.stringValue = "Высота:"
        heightLabel.isEditable = false
        heightLabel.isBordered = false
        heightLabel.drawsBackground = false
        captureSettingsBox.addSubview(heightLabel)
        
        heightField = NSTextField(frame: NSRect(x: boxMargin + 185 + coordWidth * 3, y: boxYPos, width: coordWidth, height: 20))
        heightField.stringValue = String(format: "%.0f", Config.captureRect.height)
        captureSettingsBox.addSubview(heightField)
        
        boxYPos -= 25
        
        // Кнопка выбора области
        selectAreaButton = NSButton(frame: NSRect(x: boxMargin + (boxContentWidth - 200) / 2, y: boxYPos - 10, width: 200, height: 24))
        selectAreaButton.title = "Выбрать область"
        selectAreaButton.bezelStyle = .rounded
        selectAreaButton.target = self
        selectAreaButton.action = #selector(selectAreaButtonClicked)
        captureSettingsBox.addSubview(selectAreaButton)
        
        // Добавляем остальные элементы интерфейса
        yPos -= 130
        
        // Настройки цвета
        setupColorSettingsUI()
        
        // Настройки движения
        setupMovementSettingsUI()
        
        // Настройки игрового режима
        setupGameModeSettingsUI()
        
        // Настройки отладки
        setupDebugSettingsUI()
        
        // Обновляем видимость элементов в зависимости от режима
        updateUIVisibility()
    }
} 