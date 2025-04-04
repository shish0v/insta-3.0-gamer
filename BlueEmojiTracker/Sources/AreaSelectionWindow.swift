import Cocoa

/// Окно для визуального выбора области на экране
class AreaSelectionWindow: NSWindow {
    
    // Callback при завершении выбора области
    private var selectionCallback: (CGRect) -> Void
    
    // Точки для отслеживания области выбора
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    
    /// Инициализатор окна выбора области
    /// - Parameter selectionCallback: Callback, вызываемый при завершении выбора с выбранной областью
    init(selectionCallback: @escaping (CGRect) -> Void) {
        self.selectionCallback = selectionCallback
        
        // Получаем размеры основного экрана
        let screen = NSScreen.main!
        
        // Инициализируем родительский класс
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Настраиваем окно
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        
        // Создаем представление для отображения выбранной области
        let selectionView = AreaSelectionView(frame: screen.frame)
        self.contentView = selectionView
        
        // Добавляем обработчик сочетания клавиш для отмены (Esc)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Код клавиши Esc
                self?.close()
                return nil
            }
            return event
        }
    }
    
    /// Обрабатывает нажатие кнопки мыши для начала выбора области
    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentPoint = event.locationInWindow
        contentView?.needsDisplay = true
    }
    
    /// Обрабатывает перетаскивание мыши для изменения выбираемой области
    override func mouseDragged(with event: NSEvent) {
        currentPoint = event.locationInWindow
        contentView?.needsDisplay = true
    }
    
    /// Обрабатывает отпускание кнопки мыши для завершения выбора области
    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint else { return }
        
        let current = event.locationInWindow
        
        // Создаем прямоугольник из начальной и текущей точек
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        
        let rect = NSRect(x: minX, y: minY, width: width, height: height)
        
        // Конвертируем в координаты экрана
        let screenRect = self.convertToScreen(rect)
        
        // Вызываем callback с финальным прямоугольником
        selectionCallback(screenRect)
        
        // Закрываем окно
        close()
    }
    
    /// Обрабатывает отмену операции (клавиша Esc)
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

/// Представление для отображения процесса выбора области
class AreaSelectionView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Рисуем полупрозрачный фон
        NSColor.black.withAlphaComponent(0.3).set()
        dirtyRect.fill()
        
        // Если окно управляет выбором области, получаем точки
        guard let window = self.window as? AreaSelectionWindow else { return }
        
        // Получаем контекст для рисования
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Получаем точки начала и текущей позиции из окна с помощью приватного API
        // Так как мы не можем напрямую обратиться к private свойствам, используем KVC
        guard let startPoint = window.value(forKey: "startPoint") as? NSPoint,
              let currentPoint = window.value(forKey: "currentPoint") as? NSPoint else { return }
        
        // Создаем прямоугольник из начальной и текущей точек
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)
        
        let rect = NSRect(x: minX, y: minY, width: width, height: height)
        
        // Очищаем выбранную область, делая её прозрачной
        context.setBlendMode(.clear)
        context.fill(rect)
        
        // Возвращаем обычный режим наложения
        context.setBlendMode(.normal)
        
        // Рисуем рамку вокруг выбранной области
        NSColor.white.set()
        NSBezierPath(rect: rect).stroke()
        
        // Рисуем текст с размерами
        let text = "\(Int(rect.width)) x \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7),
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(at: NSPoint(x: rect.minX + 5, y: rect.minY + 5))
        
        // Рисуем инструкции
        let instructions = "Выберите область для игрового поля. Нажмите и перетащите мышь для выбора. Нажмите Esc для отмены."
        let instructionAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7),
            .font: NSFont.systemFont(ofSize: 14)
        ]
        
        let attributedInstructions = NSAttributedString(string: instructions, attributes: instructionAttributes)
        attributedInstructions.draw(at: NSPoint(x: 20, y: bounds.height - 50))
    }
} 