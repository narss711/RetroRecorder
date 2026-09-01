import AppKit
import ImageIO
import UniformTypeIdentifiers
import WebKit

final class Snapshotter: NSObject, WKNavigationDelegate {
    private let inputURL: URL
    private let outputURL: URL
    private let outputSize: NSSize
    private let webView: WKWebView

    init(inputURL: URL, outputURL: URL, outputSize: NSSize) {
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.outputSize = outputSize
        self.webView = WKWebView(frame: NSRect(origin: .zero, size: outputSize))
        super.init()
        webView.navigationDelegate = self
    }

    func start() {
        webView.loadFileURL(inputURL, allowingReadAccessTo: inputURL.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            let configuration = WKSnapshotConfiguration()
            configuration.rect = NSRect(origin: .zero, size: outputSize)
            configuration.snapshotWidth = NSNumber(value: Double(outputSize.width))

            webView.takeSnapshot(with: configuration) { [self] image, error in
                guard let image, error == nil,
                      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    let message = error?.localizedDescription ?? "unknown error"
                    fputs("Unable to render \(inputURL.lastPathComponent): \(message)\n", stderr)
                    NSApp.terminate(nil)
                    return
                }

                let pixelWidth = Int(outputSize.width)
                let pixelHeight = Int(outputSize.height)
                let bytesPerRow = pixelWidth * 4
                let imageData = NSMutableData(length: bytesPerRow * pixelHeight)!
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
                guard let context = CGContext(
                    data: imageData.mutableBytes,
                    width: pixelWidth,
                    height: pixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) else {
                    fputs("Unable to create image context\n", stderr)
                    NSApp.terminate(nil)
                    return
                }

                context.setFillColor(NSColor.white.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
                context.draw(cgImage, in: CGRect(origin: .zero, size: outputSize))

                guard let renderedImage = context.makeImage(),
                      let destination = CGImageDestinationCreateWithURL(
                        outputURL as CFURL,
                        UTType.png.identifier as CFString,
                        1,
                        nil
                      ) else {
                    fputs("Unable to encode \(inputURL.lastPathComponent)\n", stderr)
                    NSApp.terminate(nil)
                    return
                }

                CGImageDestinationAddImage(destination, renderedImage, nil)
                CGImageDestinationFinalize(destination)
                NSApp.terminate(nil)
            }
        }
    }
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: export-svg INPUT.svg OUTPUT.png\n", stderr)
    exit(64)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let size = NSSize(width: 1290, height: 2796)

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let snapshotter = Snapshotter(inputURL: inputURL, outputURL: outputURL, outputSize: size)
snapshotter.start()
app.run()
