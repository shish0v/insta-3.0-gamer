import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {

            HStack {
                Image(systemName: "dot.scope")
                    .font(.largeTitle)
                Text("Blue Emoji Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }

            Button(action: viewModel.startStopTracking) {
                HStack {
                    Image(systemName: viewModel.isTracking ? "stop.circle.fill" : "play.circle.fill")
                    Text(viewModel.isTracking ? "Stop Tracking" : "Start Tracking")
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .tint(viewModel.isTracking ? .red : .accentColor)

            Form {
                Section(header: Label("Capture Settings", systemImage: "macwindow")) {
                    Picker("Mode", selection: $viewModel.useWindowMode) {
                        Text("Screen Area").tag(false)
                        Text("Window").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if viewModel.useWindowMode {
                        Picker("Window", selection: $viewModel.selectedWindowID) {
                            ForEach(viewModel.availableWindows) { window in
                                Text(window.name).tag(window.windowID as CGWindowID?)
                            }
                        }
                        .onAppear(perform: viewModel.updateWindowList)
                    } else {
                        Picker("Screen", selection: $viewModel.selectedScreen) {
                            ForEach(NSScreen.screens, id: \.self) { screen in
                                Text(screen.localizedName).tag(screen as NSScreen?)
                            }
                        }
                    }
                }

                Section(header: Label("Color Settings", systemImage: "eyedropper.halffull")) {
                    SliderView(label: "Blue Min:", value: $viewModel.blueMin, range: 0...255, format: "%.0f")
                    SliderView(label: "Red Max:", value: $viewModel.redMax, range: 0...255, format: "%.0f")
                    SliderView(label: "Green Max:", value: $viewModel.greenMax, range: 0...255, format: "%.0f")
                    IntSliderView(label: "Min Pixels:", value: $viewModel.minBluePixels, range: 1...100)
                }

                Section(header: Label("Movement Settings", systemImage: "arrow.up.and.down.and.arrow.left.and.right")) {
                    SliderView(label: "Threshold:", value: $viewModel.movementThreshold, range: 0...50, format: "%.0f")
                    SliderView(label: "Smoothing:", value: $viewModel.smoothingFactor, range: 0...0.99, format: "%.2f")
                    Toggle("Use Motion Prediction", isOn: $viewModel.useMotionPrediction)
                }

                Section(header: Label("Debug Settings", systemImage: "ladybug")) {
                    Toggle("Show Debug Overlay", isOn: $viewModel.showHighlight)
                }
            }
        }
        .padding()
        .frame(width: 600, height: 600)
        .onAppear(perform: viewModel.requestScreenCapturePermission)
    }
}
