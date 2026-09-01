import MetalKit
import SwiftUI

struct ShadertoyAudioFrame {
    static let width = 512

    let spectrum: [Float]
    let waveform: [Float]
    let textureBytes: [UInt8]
    let energy: Float

    init(spectrum: [Double], waveform: [Double]) {
        let spectrum = Self.resample(spectrum, count: Self.width, range: 0...1)
        let waveform = Self.resample(waveform, count: Self.width, range: -1...1)
        let energyBand = spectrum.prefix(192)
        let peak = energyBand.max() ?? 0
        let average = energyBand.reduce(0, +) / Float(max(1, energyBand.count))

        var textureBytes = Array(repeating: UInt8(0), count: Self.width * 2)
        for index in 0..<Self.width {
            textureBytes[index] = UInt8((spectrum[index] * 255).rounded())
            let normalizedWaveform = waveform[index] * 0.5 + 0.5
            textureBytes[Self.width + index] = UInt8((normalizedWaveform * 255).rounded())
        }

        self.spectrum = spectrum
        self.waveform = waveform
        self.textureBytes = textureBytes
        self.energy = min(1, max(peak, average * 1.9))
    }

    private static func resample(
        _ values: [Double],
        count: Int,
        range: ClosedRange<Double>
    ) -> [Float] {
        guard !values.isEmpty, count > 0 else {
            return Array(repeating: 0, count: max(0, count))
        }

        let clamp: (Double) -> Float = { value in
            Float(min(range.upperBound, max(range.lowerBound, value)))
        }

        guard values.count != count else {
            return values.map(clamp)
        }

        guard count > 1, values.count > 1 else {
            return Array(repeating: clamp(values[0]), count: count)
        }

        let sourceScale = Double(values.count - 1) / Double(count - 1)
        return (0..<count).map { index in
            let sourcePosition = Double(index) * sourceScale
            let lowerIndex = Int(sourcePosition.rounded(.down))
            let upperIndex = min(lowerIndex + 1, values.count - 1)
            let fraction = sourcePosition - Double(lowerIndex)
            let value = values[lowerIndex] + (values[upperIndex] - values[lowerIndex]) * fraction
            return clamp(value)
        }
    }
}

enum ShadertoyMetalEffect: String {
    case circleReactive
    case waveLeneer
    case colorFFT
    case triangleGalaxy
    case microphoneGradient
    case plasticSurface
    case movingFrequencySpectrum
    case micRipples

    var fragmentFunctionName: String {
        switch self {
        case .circleReactive:
            return "circleReactiveFragment"
        case .waveLeneer:
            return "waveLeneerFragment"
        case .colorFFT:
            return "colorFFTFragment"
        case .triangleGalaxy:
            return "triangleGalaxyFragment"
        case .microphoneGradient:
            return "microphoneGradientFragment"
        case .plasticSurface:
            return "plasticSurfaceFragment"
        case .movingFrequencySpectrum:
            return "movingFrequencySpectrumFragment"
        case .micRipples:
            return "micRipplesFragment"
        }
    }

    var usesSpectrumHistory: Bool {
        self == .plasticSurface || self == .movingFrequencySpectrum
    }

    var accessibilityLabel: String {
        switch self {
        case .circleReactive:
            return "Circle music reactive visualization"
        case .waveLeneer:
            return "Linear audio wave visualization"
        case .colorFFT:
            return "Color FFT visualization"
        case .triangleGalaxy:
            return "Triangle galaxy visualization"
        case .microphoneGradient:
            return "Microphone gradient waveform visualization"
        case .plasticSurface:
            return "Plastic audio surface visualization"
        case .movingFrequencySpectrum:
            return "Moving frequency spectrum visualization"
        case .micRipples:
            return "Microphone ripple visualization"
        }
    }
}

struct ShadertoyMetalEffectView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(InterfaceColorTheme.storageKey) private var interfaceColorThemeRaw = InterfaceColorTheme.pocketOlive.rawValue

    let effect: ShadertoyMetalEffect
    let spectrum: [Double]
    let waveform: [Double]
    let isActive: Bool

    private var themeBackgroundColor: UIColor {
        let userInterfaceStyle: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let traits = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        return InterfaceColorTheme.value(for: interfaceColorThemeRaw)
            .palette(for: traits)
            .appBackgroundMiddle
    }

    func makeCoordinator() -> Renderer {
        Renderer(effect: effect)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = Self.clearColor(from: themeBackgroundColor)
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = true
        view.isUserInteractionEnabled = effect == .plasticSurface
        view.accessibilityLabel = effect.accessibilityLabel
        if effect == .plasticSurface {
            view.accessibilityHint = "Drag to rotate the audio surface"
            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Renderer.handleSurfacePan(_:))
            )
            panGesture.maximumNumberOfTouches = 1
            panGesture.cancelsTouchesInView = true
            panGesture.delegate = context.coordinator
            view.addGestureRecognizer(panGesture)
        }

        context.coordinator.configure(for: view)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        let backgroundColor = themeBackgroundColor
        view.clearColor = Self.clearColor(from: backgroundColor)
        let shouldDrawInactiveFrame = context.coordinator.update(
            frame: ShadertoyAudioFrame(spectrum: spectrum, waveform: waveform),
            isActive: isActive,
            themeBackground: Self.rgba(from: backgroundColor)
        )

        if isActive {
            view.isPaused = false
        } else {
            view.isPaused = true
            if shouldDrawInactiveFrame {
                view.draw()
            }
        }
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Renderer) {
        view.delegate = nil
        view.isPaused = true
    }

    private static func rgba(from color: UIColor) -> SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return SIMD4<Float>(0, 0, 0, 1)
        }

        return SIMD4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    private static func clearColor(from color: UIColor) -> MTLClearColor {
        let rgba = rgba(from: color)
        return MTLClearColor(
            red: Double(rgba.x),
            green: Double(rgba.y),
            blue: Double(rgba.z),
            alpha: Double(rgba.w)
        )
    }

    final class Renderer: NSObject, MTKViewDelegate, UIGestureRecognizerDelegate {
        private static let audioSampleCount = ShadertoyAudioFrame.width
        private static let historyRowCount = 96
        private static let maximumFramesInFlight = 3

        private struct FrameUniforms {
            var resolution: SIMD2<Float>
            var time: Float
            var energy: Float
            var historyHead: UInt32
            var historyRowCount: UInt32
            var isActive: Float
            var padding: Float
            var viewRotation: SIMD2<Float>
            var themeBackground: SIMD4<Float>
        }

        private let effect: ShadertoyMetalEffect
        private let dataLock = NSLock()
        private let inFlightSemaphore = DispatchSemaphore(value: maximumFramesInFlight)
        private var pendingSpectrum = Array(repeating: Float(0), count: audioSampleCount)
        private var pendingWaveform = Array(repeating: Float(0), count: audioSampleCount)
        private var pendingHistory = Array(
            repeating: Float(0),
            count: audioSampleCount * historyRowCount
        )
        private var pendingEnergy: Float = 0
        private var pendingHistoryHead = 0
        private var pendingIsActive = false
        private var pendingViewRotation = SIMD2<Float>(0, 0.58)
        private var pendingThemeBackground = SIMD4<Float>(0, 0, 0, 1)
        private var gestureStartRotation = SIMD2<Float>(0, 0.58)
        private var hasReceivedActiveState = false
        private var spectrumBuffers: [MTLBuffer] = []
        private var waveformBuffers: [MTLBuffer] = []
        private var historyBuffers: [MTLBuffer] = []
        private var frameIndex = 0
        private var startedAt = CACurrentMediaTime()
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?

        init(effect: ShadertoyMetalEffect) {
            self.effect = effect
            super.init()
        }

        func configure(for view: MTKView) {
            guard let device = view.device else {
                assertionFailure("Metal is unavailable on this device")
                return
            }

            do {
                guard let library = device.makeDefaultLibrary(),
                      let vertexFunction = library.makeFunction(name: "shadertoyAudioVertex"),
                      let fragmentFunction = library.makeFunction(name: effect.fragmentFunctionName) else {
                    assertionFailure("Metal shader functions are unavailable for \(effect.rawValue)")
                    return
                }

                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.label = "\(effect.rawValue) Pipeline"
                descriptor.vertexFunction = vertexFunction
                descriptor.fragmentFunction = fragmentFunction
                descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

                pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
                commandQueue = device.makeCommandQueue()
                spectrumBuffers = makeBuffers(
                    device: device,
                    count: Self.audioSampleCount,
                    label: "\(effect.rawValue) FFT"
                )
                waveformBuffers = makeBuffers(
                    device: device,
                    count: Self.audioSampleCount,
                    label: "\(effect.rawValue) Waveform"
                )
                historyBuffers = makeBuffers(
                    device: device,
                    count: effect.usesSpectrumHistory
                        ? Self.audioSampleCount * Self.historyRowCount
                        : 1,
                    label: "\(effect.rawValue) Spectrogram History"
                )
            } catch {
                assertionFailure("Unable to create \(effect.rawValue) Metal pipeline: \(error)")
            }
        }

        func update(
            frame: ShadertoyAudioFrame,
            isActive: Bool,
            themeBackground: SIMD4<Float>
        ) -> Bool {
            dataLock.lock()
            let themeChanged = pendingThemeBackground != themeBackground
            let shouldDrawInactiveFrame = hasReceivedActiveState == false
                || (pendingIsActive && isActive == false)
                || themeChanged
            pendingSpectrum = frame.spectrum
            pendingWaveform = frame.waveform
            pendingEnergy = frame.energy
            pendingIsActive = isActive
            pendingThemeBackground = themeBackground
            hasReceivedActiveState = true

            if effect.usesSpectrumHistory, isActive {
                let rowOffset = pendingHistoryHead * Self.audioSampleCount
                pendingHistory.replaceSubrange(
                    rowOffset..<(rowOffset + Self.audioSampleCount),
                    with: frame.spectrum
                )
                pendingHistoryHead = (pendingHistoryHead + 1) % Self.historyRowCount
            }
            dataLock.unlock()
            return shouldDrawInactiveFrame
        }

        func draw(in view: MTKView) {
            guard let pipelineState,
                  let commandQueue,
                  spectrumBuffers.count == Self.maximumFramesInFlight,
                  waveformBuffers.count == Self.maximumFramesInFlight,
                  historyBuffers.count == Self.maximumFramesInFlight,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else {
                return
            }

            inFlightSemaphore.wait()
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                inFlightSemaphore.signal()
                return
            }

            commandBuffer.label = "\(effect.rawValue) Frame"
            commandBuffer.addCompletedHandler { [inFlightSemaphore] _ in
                inFlightSemaphore.signal()
            }

            dataLock.lock()
            let spectrum = pendingSpectrum
            let waveform = pendingWaveform
            let history = pendingHistory
            let energy = pendingEnergy
            let historyHead = pendingHistoryHead
            let isActive = pendingIsActive
            let viewRotation = pendingViewRotation
            let themeBackground = pendingThemeBackground
            dataLock.unlock()

            let spectrumBuffer = spectrumBuffers[frameIndex]
            let waveformBuffer = waveformBuffers[frameIndex]
            let historyBuffer = historyBuffers[frameIndex]
            frameIndex = (frameIndex + 1) % Self.maximumFramesInFlight

            copy(spectrum, to: spectrumBuffer)
            copy(waveform, to: waveformBuffer)
            if effect.usesSpectrumHistory {
                copy(history, to: historyBuffer)
            } else {
                historyBuffer.contents().storeBytes(of: Float(0), as: Float.self)
            }

            var uniforms = FrameUniforms(
                resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
                time: Float(CACurrentMediaTime() - startedAt),
                energy: energy,
                historyHead: UInt32(historyHead),
                historyRowCount: UInt32(Self.historyRowCount),
                isActive: isActive ? 1 : 0,
                padding: 0,
                viewRotation: viewRotation,
                themeBackground: themeBackground
            )

            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                commandBuffer.commit()
                return
            }

            encoder.label = "\(effect.rawValue) Encoder"
            encoder.setRenderPipelineState(pipelineState)
            encoder.setFragmentBytes(
                &uniforms,
                length: MemoryLayout<FrameUniforms>.stride,
                index: 0
            )
            encoder.setFragmentBuffer(spectrumBuffer, offset: 0, index: 1)
            encoder.setFragmentBuffer(waveformBuffer, offset: 0, index: 2)
            encoder.setFragmentBuffer(historyBuffer, offset: 0, index: 3)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        @objc func handleSurfacePan(_ gesture: UIPanGestureRecognizer) {
            guard effect == .plasticSurface, let view = gesture.view as? MTKView else {
                return
            }

            switch gesture.state {
            case .began:
                dataLock.lock()
                gestureStartRotation = pendingViewRotation
                dataLock.unlock()
            case .changed, .ended:
                let translation = gesture.translation(in: view)
                let width = max(view.bounds.width, 1)
                let height = max(view.bounds.height, 1)
                var rotation = SIMD2<Float>(
                    gestureStartRotation.x + Float(translation.x / width) * .pi * 1.35,
                    gestureStartRotation.y - Float(translation.y / height) * 1.25
                )
                rotation.y = min(max(rotation.y, 0.12), 1.18)
                if gesture.state == .ended {
                    rotation.x = atan2(sin(rotation.x), cos(rotation.x))
                }

                dataLock.lock()
                pendingViewRotation = rotation
                dataLock.unlock()

                if view.isPaused {
                    view.draw()
                }
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard effect == .plasticSurface,
                  let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = gestureRecognizer.view else {
                return false
            }

            // Keep a narrow edge gesture available for paging to adjacent effects.
            let edgeInset = min(28, max(18, view.bounds.width * 0.08))
            let location = panGesture.location(in: view)
            guard location.x > edgeInset, location.x < view.bounds.width - edgeInset else {
                return false
            }

            let velocity = panGesture.velocity(in: view)
            return abs(velocity.x) + abs(velocity.y) > 0
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }

        private func makeBuffers(device: MTLDevice, count: Int, label: String) -> [MTLBuffer] {
            (0..<Self.maximumFramesInFlight).compactMap { index in
                let buffer = device.makeBuffer(
                    length: count * MemoryLayout<Float>.stride,
                    options: .storageModeShared
                )
                buffer?.label = "\(label) \(index)"
                return buffer
            }
        }

        private func copy(_ values: [Float], to buffer: MTLBuffer) {
            let destination = buffer.contents().bindMemory(to: Float.self, capacity: values.count)
            values.withUnsafeBufferPointer { source in
                guard let sourceAddress = source.baseAddress else {
                    return
                }
                destination.update(from: sourceAddress, count: values.count)
            }
        }
    }
}
