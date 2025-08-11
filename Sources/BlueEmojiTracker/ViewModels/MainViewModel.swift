import Foundation
import Combine
import Cocoa

class MainViewModel: ObservableObject {

    @Published var isTracking = false
    @Published var useWindowMode = Config.useWindowMode { didSet { saveSettings() } }
    @Published var selectedScreen: NSScreen? = Config.selectedScreen { didSet { saveSettings() } }
    @Published var selectedWindowID: CGWindowID? = Config.selectedWindowID { didSet { saveSettings() } }
    @Published var captureRect: CGRect = Config.captureRect { didSet { saveSettings() } }
    @Published var blueMin: Double = Config.blueMin { didSet { saveSettings() } }
    @Published var redMax: Double = Config.redMax { didSet { saveSettings() } }
    @Published var greenMax: Double = Config.greenMax { didSet { saveSettings() } }
    @Published var minBluePixels: Int = Config.minBluePixels { didSet { saveSettings() } }
    @Published var movementThreshold: Double = Config.movementThreshold { didSet { saveSettings() } }
    @Published var smoothingFactor: Double = Config.smoothingFactor { didSet { saveSettings() } }
    @Published var useMotionPrediction = Config.useMotionPrediction { didSet { saveSettings() } }
    @Published var showHighlight = Config.showHighlight { didSet { saveSettings() } }

    @Published var availableWindows: [WindowInfo] = []

    private var tracker: BlueEmojiTracker?
    private var windowManager = WindowManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadSettings()
        updateWindowList()

        $useWindowMode.sink { [weak self] _ in self?.updateTrackerConfig() }.store(in: &cancellables)
        $selectedWindowID.sink { [weak self] _ in self?.updateTrackerConfig() }.store(in: &cancellables)
    }

    func startStopTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    func updateWindowList() {
        availableWindows = windowManager.getActiveWindows()
    }

    func requestScreenCapturePermission() {
        let stream = CGDisplayStream(dispatchQueueDisplay: .main, matching: .main, handler: { _, _, _, _ in })
        if stream == nil {
            Logger.shared.log("Запрос на разрешение захвата экрана...")
        }
    }

    private func startTracking() {
        let config = createTrackerConfig()
        tracker = BlueEmojiTracker(config: config)
        tracker?.startTracking()
        isTracking = true
        Logger.shared.log("Отслеживание запущено из ViewModel")
    }

    private func stopTracking() {
        tracker?.stopTracking()
        tracker = nil
        isTracking = false
        Logger.shared.log("Отслеживание остановлено из ViewModel")
    }

    private func updateTrackerConfig() {
        guard let tracker = tracker, isTracking else { return }
        let config = createTrackerConfig()
        tracker.updateConfig(newConfig: config)
    }

    private func createTrackerConfig() -> TrackerConfig {
        return TrackerConfig(
            useWindowMode: useWindowMode,
            selectedWindowID: selectedWindowID,
            selectedScreen: selectedScreen ?? NSScreen.main,
            captureRect: captureRect,
            blueMinValue: UInt8(blueMin),
            redMaxValue: UInt8(redMax),
            greenMaxValue: UInt8(greenMax),
            minBluePixels: minBluePixels,
            movementThreshold: CGFloat(movementThreshold),
            smoothingFactor: CGFloat(smoothingFactor),
            useMotionPrediction: useMotionPrediction
        )
    }

    private func loadSettings() {
        Config.loadSettings()

        useWindowMode = Config.useWindowMode
        selectedScreen = Config.selectedScreen ?? NSScreen.main
        selectedWindowID = Config.selectedWindowID
        captureRect = Config.captureRect
        blueMin = Config.blueMin
        redMax = Config.redMax
        greenMax = Config.greenMax
        minBluePixels = Config.minBluePixels
        movementThreshold = Config.movementThreshold
        smoothingFactor = Config.smoothingFactor
        useMotionPrediction = Config.useMotionPrediction
        showHighlight = Config.showHighlight
    }

    private func saveSettings() {
        Config.useWindowMode = useWindowMode
        Config.selectedScreen = selectedScreen
        Config.selectedWindowID = selectedWindowID
        Config.captureRect = captureRect
        Config.blueMin = blueMin
        Config.redMax = redMax
        Config.greenMax = greenMax
        Config.minBluePixels = minBluePixels
        Config.movementThreshold = movementThreshold
        Config.smoothingFactor = smoothingFactor
        Config.useMotionPrediction = useMotionPrediction
        Config.showHighlight = showHighlight

        Config.saveSettings()
    }
}

struct WindowInfo: Identifiable, Hashable {
    var id: CGWindowID { windowID }
    let windowID: CGWindowID
    let name: String
    let bounds: CGRect
}
