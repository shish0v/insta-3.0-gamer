import Cocoa

extension MainViewController {
    // MARK: - Утилиты и вспомогательные методы
    
    /// Обновляет UI на основе текущих настроек
    func updateUIFromSettings() {
        // Обновляем поля координат
        xField.doubleValue = Config.captureRect.origin.x
        yField.doubleValue = Config.captureRect.origin.y
        widthField.doubleValue = Config.captureRect.width
        heightField.doubleValue = Config.captureRect.height
        
        // Обновляем слайдеры цвета
        blueMinSlider.intValue = Int32(Config.blueMinValue)
        redMaxSlider.intValue = Int32(Config.redMaxValue)
        greenMaxSlider.intValue = Int32(Config.greenMaxValue)
        minBluePixelsSlider.intValue = Int32(Config.minBluePixels)
        
        // Обновляем метки значений цвета
        if let blueMinLabel = view.viewWithTag(201) as? NSTextField {
            blueMinLabel.stringValue = "\(Config.blueMinValue)"
        }
        
        if let redMaxLabel = view.viewWithTag(202) as? NSTextField {
            redMaxLabel.stringValue = "\(Config.redMaxValue)"
        }
        
        if let greenMaxLabel = view.viewWithTag(203) as? NSTextField {
            greenMaxLabel.stringValue = "\(Config.greenMaxValue)"
        }
        
        if let minBluePixelsLabel = view.viewWithTag(204) as? NSTextField {
            minBluePixelsLabel.stringValue = "\(Config.minBluePixels)"
        }
        
        // Обновляем слайдеры движения
        movementThresholdSlider.floatValue = Float(Config.movementThreshold)
        smoothingFactorSlider.floatValue = Float(Config.smoothingFactor)
        
        // Обновляем метки значений движения
        if let thresholdLabel = view.viewWithTag(301) as? NSTextField {
            thresholdLabel.stringValue = "\(Config.movementThreshold)"
        }
        
        if let smoothingLabel = view.viewWithTag(302) as? NSTextField {
            smoothingLabel.stringValue = String(format: "%.1f", Config.smoothingFactor)
        }
        
        // Обновляем чекбоксы
        useMotionPredictionCheckbox.state = Config.useMotionPrediction ? .on : .off
        showDebugOverlayCheckbox.state = Config.showHighlight ? .on : .off
        
        // Обновляем режим отслеживания
        trackingModeSegment.selectedSegment = Config.useWindowMode ? 1 : 0
        
        // Обновляем видимость элементов интерфейса
        updateTrackingModeUI()
    }
    
    /// Обновляет настройки на основе текущих значений в UI
    func updateSettingsFromUI() {
        // Получаем координаты из полей
        Config.captureRect = CGRect(
            x: xField.doubleValue,
            y: yField.doubleValue,
            width: widthField.doubleValue,
            height: heightField.doubleValue
        )
        
        // Получаем настройки цвета из слайдеров
        Config.blueMinValue = UInt8(blueMinSlider.intValue)
        Config.redMaxValue = UInt8(redMaxSlider.intValue)
        Config.greenMaxValue = UInt8(greenMaxSlider.intValue)
        Config.minBluePixels = Int(minBluePixelsSlider.intValue)
        
        // Получаем настройки движения из слайдеров
        Config.movementThreshold = CGFloat(movementThresholdSlider.floatValue)
        Config.smoothingFactor = CGFloat(smoothingFactorSlider.floatValue)
        
        // Получаем настройки из чекбоксов
        Config.useMotionPrediction = useMotionPredictionCheckbox.state == .on
        Config.showHighlight = showDebugOverlayCheckbox.state == .on
        
        // Сохраняем настройки
        Config.saveSettings()
        
        // Логируем текущие настройки
        Config.logCurrentSettings()
    }
    
    /// Обновляет список доступных экранов
    func updateScreenList() {
        screenPopup.removeAllItems()
        
        for (index, screen) in NSScreen.screens.enumerated() {
            let screenId = "\(index + 1)"
            let screenResolution = String(format: "%.0fx%.0f", screen.frame.width, screen.frame.height)
            let screenItem = "\(screenId): \(screenResolution)"
            screenPopup.addItem(withTitle: screenItem)
            
            // Если текущий экран является выбранным, выбираем его в выпадающем списке
            if screen == Config.selectedScreen {
                screenPopup.selectItem(at: index)
            }
        }
        
        // Если экраны есть, но выбранный не найден, выбираем первый
        if !NSScreen.screens.isEmpty && screenPopup.indexOfSelectedItem == -1 {
            screenPopup.selectItem(at: 0)
            Config.selectedScreen = NSScreen.screens[0]
        }
        
        updateScreenCoordinates()
    }
    
    /// Обновляет список доступных окон
    func updateWindowList() {
        windowPopup.removeAllItems()
        
        // Получаем список окон
        let windows = WindowManager.getActiveWindows()
        
        // Добавляем окна в выпадающий список
        for (index, window) in windows.enumerated() {
            windowPopup.addItem(withTitle: window.displayName)
            
            // Если текущее окно является выбранным, выбираем его в выпадающем списке
            if window.windowID == Config.selectedWindowID {
                windowPopup.selectItem(at: index)
            }
        }
        
        // Если окна есть, но выбранное не найдено, выбираем первое
        if !windows.isEmpty && windowPopup.indexOfSelectedItem == -1 {
            windowPopup.selectItem(at: 0)
            Config.selectedWindowID = windows[0].windowID
            Config.selectedWindowName = windows[0].name
            Config.currentWindowBounds = windows[0].bounds
            
            // Обновляем поля координат
            xField.doubleValue = windows[0].bounds.origin.x
            yField.doubleValue = windows[0].bounds.origin.y
            widthField.doubleValue = windows[0].bounds.width
            heightField.doubleValue = windows[0].bounds.height
        }
    }
    
    /// Обновляет UI в зависимости от выбранного режима отслеживания
    func updateTrackingModeUI() {
        let useWindowMode = trackingModeSegment.selectedSegment == 1
        
        // Обновляем видимость элементов для экрана
        view.subviews.forEach { subview in
            if subview.tag == 101 { // элементы для экрана
                subview.isHidden = useWindowMode
            } else if subview.tag == 102 { // элементы для окна
                subview.isHidden = !useWindowMode
            }
        }
        
        captureSettingsBox.subviews.forEach { subview in
            if subview.tag == 101 { // элементы для экрана
                subview.isHidden = useWindowMode
            } else if subview.tag == 102 { // элементы для окна
                subview.isHidden = !useWindowMode
            }
        }
        
        // Кнопка выбора области визуально доступна только в режиме экрана
        selectAreaButton.isHidden = useWindowMode
    }
    
    /// Обновляет координаты на основе выбранного экрана
    func updateScreenCoordinates() {
        guard let selectedScreen = getSelectedScreen() else { return }
        
        // Предлагаем использовать весь экран в качестве области захвата
        xField.doubleValue = selectedScreen.frame.origin.x
        yField.doubleValue = selectedScreen.frame.origin.y
        widthField.doubleValue = selectedScreen.frame.width
        heightField.doubleValue = selectedScreen.frame.height
    }
    
    /// Возвращает выбранный экран
    func getSelectedScreen() -> NSScreen? {
        let selectedIndex = screenPopup.indexOfSelectedItem
        if selectedIndex >= 0 && selectedIndex < NSScreen.screens.count {
            return NSScreen.screens[selectedIndex]
        }
        return NSScreen.main
    }
    
    /// Возвращает выбранное окно
    func getSelectedWindow() -> WindowManager.WindowInfo? {
        let selectedIndex = windowPopup.indexOfSelectedItem
        let windows = WindowManager.getActiveWindows()
        
        if selectedIndex >= 0 && selectedIndex < windows.count {
            return windows[selectedIndex]
        }
        return nil
    }
    
    // MARK: - Обработчики событий UI
    
    @objc func colorSettingsChanged() {
        // Обновляем метки значений
        if let blueMinLabel = view.viewWithTag(201) as? NSTextField {
            blueMinLabel.stringValue = "\(blueMinSlider.intValue)"
        }
        
        if let redMaxLabel = view.viewWithTag(202) as? NSTextField {
            redMaxLabel.stringValue = "\(redMaxSlider.intValue)"
        }
        
        if let greenMaxLabel = view.viewWithTag(203) as? NSTextField {
            greenMaxLabel.stringValue = "\(greenMaxSlider.intValue)"
        }
        
        if let minBluePixelsLabel = view.viewWithTag(204) as? NSTextField {
            minBluePixelsLabel.stringValue = "\(minBluePixelsSlider.intValue)"
        }
    }
    
    @objc func movementSettingsChanged() {
        // Обновляем метки значений
        if let thresholdLabel = view.viewWithTag(301) as? NSTextField {
            thresholdLabel.stringValue = String(format: "%.1f", movementThresholdSlider.floatValue)
        }
        
        if let smoothingLabel = view.viewWithTag(302) as? NSTextField {
            smoothingLabel.stringValue = String(format: "%.1f", smoothingFactorSlider.floatValue)
        }
    }
    
    @objc func motionPredictionChanged() {
        Config.useMotionPrediction = useMotionPredictionCheckbox.state == .on
    }
    
    @objc func showHighlightChanged() {
        Config.showHighlight = showDebugOverlayCheckbox.state == .on
        
        if tracker.isRunning {
            if Config.showHighlight {
                showDebugOverlay()
            } else {
                hideDebugOverlay()
            }
        }
    }
    
    @objc func selectAreaButtonClicked() {
        // Реализация выбора области захвата визуально
        Logger.shared.log("Запуск визуального выбора области захвата")
        
        // Здесь должен быть код для визуального выбора области экрана
        // ...
    }
    
    // MARK: - Работа с оверлеем отладки
    
    func showDebugOverlay() {
        // Если окно отладки уже есть, просто отображаем его
        if debugOverlayWindow != nil {
            debugOverlayWindow?.orderFront(nil)
            return
        }
        
        // Создаем окно оверлея для отладки
        let rect = Config.captureRect
        debugOverlayWindow = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = debugOverlayWindow else { return }
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Создаем view для оверлея
        debugOverlayView = DebugOverlayView(frame: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        window.contentView = debugOverlayView
        
        window.orderFront(nil)
        
        Logger.shared.log("Отображен оверлей отладки")
    }
    
    func hideDebugOverlay() {
        debugOverlayWindow?.orderOut(nil)
        Logger.shared.log("Скрыт оверлей отладки")
    }
    
    func updateDebugOverlay() {
        guard let window = debugOverlayWindow, Config.showHighlight else { return }
        
        // Обновляем положение и размеры окна оверлея
        let rect = Config.captureRect
        window.setFrame(rect, display: true)
        
        // Обновляем размеры вью оверлея
        debugOverlayView?.frame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        debugOverlayView?.needsDisplay = true
    }
    
    // MARK: - Разрешения
    
    func requestScreenCapturePermission() {
        // Запрашиваем разрешение на запись экрана
        // Для macOS > 10.15 требуется запросить разрешение
        
        // Создаем простой запрос на захват экрана, чтобы вызвать диалог разрешений
        let displayID = CGMainDisplayID()
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // Просто пробуем создать скриншот, что вызовет запрос разрешения при первом запуске
        let _ = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
        
        Logger.shared.log("Запрошено разрешение на запись экрана")
    }
}

// MARK: - Класс для отображения отладочного оверлея

class DebugOverlayView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.blue.withAlphaComponent(0.2).set()
        dirtyRect.fill()
        
        NSColor.blue.set()
        let borderPath = NSBezierPath(rect: bounds)
        borderPath.lineWidth = 2.0
        borderPath.stroke()
    }
} 