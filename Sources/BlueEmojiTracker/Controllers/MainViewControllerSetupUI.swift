import Cocoa

extension MainViewController {
    
    // MARK: - Настройка UI
    
    func setupUI() {
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
        
        // Настраиваем бокс настроек области захвата
        setupCaptureSettingsBox(margin: margin, contentWidth: contentWidth, yPos: &yPos)
        
        // Настраиваем бокс настроек цвета
        setupColorSettingsBox(margin: margin, contentWidth: contentWidth, yPos: &yPos)
        
        // Настраиваем бокс настроек движения
        setupMovementSettingsBox(margin: margin, contentWidth: contentWidth, yPos: &yPos)
        
        // Настраиваем бокс настроек отладки
        setupDebugSettingsBox(margin: margin, contentWidth: contentWidth, yPos: &yPos)
        
        // Заполняем списки экранов и окон
        updateScreenList()
        updateWindowList()
        
        // Устанавливаем правильную видимость для контролов в зависимости от режима
        updateTrackingModeUI()
    }
    
    // MARK: - Настройка отдельных секций UI
    
    private func setupCaptureSettingsBox(margin: CGFloat, contentWidth: CGFloat, yPos: inout CGFloat) {
        // Создаем бокс настроек захвата экрана
        captureSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 120, width: contentWidth, height: 120))
        captureSettingsBox.title = "Область захвата"
        captureSettingsBox.titlePosition = .atTop
        captureSettingsBox.isTransparent = false
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
        xField.doubleValue = Config.captureRect.origin.x
        captureSettingsBox.addSubview(xField)
        
        let yLabel = NSTextField(frame: NSRect(x: boxMargin + 25 + coordWidth + 5, y: boxYPos, width: 20, height: 20))
        yLabel.stringValue = "Y:"
        yLabel.isEditable = false
        yLabel.isBordered = false
        yLabel.drawsBackground = false
        captureSettingsBox.addSubview(yLabel)
        
        yField = NSTextField(frame: NSRect(x: boxMargin + 50 + coordWidth + 5, y: boxYPos, width: coordWidth, height: 20))
        yField.doubleValue = Config.captureRect.origin.y
        captureSettingsBox.addSubview(yField)
        
        let wLabel = NSTextField(frame: NSRect(x: boxMargin + 50 + coordWidth * 2 + 10, y: boxYPos, width: 20, height: 20))
        wLabel.stringValue = "W:"
        wLabel.isEditable = false
        wLabel.isBordered = false
        wLabel.drawsBackground = false
        captureSettingsBox.addSubview(wLabel)
        
        widthField = NSTextField(frame: NSRect(x: boxMargin + 75 + coordWidth * 2 + 10, y: boxYPos, width: coordWidth, height: 20))
        widthField.doubleValue = Config.captureRect.width
        captureSettingsBox.addSubview(widthField)
        
        let hLabel = NSTextField(frame: NSRect(x: boxMargin + 75 + coordWidth * 3 + 15, y: boxYPos, width: 20, height: 20))
        hLabel.stringValue = "H:"
        hLabel.isEditable = false
        hLabel.isBordered = false
        hLabel.drawsBackground = false
        captureSettingsBox.addSubview(hLabel)
        
        heightField = NSTextField(frame: NSRect(x: boxMargin + 100 + coordWidth * 3 + 15, y: boxYPos, width: coordWidth, height: 20))
        heightField.doubleValue = Config.captureRect.height
        captureSettingsBox.addSubview(heightField)
        
        boxYPos -= 25
        
        // Кнопка выбора области захвата
        selectAreaButton = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: 200, height: 20))
        selectAreaButton.title = "Выбрать область визуально"
        selectAreaButton.bezelStyle = .rounded
        selectAreaButton.target = self
        selectAreaButton.action = #selector(selectAreaButtonClicked)
        captureSettingsBox.addSubview(selectAreaButton)
        
        // Обновляем позицию Y для следующего бокса
        yPos -= 120 + 10
    }
    
    private func setupColorSettingsBox(margin: CGFloat, contentWidth: CGFloat, yPos: inout CGFloat) {
        // Создаем бокс настроек цвета
        colorSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 120, width: contentWidth, height: 120))
        colorSettingsBox.title = "Настройки цвета"
        colorSettingsBox.titlePosition = .atTop
        colorSettingsBox.isTransparent = false
        view.addSubview(colorSettingsBox)
        
        // Контент в боксе настроек цвета
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 90
        
        // Создаем слайдеры для настройки параметров цвета
        let blueMinLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        blueMinLabel.stringValue = "Мин. Blue (≥):"
        blueMinLabel.isEditable = false
        blueMinLabel.isBordered = false
        blueMinLabel.drawsBackground = false
        colorSettingsBox.addSubview(blueMinLabel)
        
        blueMinSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        blueMinSlider.minValue = 0
        blueMinSlider.maxValue = 255
        blueMinSlider.intValue = Int32(Config.blueMinValue)
        blueMinSlider.target = self
        blueMinSlider.action = #selector(colorSettingsChanged)
        colorSettingsBox.addSubview(blueMinSlider)
        
        let blueMinValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        blueMinValueLabel.stringValue = "\(Config.blueMinValue)"
        blueMinValueLabel.isEditable = false
        blueMinValueLabel.isBordered = false
        blueMinValueLabel.drawsBackground = false
        blueMinValueLabel.tag = 201
        colorSettingsBox.addSubview(blueMinValueLabel)
        
        boxYPos -= 25
        
        // Слайдер для красного канала
        let redMaxLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        redMaxLabel.stringValue = "Макс. Red (≤):"
        redMaxLabel.isEditable = false
        redMaxLabel.isBordered = false
        redMaxLabel.drawsBackground = false
        colorSettingsBox.addSubview(redMaxLabel)
        
        redMaxSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        redMaxSlider.minValue = 0
        redMaxSlider.maxValue = 255
        redMaxSlider.intValue = Int32(Config.redMaxValue)
        redMaxSlider.target = self
        redMaxSlider.action = #selector(colorSettingsChanged)
        colorSettingsBox.addSubview(redMaxSlider)
        
        let redMaxValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        redMaxValueLabel.stringValue = "\(Config.redMaxValue)"
        redMaxValueLabel.isEditable = false
        redMaxValueLabel.isBordered = false
        redMaxValueLabel.drawsBackground = false
        redMaxValueLabel.tag = 202
        colorSettingsBox.addSubview(redMaxValueLabel)
        
        boxYPos -= 25
        
        // Слайдер для зеленого канала
        let greenMaxLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        greenMaxLabel.stringValue = "Макс. Green (≤):"
        greenMaxLabel.isEditable = false
        greenMaxLabel.isBordered = false
        greenMaxLabel.drawsBackground = false
        colorSettingsBox.addSubview(greenMaxLabel)
        
        greenMaxSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        greenMaxSlider.minValue = 0
        greenMaxSlider.maxValue = 255
        greenMaxSlider.intValue = Int32(Config.greenMaxValue)
        greenMaxSlider.target = self
        greenMaxSlider.action = #selector(colorSettingsChanged)
        colorSettingsBox.addSubview(greenMaxSlider)
        
        let greenMaxValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        greenMaxValueLabel.stringValue = "\(Config.greenMaxValue)"
        greenMaxValueLabel.isEditable = false
        greenMaxValueLabel.isBordered = false
        greenMaxValueLabel.drawsBackground = false
        greenMaxValueLabel.tag = 203
        colorSettingsBox.addSubview(greenMaxValueLabel)
        
        boxYPos -= 25
        
        // Слайдер для минимального количества пикселей
        let minBluePixelsLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        minBluePixelsLabel.stringValue = "Мин. пикселей:"
        minBluePixelsLabel.isEditable = false
        minBluePixelsLabel.isBordered = false
        minBluePixelsLabel.drawsBackground = false
        colorSettingsBox.addSubview(minBluePixelsLabel)
        
        minBluePixelsSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        minBluePixelsSlider.minValue = 1
        minBluePixelsSlider.maxValue = 100
        minBluePixelsSlider.intValue = Int32(Config.minBluePixels)
        minBluePixelsSlider.target = self
        minBluePixelsSlider.action = #selector(colorSettingsChanged)
        colorSettingsBox.addSubview(minBluePixelsSlider)
        
        let minBluePixelsValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        minBluePixelsValueLabel.stringValue = "\(Config.minBluePixels)"
        minBluePixelsValueLabel.isEditable = false
        minBluePixelsValueLabel.isBordered = false
        minBluePixelsValueLabel.drawsBackground = false
        minBluePixelsValueLabel.tag = 204
        colorSettingsBox.addSubview(minBluePixelsValueLabel)
        
        // Обновляем позицию Y для следующего бокса
        yPos -= 120 + 10
    }
    
    private func setupMovementSettingsBox(margin: CGFloat, contentWidth: CGFloat, yPos: inout CGFloat) {
        // Создаем бокс настроек движения
        movementSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 80, width: contentWidth, height: 80))
        movementSettingsBox.title = "Настройки движения"
        movementSettingsBox.titlePosition = .atTop
        movementSettingsBox.isTransparent = false
        view.addSubview(movementSettingsBox)
        
        // Контент в боксе настроек движения
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 50
        
        // Слайдер для порога движения
        let thresholdLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        thresholdLabel.stringValue = "Порог движения:"
        thresholdLabel.isEditable = false
        thresholdLabel.isBordered = false
        thresholdLabel.drawsBackground = false
        movementSettingsBox.addSubview(thresholdLabel)
        
        movementThresholdSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        movementThresholdSlider.minValue = 1
        movementThresholdSlider.maxValue = 20
        movementThresholdSlider.floatValue = Float(Config.movementThreshold)
        movementThresholdSlider.target = self
        movementThresholdSlider.action = #selector(movementSettingsChanged)
        movementSettingsBox.addSubview(movementThresholdSlider)
        
        let thresholdValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        thresholdValueLabel.stringValue = "\(Config.movementThreshold)"
        thresholdValueLabel.isEditable = false
        thresholdValueLabel.isBordered = false
        thresholdValueLabel.drawsBackground = false
        thresholdValueLabel.tag = 301
        movementSettingsBox.addSubview(thresholdValueLabel)
        
        boxYPos -= 25
        
        // Слайдер для коэффициента сглаживания
        let smoothingLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 120, height: 20))
        smoothingLabel.stringValue = "Сглаживание:"
        smoothingLabel.isEditable = false
        smoothingLabel.isBordered = false
        smoothingLabel.drawsBackground = false
        movementSettingsBox.addSubview(smoothingLabel)
        
        smoothingFactorSlider = NSSlider(frame: NSRect(
            x: boxMargin + 130,
            y: boxYPos,
            width: boxContentWidth - 130 - 40,
            height: 20
        ))
        smoothingFactorSlider.minValue = 0.1
        smoothingFactorSlider.maxValue = 0.9
        smoothingFactorSlider.floatValue = Float(Config.smoothingFactor)
        smoothingFactorSlider.target = self
        smoothingFactorSlider.action = #selector(movementSettingsChanged)
        movementSettingsBox.addSubview(smoothingFactorSlider)
        
        let smoothingValueLabel = NSTextField(frame: NSRect(
            x: boxMargin + boxContentWidth - 40,
            y: boxYPos,
            width: 40,
            height: 20
        ))
        smoothingValueLabel.stringValue = String(format: "%.1f", Config.smoothingFactor)
        smoothingValueLabel.isEditable = false
        smoothingValueLabel.isBordered = false
        smoothingValueLabel.drawsBackground = false
        smoothingValueLabel.tag = 302
        movementSettingsBox.addSubview(smoothingValueLabel)
        
        boxYPos -= 25
        
        // Чекбокс для прогнозирования движения
        useMotionPredictionCheckbox = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: boxContentWidth, height: 20))
        useMotionPredictionCheckbox.title = "Использовать прогнозирование движения"
        useMotionPredictionCheckbox.state = Config.useMotionPrediction ? .on : .off
        useMotionPredictionCheckbox.setButtonType(.switch)
        useMotionPredictionCheckbox.target = self
        useMotionPredictionCheckbox.action = #selector(motionPredictionChanged)
        movementSettingsBox.addSubview(useMotionPredictionCheckbox)
        
        // Обновляем позицию Y для следующего бокса
        yPos -= 80 + 10
    }
    
    private func setupDebugSettingsBox(margin: CGFloat, contentWidth: CGFloat, yPos: inout CGFloat) {
        // Создаем бокс настроек отладки
        debugSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 50, width: contentWidth, height: 50))
        debugSettingsBox.title = "Отладка"
        debugSettingsBox.titlePosition = .atTop
        debugSettingsBox.isTransparent = false
        view.addSubview(debugSettingsBox)
        
        // Контент в боксе настроек отладки
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        let boxYPos: CGFloat = 20
        
        // Чекбокс для отображения подсветки
        showDebugOverlayCheckbox = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: boxContentWidth, height: 20))
        showDebugOverlayCheckbox.title = "Показывать подсветку области захвата"
        showDebugOverlayCheckbox.state = Config.showHighlight ? .on : .off
        showDebugOverlayCheckbox.setButtonType(.switch)
        showDebugOverlayCheckbox.target = self
        showDebugOverlayCheckbox.action = #selector(showHighlightChanged)
        debugSettingsBox.addSubview(showDebugOverlayCheckbox)
        
        // Обновляем позицию Y для следующего элемента
        yPos -= 50 + 10
    }
} 