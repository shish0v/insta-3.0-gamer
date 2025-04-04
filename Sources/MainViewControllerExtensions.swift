import Cocoa

extension MainViewController {
    
    // MARK: - UI Visibility
    
    @objc func updateUIVisibility() {
        // Обновляем видимость элементов на основе режима захвата
        let isWindowMode = trackingModeSegment.selectedSegment == 1
        
        // Элементы для режима области экрана
        for view in captureSettingsBox.subviews where view.tag == 101 {
            view.isHidden = isWindowMode
        }
        
        // Элементы для режима окна
        for view in captureSettingsBox.subviews where view.tag == 102 {
            view.isHidden = !isWindowMode
        }
        
        // Обновляем списки экранов и окон
        updateScreensList()
        updateWindowsList()
    }
    
    // MARK: - Button Actions
    
    @objc func startStopButtonClicked() {
        if !tracker.isRunning {
            // Проверяем разрешение на запись экрана
            if !requestScreenCapturePermission() {
                return
            }
            
            // Сохраняем настройки из полей ввода
            applySettings()
            
            // Запускаем отслеживание
            tracker.startTracking()
            startStopButton.title = "⏹ Остановить отслеживание"
        } else {
            // Останавливаем отслеживание
            tracker.stopTracking()
            startStopButton.title = "▶️ Запустить отслеживание"
        }
    }
    
    @objc func quitButtonClicked() {
        NSApp.terminate(nil)
    }
    
    @objc func trackingModeChanged() {
        Config.useWindowMode = trackingModeSegment.selectedSegment == 1
        updateUIVisibility()
        applySettings()
    }
    
    @objc func screenSelected() {
        guard let selectedScreenItem = screenPopup.selectedItem else { return }
        
        for (index, screen) in NSScreen.screens.enumerated() {
            if selectedScreenItem.title == "Экран \(index + 1)" {
                Config.selectedScreenIndex = index
                
                // Обновляем поля координат на основе выбранного экрана
                let screenFrame = screen.frame
                xField.stringValue = "0"
                yField.stringValue = "0"
                widthField.stringValue = String(format: "%.0f", screenFrame.width)
                heightField.stringValue = String(format: "%.0f", screenFrame.height)
                
                // Обновляем область захвата
                Config.captureRect = NSRect(x: 0, y: 0, width: screenFrame.width, height: screenFrame.height)
                applySettings()
                break
            }
        }
    }
    
    @objc func windowSelected() {
        guard let selectedWindowItem = windowPopup.selectedItem,
              let windowID = selectedWindowItem.representedObject as? CGWindowID else { return }
        
        Config.selectedWindowID = windowID
        
        // Получаем информацию об окне
        if let windowInfo = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID) as? [[String: Any]],
           let windowDict = windowInfo.first {
            
            if let bounds = windowDict[kCGWindowBounds as String] as? [String: Any],
               let x = bounds["X"] as? CGFloat,
               let y = bounds["Y"] as? CGFloat,
               let width = bounds["Width"] as? CGFloat,
               let height = bounds["Height"] as? CGFloat {
                
                // Обновляем поля координат
                xField.stringValue = String(format: "%.0f", x)
                yField.stringValue = String(format: "%.0f", y)
                widthField.stringValue = String(format: "%.0f", width)
                heightField.stringValue = String(format: "%.0f", height)
                
                // Обновляем область захвата
                Config.captureRect = NSRect(x: x, y: y, width: width, height: height)
                applySettings()
            }
        }
    }
    
    @objc func selectAreaButtonClicked() {
        // Создаем окно выбора области
        let selectionWindow = AreaSelectionWindow()
        selectionWindow.title = "Выберите область для отслеживания"
        selectionWindow.onSelectionComplete = { [weak self] rect in
            guard let self = self else { return }
            
            // Обновляем поля координат
            self.xField.stringValue = String(format: "%.0f", rect.origin.x)
            self.yField.stringValue = String(format: "%.0f", rect.origin.y)
            self.widthField.stringValue = String(format: "%.0f", rect.width)
            self.heightField.stringValue = String(format: "%.0f", rect.height)
            
            // Обновляем область захвата
            Config.captureRect = rect
            self.applySettings()
        }
        selectionWindow.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - UI Updates
    
    @objc func updateUIFromSettings() {
        // Обновляем переключатель режима захвата
        trackingModeSegment.selectedSegment = Config.useWindowMode ? 1 : 0
        
        // Обновляем поля координат
        xField.stringValue = String(format: "%.0f", Config.captureRect.origin.x)
        yField.stringValue = String(format: "%.0f", Config.captureRect.origin.y)
        widthField.stringValue = String(format: "%.0f", Config.captureRect.width)
        heightField.stringValue = String(format: "%.0f", Config.captureRect.height)
        
        // Обновляем слайдеры
        blueMinSlider.intValue = Int32(Config.blueThreshold)
        redMaxSlider.intValue = Int32(Config.redThreshold)
        greenMaxSlider.intValue = Int32(Config.greenThreshold)
        minBluePixelsSlider.intValue = Int32(Config.minBluePixelsThreshold)
        movementThresholdSlider.intValue = Int32(Config.movementThreshold)
        smoothingFactorSlider.doubleValue = Double(Config.smoothingFactor)
        
        // Обновляем чекбоксы
        useMotionPredictionCheckbox.state = Config.useMotionPrediction ? .on : .off
        gameModeCheckbox.state = Config.gameMode ? .on : .off
        showDebugOverlayCheckbox.state = Config.showDebugOverlay ? .on : .off
        
        // Обновляем видимость элементов UI
        updateUIVisibility()
    }
    
    func updateScreensList() {
        screenPopup.removeAllItems()
        for (index, _) in NSScreen.screens.enumerated() {
            screenPopup.addItem(withTitle: "Экран \(index + 1)")
        }
        
        // Выбираем текущий экран
        if Config.selectedScreenIndex < NSScreen.screens.count {
            screenPopup.selectItem(at: Config.selectedScreenIndex)
        }
    }
    
    func updateWindowsList() {
        windowPopup.removeAllItems()
        
        // Получаем список окон
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
        
        // Фильтруем только видимые и именованные окна
        let filteredWindows = windowList.filter { windowDict in
            guard let layer = windowDict[kCGWindowLayer as String] as? Int,
                  let name = windowDict[kCGWindowName as String] as? String,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let bounds = windowDict[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else {
                return false
            }
            
            // Исключаем мелкие окна, системные и окно самого трекера
            return layer == 0 && 
                   !name.isEmpty && 
                   width > 100 && 
                   height > 100 && 
                   ownerName != "BlueEmojiTracker"
        }
        
        // Добавляем окна в список
        for windowDict in filteredWindows {
            if let name = windowDict[kCGWindowName as String] as? String,
               let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
               let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID {
                
                let title = "\(ownerName) - \(name)"
                let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                menuItem.representedObject = windowID
                windowPopup.menu?.addItem(menuItem)
                
                // Выбираем текущее окно, если оно есть в списке
                if windowID == Config.selectedWindowID {
                    windowPopup.select(menuItem)
                }
            }
        }
    }
    
    // MARK: - Settings
    
    func applySettings() {
        // Собираем настройки из полей ввода
        if let x = Float(xField.stringValue),
           let y = Float(yField.stringValue),
           let width = Float(widthField.stringValue),
           let height = Float(heightField.stringValue) {
            
            Config.captureRect = NSRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
        }
        
        // Сохраняем настройки
        Config.saveSettings()
        
        // Обновляем трекер
        if tracker.isRunning {
            tracker.updateSettings()
        }
    }
    
    // MARK: - Permissions
    
    @objc func requestScreenCapturePermission() -> Bool {
        // Проверяем разрешение на запись экрана
        let authStatus = CGDisplayStream.checkAccessForMediaType(.video)
        
        switch authStatus {
        case .notDetermined:
            // Запрашиваем разрешение
            let alert = NSAlert()
            alert.messageText = "Требуется разрешение"
            alert.informativeText = "Приложение BlueEmojiTracker требует разрешение на запись экрана для отслеживания синих областей. Пожалуйста, предоставьте разрешение в диалоговом окне, которое появится после закрытия этого сообщения."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            // Инициируем запрос разрешения
            CGRequestScreenCaptureAccess()
            return false
            
        case .denied, .restricted:
            // Уведомляем пользователя о том, что разрешение не дано
            let alert = NSAlert()
            alert.messageText = "Доступ запрещен"
            alert.informativeText = "Разрешение на запись экрана не предоставлено. Пожалуйста, предоставьте разрешение в Системных настройках -> Конфиденциальность и безопасность -> Запись экрана."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Открыть настройки")
            alert.addButton(withTitle: "Отмена")
            
            if alert.runModal() == .alertFirstButtonReturn {
                // Открываем настройки конфиденциальности
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
            return false
            
        case .authorized:
            // Разрешение есть
            return true
            
        @unknown default:
            let alert = NSAlert()
            alert.messageText = "Неизвестная ошибка"
            alert.informativeText = "Возникла неизвестная ошибка при проверке разрешения на запись экрана."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return false
        }
    }
} 