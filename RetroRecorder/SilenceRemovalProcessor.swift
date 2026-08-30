import AVFoundation
import Foundation

struct SilenceRemovalResult: Identifiable {
    let id = UUID()
    let tempURL: URL
    let suggestedTitle: String
    let sourceDuration: TimeInterval
    let outputDuration: TimeInterval
    let removedDuration: TimeInterval
    let removedSegmentCount: Int
}

enum SilenceRemovalError: LocalizedError {
    case unreadableAudio
    case noAudioTrack
    case noRemovableSilence
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadableAudio:
            return "无法读取当前录音。"
        case .noAudioTrack:
            return "当前文件没有可处理的音频轨道。"
        case .noRemovableSilence:
            return "没有检测到可删除的长空白。"
        case .exportFailed(let message):
            return "删除空白失败：\(message)"
        }
    }
}

enum SilenceRemovalProcessor {
    private static let windowDuration: TimeInterval = 0.05
    private static let minimumSilenceDuration: TimeInterval = 0.7
    private static let edgePadding: TimeInterval = 0.12
    private static let minimumRemovalDuration: TimeInterval = 0.25

    static func process(recording: RecordingItem) async throws -> SilenceRemovalResult {
        let analysis = try analyze(url: recording.url)

        guard analysis.removalRanges.isEmpty == false else {
            throw SilenceRemovalError.noRemovableSilence
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RetroRecorder-Silence-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        try? FileManager.default.removeItem(at: tempURL)
        try await exportAudio(from: recording.url, retaining: analysis.retainedRanges, to: tempURL)

        return SilenceRemovalResult(
            tempURL: tempURL,
            suggestedTitle: "\(recording.title) 已处理",
            sourceDuration: analysis.sourceDuration,
            outputDuration: analysis.outputDuration,
            removedDuration: analysis.removedDuration,
            removedSegmentCount: analysis.removalRanges.count
        )
    }

    private static func analyze(url: URL) throws -> SilenceAnalysis {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let sampleRate = format.sampleRate
        let frameCapacity = max(256, AVAudioFrameCount(sampleRate * windowDuration))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw SilenceRemovalError.unreadableAudio
        }

        var windows: [AudioEnergyWindow] = []
        let sourceDuration = sampleRate > 0 ? Double(file.length) / sampleRate : 0

        while file.framePosition < file.length {
            let remainingFrames = AVAudioFrameCount(file.length - file.framePosition)
            let frameCount = min(frameCapacity, remainingFrames)
            let startTime = sampleRate > 0 ? Double(file.framePosition) / sampleRate : 0

            try file.read(into: buffer, frameCount: frameCount)

            guard let channelData = buffer.floatChannelData else {
                throw SilenceRemovalError.unreadableAudio
            }

            let framesRead = Int(buffer.frameLength)
            guard framesRead > 0 else {
                break
            }

            let channelCount = max(1, Int(format.channelCount))
            var sumSquares: Float = 0
            var sampleCount = 0

            for channel in 0..<channelCount {
                let samples = channelData[channel]
                for frame in 0..<framesRead {
                    let sample = samples[frame]
                    sumSquares += sample * sample
                    sampleCount += 1
                }
            }

            let rms = sqrt(max(0, sumSquares / Float(max(1, sampleCount))))
            let db = max(-80, 20 * log10(Double(max(rms, 0.000_001))))
            let duration = sampleRate > 0 ? Double(framesRead) / sampleRate : windowDuration
            windows.append(AudioEnergyWindow(start: startTime, duration: duration, db: db))
        }

        guard windows.isEmpty == false, sourceDuration > 0 else {
            throw SilenceRemovalError.unreadableAudio
        }

        let threshold = silenceThreshold(for: windows.map(\.db))
        let removalRanges = removableSilenceRanges(
            in: windows,
            threshold: threshold,
            sourceDuration: sourceDuration
        )
        let retainedRanges = retainedRanges(sourceDuration: sourceDuration, removing: removalRanges)
        let removedDuration = removalRanges.reduce(0) { $0 + $1.duration }
        let outputDuration = max(0, sourceDuration - removedDuration)

        return SilenceAnalysis(
            sourceDuration: sourceDuration,
            outputDuration: outputDuration,
            removedDuration: removedDuration,
            removalRanges: removalRanges,
            retainedRanges: retainedRanges
        )
    }

    private static func silenceThreshold(for dbValues: [Double]) -> Double {
        let sortedValues = dbValues.sorted()
        let noiseFloor = percentile(0.2, in: sortedValues)
        let speechCeiling = percentile(0.9, in: sortedValues)
        let dynamicLift = max(8, (speechCeiling - noiseFloor) * 0.25)
        return min(-35, max(-52, noiseFloor + dynamicLift))
    }

    private static func percentile(_ percentile: Double, in sortedValues: [Double]) -> Double {
        guard sortedValues.isEmpty == false else {
            return -45
        }

        let clamped = min(1, max(0, percentile))
        let index = Int((Double(sortedValues.count - 1) * clamped).rounded())
        return sortedValues[index]
    }

    private static func removableSilenceRanges(
        in windows: [AudioEnergyWindow],
        threshold: Double,
        sourceDuration: TimeInterval
    ) -> [TimeRange] {
        var ranges: [TimeRange] = []
        var silenceStart: TimeInterval?

        for window in windows {
            if window.db < threshold {
                if silenceStart == nil {
                    silenceStart = window.start
                }
            } else if let start = silenceStart {
                appendRemovableRange(from: start, to: window.start, sourceDuration: sourceDuration, ranges: &ranges)
                silenceStart = nil
            }
        }

        if let start = silenceStart {
            appendRemovableRange(from: start, to: sourceDuration, sourceDuration: sourceDuration, ranges: &ranges)
        }

        return ranges
    }

    private static func appendRemovableRange(
        from start: TimeInterval,
        to end: TimeInterval,
        sourceDuration: TimeInterval,
        ranges: inout [TimeRange]
    ) {
        guard end - start >= minimumSilenceDuration else {
            return
        }

        let isLeadingSilence = start <= windowDuration
        let isTrailingSilence = sourceDuration - end <= windowDuration
        let removalStart = isLeadingSilence ? 0 : start + edgePadding
        let removalEnd = isTrailingSilence ? sourceDuration : end - edgePadding

        guard removalEnd - removalStart >= minimumRemovalDuration else {
            return
        }

        ranges.append(TimeRange(start: max(0, removalStart), end: min(sourceDuration, removalEnd)))
    }

    private static func retainedRanges(sourceDuration: TimeInterval, removing removalRanges: [TimeRange]) -> [TimeRange] {
        var retained: [TimeRange] = []
        var cursor: TimeInterval = 0

        for range in removalRanges {
            if range.start > cursor {
                retained.append(TimeRange(start: cursor, end: range.start))
            }

            cursor = max(cursor, range.end)
        }

        if cursor < sourceDuration {
            retained.append(TimeRange(start: cursor, end: sourceDuration))
        }

        return retained.filter { $0.duration > 0.02 }
    }

    private static func exportAudio(from sourceURL: URL, retaining ranges: [TimeRange], to outputURL: URL) async throws {
        let asset = AVURLAsset(url: sourceURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)

        guard let sourceTrack = tracks.first else {
            throw SilenceRemovalError.noAudioTrack
        }

        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw SilenceRemovalError.noAudioTrack
        }

        var insertionTime = CMTime.zero
        let timeScale: CMTimeScale = 600

        for range in ranges {
            let start = CMTime(seconds: range.start, preferredTimescale: timeScale)
            let duration = CMTime(seconds: range.duration, preferredTimescale: timeScale)
            let timeRange = CMTimeRange(start: start, duration: duration)
            try compositionTrack.insertTimeRange(timeRange, of: sourceTrack, at: insertionTime)
            insertionTime = insertionTime + duration
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw SilenceRemovalError.exportFailed("当前音频格式无法导出。")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(start: .zero, duration: insertionTime)

        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed, .cancelled:
                    let message = exportSession.error?.localizedDescription ?? "导出被取消。"
                    continuation.resume(throwing: SilenceRemovalError.exportFailed(message))
                default:
                    continuation.resume(throwing: SilenceRemovalError.exportFailed("导出状态异常。"))
                }
            }
        }
    }
}

private struct AudioEnergyWindow {
    let start: TimeInterval
    let duration: TimeInterval
    let db: Double
}

private struct SilenceAnalysis {
    let sourceDuration: TimeInterval
    let outputDuration: TimeInterval
    let removedDuration: TimeInterval
    let removalRanges: [TimeRange]
    let retainedRanges: [TimeRange]
}

private struct TimeRange {
    let start: TimeInterval
    let end: TimeInterval

    var duration: TimeInterval {
        max(0, end - start)
    }
}
