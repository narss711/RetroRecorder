import SwiftUI
import UIKit

struct SoundCircleSDLView: UIViewRepresentable {
    let spectrum: [Double]
    let waveform: [Double]
    let isActive: Bool

    func makeCoordinator() -> Renderer {
        Renderer()
    }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.accessibilityLabel = "SDL GPU realtime sound circle"
        context.coordinator.attach(view)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        context.coordinator.update(
            frame: ShadertoyAudioFrame(spectrum: spectrum, waveform: waveform),
            isActive: isActive
        )
    }

    static func dismantleUIView(_ view: UIImageView, coordinator: Renderer) {
        coordinator.stop()
    }

    final class Renderer {
        private static let width: UInt32 = 384
        private static let height: UInt32 = 192

        private let queue = DispatchQueue(label: "com.lutan.RetroRecorder.sound-circle-sdl", qos: .userInteractive)
        private let dataLock = NSLock()
        private weak var imageView: UIImageView?
        private var renderer: OpaquePointer?
        private var timer: DispatchSourceTimer?
        private var pendingAudioBytes = Array(repeating: UInt8(0), count: ShadertoyAudioFrame.width * 2)
        private var startedAt = CACurrentMediaTime()
        private var isActive = false
        private var isStopped = false

        init() {
            queue.async { [weak self] in
                guard let self, !self.isStopped else { return }
                self.renderer = RRSDLRendererCreate(Self.width, Self.height)
                self.renderFrame()
            }
        }

        deinit {
            stop()
        }

        func attach(_ imageView: UIImageView) {
            self.imageView = imageView
        }

        func update(frame: ShadertoyAudioFrame, isActive: Bool) {
            dataLock.lock()
            pendingAudioBytes = frame.textureBytes
            dataLock.unlock()

            guard self.isActive != isActive else { return }
            self.isActive = isActive
            if isActive {
                startTimer()
            } else {
                cancelTimer()
                queue.async { [weak self] in self?.renderFrame() }
            }
        }

        func stop() {
            guard !isStopped else { return }
            isStopped = true
            cancelTimer()
            queue.async { [weak self] in
                guard let self else { return }
                if let renderer = self.renderer {
                    RRSDLRendererDestroy(renderer)
                    self.renderer = nil
                }
            }
        }

        private func startTimer() {
            guard timer == nil, !isStopped else { return }
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now(), repeating: .milliseconds(33), leeway: .milliseconds(2))
            timer.setEventHandler { [weak self] in self?.renderFrame() }
            self.timer = timer
            timer.resume()
        }

        private func cancelTimer() {
            timer?.setEventHandler {}
            timer?.cancel()
            timer = nil
        }

        private func renderFrame() {
            guard !isStopped, let renderer else { return }

            dataLock.lock()
            let audioBytes = pendingAudioBytes
            dataLock.unlock()

            var pixels = Array(repeating: UInt8(0), count: Int(Self.width * Self.height * 4))
            let rendered = audioBytes.withUnsafeBufferPointer { audioBuffer in
                pixels.withUnsafeMutableBufferPointer { pixelBuffer in
                    RRSDLRendererRender(
                        renderer,
                        audioBuffer.baseAddress,
                        UInt32(audioBuffer.count),
                        Float(CACurrentMediaTime() - startedAt),
                        pixelBuffer.baseAddress,
                        pixelBuffer.count
                    )
                }
            }
            guard rendered, let image = Self.makeImage(from: pixels) else { return }

            DispatchQueue.main.async { [weak self] in
                self?.imageView?.image = image
            }
        }

        private static func makeImage(from pixels: [UInt8]) -> UIImage? {
            let data = Data(pixels) as CFData
            guard let provider = CGDataProvider(data: data) else { return nil }
            let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
                CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            )
            guard let image = CGImage(
                width: Int(width),
                height: Int(height),
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: Int(width) * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            ) else { return nil }
            return UIImage(cgImage: image)
        }
    }
}
