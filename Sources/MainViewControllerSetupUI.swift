import Cocoa

extension MainViewController {
    
    // MARK: - Настройка UI элементов
    
    func setupColorSettingsUI() {
        // Создаем отступы
        let margin: CGFloat = 20
        let contentWidth = view.frame.width - (margin * 2)
        var yPos = view.frame.height - 210  // Начальная позиция Y после captureSettingsBox
        
        // Создаем бокс настроек цвета
        colorSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 120, width: contentWidth, height: 120))
        colorSettingsBox.title = "Настройки цвета"
        colorSettingsBox.titlePosition = .atTop
        // Заменяем borderType на transparent
        colorSettingsBox.transparent = false
        view.addSubview(colorSettingsBox)
        
        // Контент в боксе настроек цвета
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 90
        
        // Минимальное значение синего компонента
        let blueMinLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        blueMinLabel.stringValue = "Мин. синий компонент:"
        blueMinLabel.isEditable = false
        blueMinLabel.isBordered = false
        blueMinLabel.drawsBackground = false
        colorSettingsBox.addSubview(blueMinLabel)
        
        let blueMinValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        blueMinValueLabel.stringValue = "\(Config.blueThreshold)"
        blueMinValueLabel.isEditable = false
        blueMinValueLabel.isBordered = false
        blueMinValueLabel.drawsBackground = false
        colorSettingsBox.addSubview(blueMinValueLabel)
        
        blueMinSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        blueMinSlider.minValue = 1
        blueMinSlider.maxValue = 254
        blueMinSlider.intValue = Int32(Config.blueThreshold)
        blueMinSlider.target = self
        blueMinSlider.action = #selector(blueMinSliderChanged)
        colorSettingsBox.addSubview(blueMinSlider)
        
        boxYPos -= 25
        
        // Максимальное значение красного компонента
        let redMaxLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        redMaxLabel.stringValue = "Макс. красный комп.:"
        redMaxLabel.isEditable = false
        redMaxLabel.isBordered = false
        redMaxLabel.drawsBackground = false
        colorSettingsBox.addSubview(redMaxLabel)
        
        let redMaxValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        redMaxValueLabel.stringValue = "\(Config.redThreshold)"
        redMaxValueLabel.isEditable = false
        redMaxValueLabel.isBordered = false
        redMaxValueLabel.drawsBackground = false
        colorSettingsBox.addSubview(redMaxValueLabel)
        
        redMaxSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        redMaxSlider.minValue = 1
        redMaxSlider.maxValue = 254
        redMaxSlider.intValue = Int32(Config.redThreshold)
        redMaxSlider.target = self
        redMaxSlider.action = #selector(redMaxSliderChanged)
        colorSettingsBox.addSubview(redMaxSlider)
        
        boxYPos -= 25
        
        // Максимальное значение зеленого компонента
        let greenMaxLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        greenMaxLabel.stringValue = "Макс. зеленый комп.:"
        greenMaxLabel.isEditable = false
        greenMaxLabel.isBordered = false
        greenMaxLabel.drawsBackground = false
        colorSettingsBox.addSubview(greenMaxLabel)
        
        let greenMaxValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        greenMaxValueLabel.stringValue = "\(Config.greenThreshold)"
        greenMaxValueLabel.isEditable = false
        greenMaxValueLabel.isBordered = false
        greenMaxValueLabel.drawsBackground = false
        colorSettingsBox.addSubview(greenMaxValueLabel)
        
        greenMaxSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        greenMaxSlider.minValue = 1
        greenMaxSlider.maxValue = 254
        greenMaxSlider.intValue = Int32(Config.greenThreshold)
        greenMaxSlider.target = self
        greenMaxSlider.action = #selector(greenMaxSliderChanged)
        colorSettingsBox.addSubview(greenMaxSlider)
        
        boxYPos -= 25
        
        // Минимальное количество синих пикселей
        let minBluePixelsLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        minBluePixelsLabel.stringValue = "Мин. синих пикселей:"
        minBluePixelsLabel.isEditable = false
        minBluePixelsLabel.isBordered = false
        minBluePixelsLabel.drawsBackground = false
        colorSettingsBox.addSubview(minBluePixelsLabel)
        
        let minBluePixelsValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        minBluePixelsValueLabel.stringValue = "\(Config.minBluePixelsThreshold)"
        minBluePixelsValueLabel.isEditable = false
        minBluePixelsValueLabel.isBordered = false
        minBluePixelsValueLabel.drawsBackground = false
        colorSettingsBox.addSubview(minBluePixelsValueLabel)
        
        minBluePixelsSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        minBluePixelsSlider.minValue = 1
        minBluePixelsSlider.maxValue = 1000
        minBluePixelsSlider.intValue = Int32(Config.minBluePixelsThreshold)
        minBluePixelsSlider.target = self
        minBluePixelsSlider.action = #selector(minBluePixelsSliderChanged)
        colorSettingsBox.addSubview(minBluePixelsSlider)
        
        // Обновляем текущую позицию Y для следующего бокса
        yPos -= 130
    }
    
    func setupMovementSettingsUI() {
        // Создаем отступы
        let margin: CGFloat = 20
        let contentWidth = view.frame.width - (margin * 2)
        var yPos = view.frame.height - 340  // Начальная позиция Y после colorSettingsBox
        
        // Создаем бокс настроек перемещения
        movementSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 100, width: contentWidth, height: 100))
        movementSettingsBox.title = "Настройки перемещения"
        movementSettingsBox.titlePosition = .atTop
        // Заменяем borderType на transparent
        movementSettingsBox.transparent = false
        view.addSubview(movementSettingsBox)
        
        // Контент в боксе настроек перемещения
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 70
        
        // Порог перемещения
        let movementThresholdLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        movementThresholdLabel.stringValue = "Порог перемещения:"
        movementThresholdLabel.isEditable = false
        movementThresholdLabel.isBordered = false
        movementThresholdLabel.drawsBackground = false
        movementSettingsBox.addSubview(movementThresholdLabel)
        
        let movementThresholdValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        movementThresholdValueLabel.stringValue = "\(Config.movementThreshold)"
        movementThresholdValueLabel.isEditable = false
        movementThresholdValueLabel.isBordered = false
        movementThresholdValueLabel.drawsBackground = false
        movementSettingsBox.addSubview(movementThresholdValueLabel)
        
        movementThresholdSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        movementThresholdSlider.minValue = 1
        movementThresholdSlider.maxValue = 50
        movementThresholdSlider.intValue = Int32(Config.movementThreshold)
        movementThresholdSlider.target = self
        movementThresholdSlider.action = #selector(movementThresholdSliderChanged)
        movementSettingsBox.addSubview(movementThresholdSlider)
        
        boxYPos -= 25
        
        // Фактор сглаживания
        let smoothingFactorLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos, width: 130, height: 20))
        smoothingFactorLabel.stringValue = "Сглаживание:"
        smoothingFactorLabel.isEditable = false
        smoothingFactorLabel.isBordered = false
        smoothingFactorLabel.drawsBackground = false
        movementSettingsBox.addSubview(smoothingFactorLabel)
        
        let smoothingFactorValueLabel = NSTextField(frame: NSRect(x: boxMargin + 135, y: boxYPos, width: 30, height: 20))
        smoothingFactorValueLabel.stringValue = String(format: "%.1f", Config.smoothingFactor)
        smoothingFactorValueLabel.isEditable = false
        smoothingFactorValueLabel.isBordered = false
        smoothingFactorValueLabel.drawsBackground = false
        movementSettingsBox.addSubview(smoothingFactorValueLabel)
        
        smoothingFactorSlider = NSSlider(frame: NSRect(x: boxMargin + 170, y: boxYPos, width: boxContentWidth - 170, height: 20))
        smoothingFactorSlider.minValue = 0
        smoothingFactorSlider.maxValue = 0.9
        smoothingFactorSlider.doubleValue = Double(Config.smoothingFactor)
        smoothingFactorSlider.target = self
        smoothingFactorSlider.action = #selector(smoothingFactorSliderChanged)
        movementSettingsBox.addSubview(smoothingFactorSlider)
        
        boxYPos -= 25
        
        // Использовать предсказание движения
        useMotionPredictionCheckbox = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: boxContentWidth, height: 20))
        useMotionPredictionCheckbox.title = "Использовать предсказание движения"
        useMotionPredictionCheckbox.setButtonType(.switch)
        useMotionPredictionCheckbox.state = Config.useMotionPrediction ? .on : .off
        useMotionPredictionCheckbox.target = self
        useMotionPredictionCheckbox.action = #selector(useMotionPredictionToggled)
        movementSettingsBox.addSubview(useMotionPredictionCheckbox)
        
        // Обновляем текущую позицию Y для следующего бокса
        yPos -= 110
    }
    
    func setupGameModeSettingsUI() {
        // Создаем отступы
        let margin: CGFloat = 20
        let contentWidth = view.frame.width - (margin * 2)
        var yPos = view.frame.height - 450  // Начальная позиция Y после movementSettingsBox
        
        // Создаем бокс настроек игрового режима
        gameModeSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 80, width: contentWidth, height: 80))
        gameModeSettingsBox.title = "Игровой режим"
        gameModeSettingsBox.titlePosition = .atTop
        // Заменяем borderType на transparent
        gameModeSettingsBox.transparent = false
        view.addSubview(gameModeSettingsBox)
        
        // Контент в боксе настроек игрового режима
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        var boxYPos: CGFloat = 50
        
        // Включение игрового режима
        gameModeCheckbox = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: boxContentWidth / 2, height: 20))
        gameModeCheckbox.title = "Включить игровой режим"
        gameModeCheckbox.setButtonType(.switch)
        gameModeCheckbox.state = Config.gameMode ? .on : .off
        gameModeCheckbox.target = self
        gameModeCheckbox.action = #selector(gameModeToggled)
        gameModeSettingsBox.addSubview(gameModeCheckbox)
        
        // Установка границ игры
        gameBoundsButton = NSButton(frame: NSRect(x: boxMargin + boxContentWidth / 2, y: boxYPos, width: boxContentWidth / 2, height: 20))
        gameBoundsButton.title = "Установить границы игры"
        gameBoundsButton.bezelStyle = .rounded
        gameBoundsButton.target = self
        gameBoundsButton.action = #selector(gameBoundsButtonClicked)
        gameModeSettingsBox.addSubview(gameBoundsButton)
        
        boxYPos -= 25
        
        // Информация об игровом режиме
        gameModeInfoLabel = NSTextField(frame: NSRect(x: boxMargin, y: boxYPos - 10, width: boxContentWidth, height: 30))
        gameModeInfoLabel.stringValue = "Игровой режим ограничивает курсор в пределах определенной области."
        gameModeInfoLabel.isEditable = false
        gameModeInfoLabel.isBordered = false
        gameModeInfoLabel.drawsBackground = false
        gameModeInfoLabel.usesSingleLineMode = false
        gameModeInfoLabel.cell?.wraps = true
        gameModeSettingsBox.addSubview(gameModeInfoLabel)
        
        // Обновляем текущую позицию Y для следующего бокса
        yPos -= 90
    }
    
    func setupDebugSettingsUI() {
        // Создаем отступы
        let margin: CGFloat = 20
        let contentWidth = view.frame.width - (margin * 2)
        var yPos = view.frame.height - 540  // Начальная позиция Y после gameModeSettingsBox
        
        // Создаем бокс настроек отладки
        debugSettingsBox = NSBox(frame: NSRect(x: margin, y: yPos - 50, width: contentWidth, height: 50))
        debugSettingsBox.title = "Отладка"
        debugSettingsBox.titlePosition = .atTop
        // Заменяем borderType на transparent
        debugSettingsBox.transparent = false
        view.addSubview(debugSettingsBox)
        
        // Контент в боксе настроек отладки
        let boxMargin: CGFloat = 10
        let boxContentWidth = contentWidth - (boxMargin * 2)
        let boxYPos: CGFloat = 20
        
        // Показать отладочное наложение
        showDebugOverlayCheckbox = NSButton(frame: NSRect(x: boxMargin, y: boxYPos, width: boxContentWidth, height: 20))
        showDebugOverlayCheckbox.title = "Показать отладочную информацию"
        showDebugOverlayCheckbox.setButtonType(.switch)
        showDebugOverlayCheckbox.state = Config.showDebugOverlay ? .on : .off
        showDebugOverlayCheckbox.target = self
        showDebugOverlayCheckbox.action = #selector(showDebugOverlayToggled)
        debugSettingsBox.addSubview(showDebugOverlayCheckbox)
    }
    
    // MARK: - Event handlers
    
    @objc func blueMinSliderChanged() {
        let value = blueMinSlider.intValue
        Config.blueThreshold = Int(value)
        // Обновляем текст с текущим значением
        if let valueLabel = colorSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 90 
        }) as? NSTextField {
            valueLabel.stringValue = "\(Config.blueThreshold)"
        }
        applySettings()
    }
    
    @objc func redMaxSliderChanged() {
        let value = redMaxSlider.intValue
        Config.redThreshold = Int(value)
        // Обновляем текст с текущим значением
        if let valueLabel = colorSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 65 
        }) as? NSTextField {
            valueLabel.stringValue = "\(Config.redThreshold)"
        }
        applySettings()
    }
    
    @objc func greenMaxSliderChanged() {
        let value = greenMaxSlider.intValue
        Config.greenThreshold = Int(value)
        // Обновляем текст с текущим значением
        if let valueLabel = colorSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 40 
        }) as? NSTextField {
            valueLabel.stringValue = "\(Config.greenThreshold)"
        }
        applySettings()
    }
    
    @objc func minBluePixelsSliderChanged() {
        let value = minBluePixelsSlider.intValue
        Config.minBluePixelsThreshold = Int(value)
        // Обновляем текст с текущим значением
        if let valueLabel = colorSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 15 
        }) as? NSTextField {
            valueLabel.stringValue = "\(Config.minBluePixelsThreshold)"
        }
        applySettings()
    }
    
    @objc func movementThresholdSliderChanged() {
        let value = movementThresholdSlider.intValue
        Config.movementThreshold = Int(value)
        // Обновляем текст с текущим значением
        if let valueLabel = movementSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 70 
        }) as? NSTextField {
            valueLabel.stringValue = "\(Config.movementThreshold)"
        }
        applySettings()
    }
    
    @objc func smoothingFactorSliderChanged() {
        let value = smoothingFactorSlider.doubleValue
        Config.smoothingFactor = Float(value)
        // Обновляем текст с текущим значением
        if let valueLabel = movementSettingsBox.subviews.first(where: { 
            ($0 as? NSTextField)?.frame.origin.x == 10 + 135 && ($0 as? NSTextField)?.frame.origin.y == 45 
        }) as? NSTextField {
            valueLabel.stringValue = String(format: "%.1f", Config.smoothingFactor)
        }
        applySettings()
    }
    
    @objc func useMotionPredictionToggled() {
        Config.useMotionPrediction = useMotionPredictionCheckbox.state == .on
        applySettings()
    }
    
    @objc func gameModeToggled() {
        Config.gameMode = gameModeCheckbox.state == .on
        applySettings()
        
        // Если включен игровой режим, проверяем, установлены ли границы
        if Config.gameMode && (Config.gameBounds.width == 0 || Config.gameBounds.height == 0) {
            // Если границы не установлены, предлагаем пользователю установить их
            gameModeInfoLabel.stringValue = "Пожалуйста, установите границы игры!"
            gameModeInfoLabel.textColor = NSColor.red
        } else {
            gameModeInfoLabel.stringValue = "Игровой режим ограничивает курсор в пределах определенной области."
            gameModeInfoLabel.textColor = NSColor.textColor
        }
    }
    
    @objc func gameBoundsButtonClicked() {
        // Создаем окно выбора области для игровых границ
        let selectionWindow = AreaSelectionWindow()
        selectionWindow.title = "Выберите границы игры"
        selectionWindow.onSelectionComplete = { [weak self] rect in
            Config.gameBounds = rect
            self?.applySettings()
        }
        selectionWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func showDebugOverlayToggled() {
        Config.showDebugOverlay = showDebugOverlayCheckbox.state == .on
        applySettings()
        
        if Config.showDebugOverlay {
            createDebugOverlay()
        } else {
            removeDebugOverlay()
        }
    }
    
    private func createDebugOverlay() {
        if debugOverlayWindow == nil {
            let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            let windowRect = NSRect(x: screenRect.width - 250, y: screenRect.height - 200, width: 240, height: 190)
            
            debugOverlayWindow = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .resizable, .utility],
                backing: .buffered,
                defer: false)
            
            debugOverlayWindow?.title = "Отладка"
            debugOverlayWindow?.level = .floating
            debugOverlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            debugOverlayWindow?.isOpaque = false
            debugOverlayWindow?.backgroundColor = NSColor.clear
            
            debugOverlayView = DebugOverlayView(frame: NSRect(x: 0, y: 0, width: windowRect.width, height: windowRect.height))
            debugOverlayView?.tracker = tracker
            debugOverlayWindow?.contentView = debugOverlayView
            
            debugOverlayWindow?.makeKeyAndOrderFront(nil)
        }
    }
    
    private func removeDebugOverlay() {
        debugOverlayWindow?.close()
        debugOverlayWindow = nil
        debugOverlayView = nil
    }
} 