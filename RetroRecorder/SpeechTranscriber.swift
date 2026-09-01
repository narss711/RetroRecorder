import AVFoundation
import Foundation
import Speech

enum TranscriptionEngine: String, CaseIterable, Identifiable {
    case appleSpeech
    case whisper
    case deepSpeech

    static let storageKey = "transcriptionEngine"

    var id: String { rawValue }

    var isAvailable: Bool {
        switch self {
        case .appleSpeech:
            return true
        case .whisper, .deepSpeech:
            return false
        }
    }

    var modelName: String {
        switch self {
        case .appleSpeech:
            return "Apple Speech"
        case .whisper:
            return "OpenAI Whisper"
        case .deepSpeech:
            return "Mozilla DeepSpeech"
        }
    }

    static func value(for rawValue: String) -> TranscriptionEngine {
        switch rawValue {
        case "whisperTiny", "whisperBase", "whisperSmall", "whisperMedium", "whisperTurbo":
            return .whisper
        case "deepSpeechEnglish093", "deepSpeechChinese093":
            return .deepSpeech
        default:
            break
        }

        return TranscriptionEngine(rawValue: rawValue) ?? .appleSpeech
    }
}

struct SpeechLanguageOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let nativeName: String

    var subtitle: String {
        id
    }

    var title: String {
        nativeName == displayName ? displayName : "\(displayName) / \(nativeName)"
    }

    static let defaultIdentifier = "zh-CN"

    static func option(for identifier: String) -> SpeechLanguageOption {
        let normalizedIdentifier = normalized(identifier)
        let locale = Locale(identifier: normalizedIdentifier)
        let currentLocale = Locale.current
        let displayName = currentLocale.localizedString(forIdentifier: normalizedIdentifier) ?? normalizedIdentifier
        let nativeName = locale.localizedString(forIdentifier: normalizedIdentifier) ?? displayName

        return SpeechLanguageOption(
            id: normalizedIdentifier,
            displayName: displayName,
            nativeName: nativeName
        )
    }

    static func supportedOptions() -> [SpeechLanguageOption] {
        let preferredOrder = [
            "zh-CN",
            "zh-TW",
            "zh-HK",
            "en-US",
            "en-GB",
            "es-ES",
            "ar-SA",
            "pt-BR",
            "pt-PT",
            "ru-RU",
            "ja-JP",
            "de-DE",
            "fr-FR",
            "ko-KR"
        ]

        return SFSpeechRecognizer.supportedLocales()
            .map { option(for: $0.identifier) }
            .sorted { left, right in
                let leftIndex = preferredOrder.firstIndex(of: left.id) ?? Int.max
                let rightIndex = preferredOrder.firstIndex(of: right.id) ?? Int.max

                if leftIndex != rightIndex {
                    return leftIndex < rightIndex
                }

                if left.displayName != right.displayName {
                    return left.displayName.localizedCompare(right.displayName) == .orderedAscending
                }

                return left.id < right.id
            }
    }

    static func normalized(_ identifier: String) -> String {
        identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
    }
}

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case recognizerUnavailable(String)
    case emptyResult
    case engineUnavailable(TranscriptionEngine)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "没有语音识别权限。"
        case .recognizerUnavailable(let identifier):
            return "当前语言（\(identifier)）的语音识别不可用。"
        case .emptyResult:
            return "没有识别到可用文本。"
        case .engineUnavailable(let engine):
            switch engine {
            case .appleSpeech:
                return "Apple Speech 当前不可用。"
            case .whisper:
                return "\(engine.modelName) 需要 iOS 本地 Whisper 运行时。本版本已加入模型切换选项，但还没有嵌入可执行后端。"
            case .deepSpeech:
                return "\(engine.modelName) 需要 DeepSpeech TFLite/C++ 运行时；DeepSpeech 官方项目已停止维护，本版本暂不执行这个模型。"
            }
        }
    }
}

final class SpeechTranscriber {
    private var recognitionTask: SFSpeechRecognitionTask?

    func transcribe(
        url: URL,
        localeIdentifier: String,
        engine: TranscriptionEngine = .appleSpeech
    ) async throws -> String {
        guard engine == .appleSpeech else {
            throw TranscriptionError.engineUnavailable(engine)
        }

        let authorizationStatus = await requestAuthorization()

        guard authorizationStatus == .authorized else {
            throw TranscriptionError.authorizationDenied
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
              recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable(localeIdentifier)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = true
            request.taskHint = .dictation

            var didResume = false

            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !didResume else {
                        return
                    }

                    didResume = true
                    transcript.isEmpty
                        ? continuation.resume(throwing: TranscriptionError.emptyResult)
                        : continuation.resume(returning: transcript)
                    return
                }

                if let error {
                    guard !didResume else {
                        return
                    }

                    didResume = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func cancel() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

final class LiveSpeechRecognizer {
    private static let segmentDuration: TimeInterval = 45

    private let stateQueue = DispatchQueue(label: "com.lutan.RetroRecorder.live-speech")
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var segmentRestartWorkItem: DispatchWorkItem?
    private var segmentID = 0
    private var segmentText = ""
    private var committedText = ""
    private var localeIdentifier = SpeechLanguageOption.defaultIdentifier
    private var onResultHandler: ((String) -> Void)?
    private var isActive = false

    func start(
        localeIdentifier: String,
        onResult: @escaping (String) -> Void,
        onError _: @escaping (Error) -> Void
    ) async throws {
        cancel()

        let authorizationStatus = await requestAuthorization()

        guard authorizationStatus == .authorized else {
            throw TranscriptionError.authorizationDenied
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
              recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable(localeIdentifier)
        }

        stateQueue.sync {
            self.recognizer = recognizer
            self.localeIdentifier = localeIdentifier
            self.onResultHandler = onResult
            self.committedText = ""
            self.segmentText = ""
            self.isActive = true
            self.startSegmentLocked()
        }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        // Keep the buffer alive until append finishes while serializing it with
        // segment rotation. This prevents a restart from dropping audio at the
        // exact boundary between two recognition requests.
        stateQueue.sync {
            guard isActive else {
                return
            }

            recognitionRequest?.append(buffer)
        }
    }

    func stop() {
        stateQueue.sync {
            isActive = false
            segmentRestartWorkItem?.cancel()
            segmentRestartWorkItem = nil
            recognitionRequest?.endAudio()
            recognitionTask?.finish()
            clearRecognitionStateLocked()
        }
    }

    func cancel() {
        stateQueue.sync {
            isActive = false
            segmentRestartWorkItem?.cancel()
            segmentRestartWorkItem = nil
            recognitionTask?.cancel()
            recognitionRequest?.endAudio()
            clearRecognitionStateLocked()
        }
    }

    private func startSegmentLocked() {
        guard isActive, let recognizer else {
            return
        }

        segmentID += 1
        let currentSegmentID = segmentID
        segmentText = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else {
                return
            }

            self.stateQueue.async {
                guard self.isActive, self.segmentID == currentSegmentID else {
                    return
                }

                if let result {
                    let nextText = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if nextText.isEmpty == false {
                        self.segmentText = nextText
                        self.emitTranscriptLocked()
                    }

                    if result.isFinal {
                        self.rotateSegmentLocked()
                        return
                    }
                }

                if error != nil {
                    // Speech recognition can end a live task because of its
                    // service timeout. Restart silently so Live Text keeps
                    // receiving new words instead of replacing them with an
                    // error message.
                    self.rotateSegmentLocked()
                }
            }
        }

        let restartWorkItem = DispatchWorkItem { [weak self] in
            self?.rotateSegmentLocked()
        }
        segmentRestartWorkItem?.cancel()
        segmentRestartWorkItem = restartWorkItem
        stateQueue.asyncAfter(
            deadline: .now() + Self.segmentDuration,
            execute: restartWorkItem
        )
    }

    private func rotateSegmentLocked() {
        guard isActive else {
            return
        }

        committedText = join(committedText, segmentText)
        segmentRestartWorkItem?.cancel()
        segmentRestartWorkItem = nil

        let oldRequest = recognitionRequest
        let oldTask = recognitionTask
        recognitionRequest = nil
        recognitionTask = nil
        oldRequest?.endAudio()
        oldTask?.finish()

        emitTranscriptLocked()
        startSegmentLocked()
    }

    private func emitTranscriptLocked() {
        let transcript = join(committedText, segmentText)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard transcript.isEmpty == false else {
            return
        }

        onResultHandler?(transcript)
    }

    private func join(_ left: String, _ right: String) -> String {
        let left = left.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = right.trimmingCharacters(in: .whitespacesAndNewlines)

        guard left.isEmpty == false else { return right }
        guard right.isEmpty == false else { return left }

        let languageCode = localeIdentifier.split(separator: "-").first.map(String.init) ?? localeIdentifier
        let usesWordSeparators = ["en", "es", "ar", "pt", "ru", "de", "fr"].contains(languageCode)
        return usesWordSeparators ? "\(left) \(right)" : "\(left)\(right)"
    }

    private func clearRecognitionStateLocked() {
        recognitionTask = nil
        recognitionRequest = nil
        recognizer = nil
        onResultHandler = nil
        segmentText = ""
        committedText = ""
    }

    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
