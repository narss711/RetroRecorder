import ActivityKit
import AVFoundation
import Accelerate
import CoreLocation
import Foundation
import MediaPlayer
import onnxruntime_objc

enum AppPermissionKind: String, CaseIterable, Identifiable {
    case microphone
    case speechRecognition
    case location

    var id: String { rawValue }
}

enum AppPermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied

    var isAuthorized: Bool {
        self == .authorized
    }
}

enum NoiseReductionMode: String, CaseIterable, Identifiable {
    case off
    case rnnoise
    case deepFilterNetV3
    case dtln

    var id: String { rawValue }

    var isAvailable: Bool {
        switch self {
        case .off, .rnnoise, .deepFilterNetV3, .dtln:
            return true
        }
    }
}

enum EchoCancellationMode: String, CaseIterable, Identifiable {
    case off
    case voiceProcessing

    var id: String { rawValue }

    var isAvailable: Bool {
        true
    }
}

enum RecordingAudioFileFormat: String, CaseIterable, Identifiable {
    case caf
    case wav
    case m4a
    case aiff

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .caf:
            return "caf"
        case .wav:
            return "wav"
        case .m4a:
            return "m4a"
        case .aiff:
            return "aiff"
        }
    }

    var title: String {
        switch self {
        case .caf:
            return "CAF"
        case .wav:
            return "WAV"
        case .m4a:
            return "M4A"
        case .aiff:
            return "AIFF"
        }
    }

    var encodingTitle: String {
        switch self {
        case .m4a:
            return "Apple Lossless (ALAC)"
        case .caf, .wav:
            return "Linear PCM"
        case .aiff:
            return "Linear PCM, Big Endian"
        }
    }

    func subtitle(language: AppLanguage) -> String {
        if language.resolvedLanguage == .english {
            switch self {
            case .caf:
                return "Core Audio file"
            case .wav:
                return "PCM wave file"
            case .m4a:
                return "Apple Lossless"
            case .aiff:
                return "PCM interchange"
            }
        }

        switch self {
        case .caf:
            return "Core Audio 容器"
        case .wav:
            return "PCM 波形文件"
        case .m4a:
            return "Apple Lossless"
        case .aiff:
            return "PCM 交换格式"
        }
    }
}

enum RecordingSampleRate: Int, CaseIterable, Identifiable {
    case hz16000 = 16_000
    case hz22050 = 22_050
    case hz32000 = 32_000
    case hz44100 = 44_100
    case hz48000 = 48_000
    case hz96000 = 96_000

    var id: Int { rawValue }
    var value: Double { Double(rawValue) }

    var title: String {
        switch self {
        case .hz16000:
            return "16 kHz"
        case .hz22050:
            return "22.05 kHz"
        case .hz32000:
            return "32 kHz"
        case .hz44100:
            return "44.1 kHz"
        case .hz48000:
            return "48 kHz"
        case .hz96000:
            return "96 kHz"
        }
    }
}

enum RecordingBitDepth: Int, CaseIterable, Identifiable {
    case int16 = 16
    case int24 = 24
    case float32 = 32

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .int16:
            return "16-bit"
        case .int24:
            return "24-bit"
        case .float32:
            return "32-bit Float"
        }
    }

    var isFloat: Bool {
        self == .float32
    }
}

struct RecordingAudioConfiguration: Equatable {
    let fileFormat: RecordingAudioFileFormat
    let sampleRate: RecordingSampleRate
    let bitDepth: RecordingBitDepth

    var qualityText: String {
        "\(sampleRate.title) · \(bitDepth.title)"
    }

    func fileSettings(channelCount: Int = 1) -> [String: Any] {
        switch fileFormat {
        case .m4a:
            return [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: sampleRate.value,
                AVNumberOfChannelsKey: channelCount,
                AVEncoderBitDepthHintKey: bitDepth.rawValue,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        case .caf, .wav, .aiff:
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: sampleRate.value,
                AVNumberOfChannelsKey: channelCount,
                AVLinearPCMBitDepthKey: bitDepth.rawValue,
                AVLinearPCMIsFloatKey: bitDepth.isFloat,
                AVLinearPCMIsBigEndianKey: fileFormat == .aiff,
                AVLinearPCMIsNonInterleaved: false
            ]
        }
    }
}

enum RecordingTagAddResult: Equatable {
    case added(second: Int)
    case alreadyExists(second: Int)

    var second: Int {
        switch self {
        case let .added(second), let .alreadyExists(second):
            return second
        }
    }

    var isAdded: Bool {
        if case .added = self {
            return true
        }

        return false
    }
}

@MainActor
private final class RecordingLocationProvider: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []
    private var locationContinuations: [CheckedContinuation<RecordingLocationMetadata?, Never>] = []
    private(set) var locationSnapshot: RecordingLocationMetadata?
    private var didPrepare = false

    var cachedLocationSnapshot: RecordingLocationMetadata? {
        locationSnapshot
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func prepare() async {
        guard !didPrepare else {
            return
        }

        didPrepare = true
        let status = await requestAuthorizationIfNeeded()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return
        }

        locationSnapshot = await requestLocationSnapshot()
    }

    func locationSnapshotForRecording() async -> RecordingLocationMetadata? {
        let status = await requestAuthorizationIfNeeded()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        let previousSnapshot = locationSnapshot
        let requestedSnapshot = await requestLocationSnapshot()
        if let requestedSnapshot {
            locationSnapshot = requestedSnapshot
            return requestedSnapshot
        }

        if let cachedLocation = manager.location {
            let snapshot = await makeSnapshot(for: cachedLocation)
            locationSnapshot = snapshot
            return snapshot
        }

        return previousSnapshot
    }

    func requestAuthorization() async -> CLAuthorizationStatus {
        await requestAuthorizationIfNeeded()
    }

    private func requestAuthorizationIfNeeded() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else {
            return status
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuations.append(continuation)
            if authorizationContinuations.count == 1 {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    private func requestLocationSnapshot() async -> RecordingLocationMetadata? {
        await withCheckedContinuation { continuation in
            locationContinuations.append(continuation)
            if locationContinuations.count == 1 {
                manager.requestLocation()
            }
        }
    }

    private func makeSnapshot(for location: CLLocation) async -> RecordingLocationMetadata {
        let address = await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                continuation.resume(returning: Self.shortAddress(from: placemarks?.first))
            }
        }

        return RecordingLocationMetadata(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil,
            timestamp: location.timestamp,
            address: address
        )
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        completeAuthorizationRequests(with: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        completeAuthorizationRequests(with: status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            completeLocationRequest(with: nil)
            return
        }

        Task { @MainActor [weak self] in
            let snapshot = await self?.makeSnapshot(for: location)
            self?.locationSnapshot = snapshot
            self?.completeLocationRequest(with: snapshot)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completeLocationRequest(with: nil)
    }

    private func completeLocationRequest(with snapshot: RecordingLocationMetadata?) {
        guard locationContinuations.isEmpty == false else {
            return
        }

        let continuations = locationContinuations
        locationContinuations.removeAll()
        continuations.forEach { $0.resume(returning: snapshot) }
    }

    private func completeAuthorizationRequests(with status: CLAuthorizationStatus) {
        guard authorizationContinuations.isEmpty == false else {
            return
        }

        let continuations = authorizationContinuations
        authorizationContinuations.removeAll()
        continuations.forEach { $0.resume(returning: status) }
    }

    private nonisolated static func shortAddress(from placemark: CLPlacemark?) -> String? {
        guard let placemark else {
            return nil
        }

        let streetAddress = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if streetAddress.isEmpty == false {
            return streetAddress
        }

        if let subLocality = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines),
           subLocality.isEmpty == false {
            return subLocality
        }

        if let locality = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines),
           locality.isEmpty == false {
            return locality
        }

        return nil
    }

}

@MainActor
final class AudioRecorderViewModel: NSObject, ObservableObject {
    private static let visualizationBarCount = 56
    private static let frequencyBarCount = 48
    private static let rollingWaveformSampleCount = 180
    private static let shadertoyAudioSampleCount = 512

    @Published var inputs: [AudioInputOption] = []
    @Published var selectedInputID: AudioInputOption.ID?
    @Published private(set) var isStartingRecording = false
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var elapsed: TimeInterval = 0
    @Published var powerLevel: Double = 0
    @Published var leftPowerLevel: Double = 0
    @Published var rightPowerLevel: Double = 0
    @Published var waveformLevels: [Double] = Array(repeating: 0, count: 56)
    @Published var frequencyLevels: [Double] = Array(repeating: 0, count: 48)
    @Published var instantaneousFrequencyLevels: [Double] = Array(repeating: 0, count: 48)
    @Published var liveWaveformSamples: [Double] = Array(repeating: 0, count: 180)
    @Published var shadertoySpectrumLevels: [Double] = Array(repeating: 0, count: 512)
    @Published var shadertoyWaveformSamples: [Double] = Array(repeating: 0, count: 512)
    @Published var recordings: [RecordingItem] = []
    @Published var playingRecordingID: RecordingItem.ID?
    @Published var playbackElapsed: TimeInterval = 0
    @Published var transcribingRecordingID: RecordingItem.ID?
    @Published var copiedRecordingID: RecordingItem.ID?
    @Published var reviewRecording: RecordingItem?
    @Published var localeChoices = SpeechLanguageOption.supportedOptions()
    @Published var liveRecognitionLanguageIdentifier: String {
        didSet {
            UserDefaults.standard.set(liveRecognitionLanguageIdentifier, forKey: Self.liveRecognitionLanguageDefaultsKey)
        }
    }
    @Published var lastInputRefreshAt: Date?
    @Published var errorMessage: String?
    @Published var liveTranscript = ""
    @Published var liveActivityStatusText: String?
    @Published var activeRecordingTagTimes: [TimeInterval] = []
    @Published var transcriptionEngine: TranscriptionEngine {
        didSet {
            UserDefaults.standard.set(transcriptionEngine.rawValue, forKey: TranscriptionEngine.storageKey)
        }
    }
    @Published var noiseReductionMode: NoiseReductionMode {
        didSet {
            UserDefaults.standard.set(noiseReductionMode.rawValue, forKey: Self.noiseReductionModeDefaultsKey)
        }
    }
    @Published var echoCancellationMode: EchoCancellationMode {
        didSet {
            UserDefaults.standard.set(echoCancellationMode.rawValue, forKey: Self.echoCancellationModeDefaultsKey)
        }
    }
    @Published var recordingFileFormat: RecordingAudioFileFormat {
        didSet {
            UserDefaults.standard.set(recordingFileFormat.rawValue, forKey: Self.recordingFileFormatDefaultsKey)
        }
    }
    @Published var recordingSampleRate: RecordingSampleRate {
        didSet {
            UserDefaults.standard.set(recordingSampleRate.rawValue, forKey: Self.recordingSampleRateDefaultsKey)
        }
    }
    @Published var recordingBitDepth: RecordingBitDepth {
        didSet {
            UserDefaults.standard.set(recordingBitDepth.rawValue, forKey: Self.recordingBitDepthDefaultsKey)
        }
    }

    private static let noiseReductionModeDefaultsKey = "noiseReductionMode"
    private static let noiseReductionDefaultsKey = "noiseReductionEnabled"
    private static let echoCancellationModeDefaultsKey = "echoCancellationMode"
    private static let recordingFileFormatDefaultsKey = "recordingFileFormat"
    private static let recordingSampleRateDefaultsKey = "recordingSampleRate"
    private static let recordingBitDepthDefaultsKey = "recordingBitDepth"
    private static let liveRecognitionLanguageDefaultsKey = "liveRecognitionLanguage"
    private let inputManager = AudioSessionInputManager()
    private let locationProvider = RecordingLocationProvider()
    private let transcriber = SpeechTranscriber()
    private let liveSpeechRecognizer = LiveSpeechRecognizer()
    private var recorder: AVAudioRecorder?
    private var denoisedRecorder: DenoisedAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?
    private var playbackTimer: Timer?
    private var playbackRemoteCommandTargets: [(command: MPRemoteCommand, token: Any)] = []
    private var lastNowPlayingTime: TimeInterval = -1
    private var inputRefreshTimer: Timer?
    private var liveActivityCommandTimer: Timer?
    private var playbackSessionLeaseCount = 0
    private var routeObserver: NSObjectProtocol?
    private var cloudStoreObserver: NSObjectProtocol?
    private var knownInputIDs = Set<AudioInputOption.ID>()
    private var activeRecordingURL: URL?
    private var recordingLiveActivity: Activity<RecordingLiveActivityAttributes>?
    private var recordingLiveActivityTimerStartDate: Date?

    override init() {
        if let storedEngine = UserDefaults.standard.string(forKey: TranscriptionEngine.storageKey) {
            transcriptionEngine = TranscriptionEngine.value(for: storedEngine)
        } else {
            transcriptionEngine = .appleSpeech
        }

        if let storedMode = UserDefaults.standard.string(forKey: Self.noiseReductionModeDefaultsKey),
           let mode = NoiseReductionMode(rawValue: storedMode) {
            noiseReductionMode = mode.isAvailable ? mode : .rnnoise
        } else {
            let legacyEnabled = UserDefaults.standard.object(forKey: Self.noiseReductionDefaultsKey) as? Bool ?? true
            noiseReductionMode = legacyEnabled ? .rnnoise : .off
        }

        if let storedEchoMode = UserDefaults.standard.string(forKey: Self.echoCancellationModeDefaultsKey),
           let mode = EchoCancellationMode(rawValue: storedEchoMode) {
            echoCancellationMode = mode.isAvailable ? mode : .off
        } else {
            echoCancellationMode = .off
        }

        if let storedFormat = UserDefaults.standard.string(forKey: Self.recordingFileFormatDefaultsKey),
           let format = RecordingAudioFileFormat(rawValue: storedFormat) {
            recordingFileFormat = format
        } else {
            recordingFileFormat = .caf
        }

        let storedSampleRate = UserDefaults.standard.integer(forKey: Self.recordingSampleRateDefaultsKey)
        recordingSampleRate = RecordingSampleRate(rawValue: storedSampleRate) ?? .hz48000

        let storedBitDepth = UserDefaults.standard.integer(forKey: Self.recordingBitDepthDefaultsKey)
        recordingBitDepth = RecordingBitDepth(rawValue: storedBitDepth) ?? .int24

        let availableLanguages = SpeechLanguageOption.supportedOptions()
        let storedLanguage = UserDefaults.standard.string(forKey: Self.liveRecognitionLanguageDefaultsKey)
            .map(SpeechLanguageOption.normalized)
        let preferredLanguage = storedLanguage.flatMap { stored in
            availableLanguages.first(where: { $0.id.caseInsensitiveCompare(stored) == .orderedSame })?.id
        } ?? SpeechLanguageOption.systemDefaultIdentifier(in: availableLanguages)
        liveRecognitionLanguageIdentifier = preferredLanguage

        super.init()
        cloudStoreObserver = NotificationCenter.default.addObserver(
            forName: .recordingCloudStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isRecording else { return }
                self.recordings = RecordingStore.loadRecordings()
            }
        }
        recordings = RecordingStore.loadRecordings()
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshInputs(activateSession: false)
            }
        }
        startInputRefreshTimer()
    }

    deinit {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
        if let cloudStoreObserver {
            NotificationCenter.default.removeObserver(cloudStoreObserver)
        }
        meterTimer?.invalidate()
        playbackTimer?.invalidate()
        inputRefreshTimer?.invalidate()
        liveActivityCommandTimer?.invalidate()
        let activity = recordingLiveActivity
        Task { [activity] in
            await activity?.end(nil, dismissalPolicy: .immediate)
        }
        transcriber.cancel()
        liveSpeechRecognizer.cancel()
    }

    func prepare() async {
        await endExistingRecordingLiveActivities()

        do {
            try inputManager.prepareSession(echoCancellationEnabled: echoCancellationMode == .voiceProcessing)
            refreshInputs(activateSession: false)
        } catch {
            errorMessage = error.localizedDescription
        }

        Task { @MainActor [locationProvider] in
            await locationProvider.prepare()
        }
    }

    var recordingAudioConfiguration: RecordingAudioConfiguration {
        RecordingAudioConfiguration(
            fileFormat: recordingFileFormat,
            sampleRate: recordingSampleRate,
            bitDepth: recordingBitDepth
        )
    }

    var recordingQualityText: String {
        recordingAudioConfiguration.qualityText
    }

    private var liveActivityInputName: String {
        let input = inputs.first { $0.id == selectedInputID } ?? inputs.first
        let deviceName = input?.deviceName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return deviceName.isEmpty ? "Microphone" : deviceName
    }

    private var liveActivityNoiseReductionName: String {
        switch noiseReductionMode {
        case .off:
            return "Off"
        case .rnnoise:
            return "RNNoise"
        case .deepFilterNetV3:
            return "DeepFilterNet V3"
        case .dtln:
            return "DTLN"
        }
    }

    private var liveActivityEchoCancellationName: String {
        switch echoCancellationMode {
        case .off:
            return "Off"
        case .voiceProcessing:
            return "Voice Processing"
        }
    }

    func refreshInputs() {
        refreshInputs(activateSession: true)
    }

    private func refreshInputs(activateSession: Bool) {
        let shouldActivateSession = activateSession && playbackSessionLeaseCount == 0

        if shouldActivateSession, !isRecording, playingRecordingID == nil {
            try? inputManager.prepareSession()
        }

        let refreshedInputs = inputManager.availableInputs()
        inputs = refreshedInputs
        lastInputRefreshAt = Date()

        guard !isRecording, playingRecordingID == nil else {
            return
        }

        let inputIDs = Set(refreshedInputs.map(\.id))
        let newlyDetectedInputs = refreshedInputs.filter { knownInputIDs.contains($0.id) == false }
        knownInputIDs = inputIDs

        guard refreshedInputs.isEmpty == false else {
            selectedInputID = nil
            return
        }

        if let newestInput = newlyDetectedInputs.last {
            applyPreferredInput(newestInput)
            return
        }

        if let selectedInputID, refreshedInputs.contains(where: { $0.id == selectedInputID }) {
            return
        }

        if let currentInputID = inputManager.currentInputID,
           let currentInput = refreshedInputs.first(where: { $0.id == currentInputID }) {
            selectedInputID = currentInput.id
            return
        }

        if let fallbackInput = refreshedInputs.last ?? refreshedInputs.first {
            applyPreferredInput(fallbackInput)
        }
    }

    func beginPlaybackSession() {
        playbackSessionLeaseCount += 1
        inputRefreshTimer?.fireDate = .distantFuture
    }

    func endPlaybackSession() {
        playbackSessionLeaseCount = max(0, playbackSessionLeaseCount - 1)

        guard playbackSessionLeaseCount == 0 else {
            return
        }

        inputRefreshTimer?.fireDate = Date().addingTimeInterval(2.5)
        guard !isRecording, playingRecordingID == nil else {
            return
        }

        refreshInputs(activateSession: true)
    }

    func permissionStatus(for permission: AppPermissionKind) -> AppPermissionStatus {
        switch permission {
        case .microphone:
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return .authorized
            case .undetermined:
                return .notDetermined
            case .denied:
                return .denied
            @unknown default:
                return .denied
            }
        case .speechRecognition:
            switch transcriber.authorizationStatus {
            case .authorized:
                return .authorized
            case .notDetermined:
                return .notDetermined
            case .denied, .restricted:
                return .denied
            @unknown default:
                return .denied
            }
        case .location:
            switch locationProvider.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                return .authorized
            case .notDetermined:
                return .notDetermined
            case .denied, .restricted:
                return .denied
            @unknown default:
                return .denied
            }
        }
    }

    func requestPermission(_ permission: AppPermissionKind) async -> AppPermissionStatus {
        switch permission {
        case .microphone:
            _ = await requestMicrophonePermission()
        case .speechRecognition:
            _ = await transcriber.requestAuthorization()
        case .location:
            _ = await locationProvider.requestAuthorization()
        }

        return permissionStatus(for: permission)
    }

    func localeIdentifier(for recording: RecordingItem) -> String {
        recording.resolvedLanguageIdentifier
    }

    func languageTitle(for recording: RecordingItem) -> String {
        SpeechLanguageOption.option(for: localeIdentifier(for: recording)).displayName
    }

    func setLiveRecognitionLanguage(_ identifier: String) {
        let normalizedIdentifier = SpeechLanguageOption.normalized(identifier)

        guard normalizedIdentifier.isEmpty == false else {
            return
        }

        if localeChoices.contains(where: { $0.id == normalizedIdentifier }) == false {
            localeChoices.insert(SpeechLanguageOption.option(for: normalizedIdentifier), at: 0)
        }

        guard normalizedIdentifier != liveRecognitionLanguageIdentifier else {
            return
        }

        liveRecognitionLanguageIdentifier = normalizedIdentifier

        guard isRecording, let recordingURL = activeRecordingURL else {
            return
        }

        let previousTranscript = liveTranscript
        try? RecordingStore.saveLanguageIdentifier(normalizedIdentifier, for: recordingURL)

        Task { @MainActor [weak self] in
            await self?.startLiveRecognition(
                for: recordingURL,
                initialTranscript: previousTranscript
            )
        }
    }

    func setLocaleIdentifier(_ identifier: String, for recording: RecordingItem) {
        let normalizedIdentifier = SpeechLanguageOption.normalized(identifier)

        guard !normalizedIdentifier.isEmpty else {
            return
        }

        if localeChoices.contains(where: { $0.id == normalizedIdentifier }) == false {
            localeChoices.insert(SpeechLanguageOption.option(for: normalizedIdentifier), at: 0)
        }

        do {
            try RecordingStore.saveLanguageIdentifier(normalizedIdentifier, for: recording.url)
            recordings = RecordingStore.loadRecordings()
            refreshReviewRecordingIfNeeded(matching: recording.url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameRecording(_ recording: RecordingItem, to title: String) {
        do {
            try RecordingStore.saveTitle(title, for: recording.url)
            recordings = RecordingStore.loadRecordings()
            refreshReviewRecordingIfNeeded(matching: recording.url)
        } catch {
            errorMessage = "重命名失败：\(error.localizedDescription)"
        }
    }

    func saveTranscript(_ transcript: String, for recording: RecordingItem) {
        do {
            try RecordingStore.saveTranscript(transcript, languageIdentifier: localeIdentifier(for: recording), for: recording.url)
            recordings = RecordingStore.loadRecordings()
            refreshReviewRecordingIfNeeded(matching: recording.url)
        } catch {
            errorMessage = "保存文本失败：\(error.localizedDescription)"
        }
    }

    func saveProcessedRecording(from sourceURL: URL, title: String, sourceRecording: RecordingItem) {
        do {
            let outputURL = try RecordingStore.makeRecordingURL(
                filename: title,
                fileExtension: sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
            )

            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            try FileManager.default.moveItem(at: sourceURL, to: outputURL)
            try RecordingStore.saveTitle(title, for: outputURL)

            if let transcript = sourceRecording.transcript {
                try RecordingStore.saveTranscript(
                    transcript,
                    languageIdentifier: localeIdentifier(for: sourceRecording),
                    for: outputURL
                )
            }

            recordings = RecordingStore.loadRecordings()
        } catch {
            errorMessage = "保存处理后录音失败：\(error.localizedDescription)"
        }
    }

    func saveTagTimes(_ tagTimes: [TimeInterval], for recording: RecordingItem) {
        do {
            try RecordingStore.saveTagTimes(tagTimes, for: recording.url)
            recordings = RecordingStore.loadRecordings()
            refreshReviewRecordingIfNeeded(matching: recording.url)
        } catch {
            errorMessage = "保存标签失败：\(error.localizedDescription)"
        }
    }

    var hasTagAtCurrentRecordingTime: Bool {
        let currentSecond = Int(max(0, elapsed).rounded())
        return activeRecordingTagTimes.contains { Int($0.rounded()) == currentSecond }
    }

    @discardableResult
    func addTagAtCurrentRecordingTime() -> RecordingTagAddResult? {
        guard isRecording else {
            return nil
        }

        let currentSecond = Int(max(0, elapsed).rounded())
        guard activeRecordingTagTimes.contains(where: { Int($0.rounded()) == currentSecond }) == false else {
            return .alreadyExists(second: currentSecond)
        }

        activeRecordingTagTimes = normalizedRecordingTagTimes(activeRecordingTagTimes + [TimeInterval(currentSecond)])
        return .added(second: currentSecond)
    }

    func selectInput(_ input: AudioInputOption) {
        guard !isRecording else {
            errorMessage = "录音中不能切换音源。"
            return
        }

        do {
            try inputManager.prepareSession()
            try inputManager.selectInput(id: input.id)
            selectedInputID = input.id
            knownInputIDs = Set(inputs.map(\.id))
            refreshInputs(activateSession: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startRecording() async {
        guard !isRecording, !isStartingRecording else {
            return
        }

        isStartingRecording = true
        defer { isStartingRecording = false }
        await Task.yield()

        stopPlayback()

        guard await requestMicrophonePermission() else {
            errorMessage = "没有麦克风权限。"
            return
        }

        do {
            try inputManager.prepareSession(echoCancellationEnabled: echoCancellationMode == .voiceProcessing)
            refreshInputs(activateSession: false)

            if let selectedInputID, inputs.contains(where: { $0.id == selectedInputID }) {
                try inputManager.selectInput(id: selectedInputID)
            } else if let firstInput = inputs.first {
                try inputManager.selectInput(id: firstInput.id)
                selectedInputID = firstInput.id
            }

            let audioConfiguration = recordingAudioConfiguration
            let recordingDate = Date()
            let locationSnapshot = locationProvider.cachedLocationSnapshot
            let recordingTitle = RecordingStore.defaultRecordingTitle(
                locationName: locationSnapshot?.address,
                date: recordingDate
            )
            let url = try RecordingStore.makeRecordingURL(
                filename: recordingTitle,
                fileExtension: audioConfiguration.fileFormat.fileExtension
            )
            let selectedInput = inputs.first { $0.id == selectedInputID } ?? inputs.first
            let recordingMetadata = RecordingMetadata(
                languageIdentifier: liveRecognitionLanguageIdentifier,
                title: nil,
                tagTimes: nil,
                recordIdentifier: UUID().uuidString,
                modifiedAt: recordingDate,
                recordedAt: recordingDate,
                location: locationSnapshot,
                fileFormat: audioConfiguration.fileFormat.title,
                sampleRate: audioConfiguration.sampleRate.value,
                bitDepth: audioConfiguration.bitDepth.rawValue,
                channelCount: 1,
                inputName: selectedInput?.deviceName,
                inputUID: selectedInput?.id,
                inputPortType: selectedInput?.portType,
                noiseReductionMode: noiseReductionMode.rawValue,
                echoCancellationMode: echoCancellationMode.rawValue,
                encoding: audioConfiguration.fileFormat.encodingTitle
            )
            activeRecordingURL = url
            elapsed = 0
            powerLevel = 0
            leftPowerLevel = 0
            rightPowerLevel = 0
            resetWaveformLevels()
            liveTranscript = ""
            liveActivityStatusText = nil
            activeRecordingTagTimes = []

            switch noiseReductionMode {
            case .off, .rnnoise, .deepFilterNetV3, .dtln:
                let liveRecognizer = liveSpeechRecognizer
                let nextRecorder = try DenoisedAudioRecorder(
                    url: url,
                    mode: noiseReductionMode,
                    audioConfiguration: audioConfiguration,
                    echoCancellationEnabled: echoCancellationMode == .voiceProcessing,
                    speechBufferHandler: { buffer in
                        liveRecognizer.append(buffer)
                    },
                    meterHandler: { [weak self] left, right, elapsed in
                        Task { @MainActor in
                            guard let self, self.isRecording, !self.isPaused else {
                                return
                            }

                            self.leftPowerLevel = left
                            self.rightPowerLevel = right
                            self.powerLevel = max(left, right)
                            self.elapsed = elapsed
                        }
                    },
                    visualizationHandler: { [weak self] levels, frequencies, shadertoySpectrum, shadertoyWaveform in
                        Task { @MainActor in
                            self?.applyWaveformLevels(
                                levels,
                                frequencyLevels: frequencies,
                                shadertoySpectrum: shadertoySpectrum,
                                shadertoyWaveform: shadertoyWaveform
                            )
                        }
                    },
                    failureHandler: { [weak self] error in
                        Task { @MainActor in
                            guard let self, self.isRecording else {
                                return
                            }

                            self.errorMessage = "降噪处理失败：\(error.localizedDescription)"
                            self.finishRecording(successfully: false)
                        }
                    }
                )

                try nextRecorder.start()
                denoisedRecorder = nextRecorder
                try RecordingStore.writeMetadata(recordingMetadata, for: url)
                isRecording = true
                isPaused = false
                startRecordingAncillaryServices(recordingURL: url, recordingDate: recordingDate)
                return
            }
        } catch {
            liveSpeechRecognizer.cancel()
            denoisedRecorder?.stop()
            denoisedRecorder = nil
            recorder = nil
            activeRecordingURL = nil
            isRecording = false
            isPaused = false
            elapsed = 0
            resetWaveformLevels()
            liveTranscript = ""
            liveActivityStatusText = nil
            activeRecordingTagTimes = []
            stopLiveActivityCommandPolling()
            endRecordingLiveActivity(finalElapsed: elapsed)
            errorMessage = error.localizedDescription
        }
    }

    func pauseOrResumeRecording() {
        guard isRecording else {
            return
        }

        if isPaused {
            denoisedRecorder?.setPaused(false)
            recorder?.record()
            isPaused = false
            recordingLiveActivityTimerStartDate = Date().addingTimeInterval(-elapsed)
            liveActivityStatusText = recordingLiveActivity == nil ? "Live Activity 未启动" : "Live Activity 录音中"
            updateRecordingLiveActivity()
        } else {
            denoisedRecorder?.setPaused(true)
            recorder?.pause()
            isPaused = true
            powerLevel = 0
            leftPowerLevel = 0
            rightPowerLevel = 0
            resetWaveformLevels()
            liveActivityStatusText = recordingLiveActivity == nil ? "Live Activity 未启动" : "Live Activity 已暂停"
            updateRecordingLiveActivity()
        }
    }

    func stopRecording() {
        guard isRecording else {
            return
        }

        if let denoisedRecorder {
            liveSpeechRecognizer.stop()
            denoisedRecorder.stop()
            self.denoisedRecorder = nil
            finishRecording(successfully: true)
            return
        }

        recorder?.stop()
        liveSpeechRecognizer.stop()
        stopMeterTimer()
        let finalElapsed = elapsed
        isRecording = false
        isPaused = false
        powerLevel = 0
        leftPowerLevel = 0
        rightPowerLevel = 0
        elapsed = 0
        resetWaveformLevels()
        liveTranscript = ""
        liveActivityStatusText = nil
        activeRecordingTagTimes = []
        stopLiveActivityCommandPolling()
        endRecordingLiveActivity(finalElapsed: finalElapsed)
    }

    func play(_ recording: RecordingItem) {
        if playingRecordingID == recording.id {
            stopPlayback()
            return
        }

        guard !isRecording else {
            errorMessage = "请先停止录音。"
            return
        }

        if playingRecordingID != nil {
            stopPlayback()
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let nextPlayer = try AVAudioPlayer(contentsOf: recording.url)
            nextPlayer.delegate = self
            nextPlayer.prepareToPlay()
            nextPlayer.play()

            player = nextPlayer
            playingRecordingID = recording.id
            installRemoteCommandHandlers(for: recording)
            updatePlaybackProgress()
            startPlaybackTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopCurrentPlayback() {
        stopPlayback()
    }

    func transcribe(_ recording: RecordingItem) async {
        guard transcribingRecordingID == nil else {
            return
        }

        stopPlayback()
        transcribingRecordingID = recording.id
        defer { transcribingRecordingID = nil }

        do {
            let localeIdentifier = localeIdentifier(for: recording)
            let transcript = try await recognizeTranscript(for: recording)
            try RecordingStore.saveTranscript(transcript, languageIdentifier: localeIdentifier, for: recording.url)
            recordings = RecordingStore.loadRecordings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recognizeTranscriptPreview(_ recording: RecordingItem) async -> String? {
        guard transcribingRecordingID == nil else {
            return nil
        }

        stopPlayback()
        transcribingRecordingID = recording.id
        defer { transcribingRecordingID = nil }

        do {
            return try await recognizeTranscript(for: recording)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func recognizeTranscript(for recording: RecordingItem) async throws -> String {
        try await transcriber.transcribe(
            url: recording.url,
            localeIdentifier: localeIdentifier(for: recording),
            engine: transcriptionEngine
        )
    }

    func markTranscriptCopied(_ recording: RecordingItem) {
        copiedRecordingID = recording.id

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                if self?.copiedRecordingID == recording.id {
                    self?.copiedRecordingID = nil
                }
            }
        }
    }

    func delete(_ recording: RecordingItem) {
        deleteRecordings(with: [recording.id])
    }

    func deleteRecordings(with ids: Set<RecordingItem.ID>) {
        guard ids.isEmpty == false else {
            return
        }

        if let transcribingRecordingID, ids.contains(transcribingRecordingID) {
            errorMessage = "请等待转文本完成后再删除。"
            return
        }

        stopPlaybackIfNeeded(for: ids)

        do {
            let itemsToDelete = recordings.filter { ids.contains($0.id) }
            try RecordingStore.delete(itemsToDelete)
            if let copiedRecordingID, ids.contains(copiedRecordingID) {
                self.copiedRecordingID = nil
            }
            recordings = RecordingStore.loadRecordings()
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }

    private func stopPlaybackIfNeeded(for ids: Set<RecordingItem.ID>) {
        if let playingRecordingID, ids.contains(playingRecordingID) {
            stopPlayback()
        }
    }

    private func startRecordingAncillaryServices(recordingURL: URL, recordingDate: Date) {
        Task { @MainActor [weak self] in
            await self?.startLiveRecognition(for: recordingURL)
        }

        Task { @MainActor [weak self] in
            guard let self,
                  self.isRecording,
                  self.activeRecordingURL == recordingURL else {
                return
            }

            await self.startRecordingLiveActivity(recordingURL: recordingURL)
        }

        Task { @MainActor [weak self] in
            await self?.refreshLocationMetadata(
                for: recordingURL,
                recordingDate: recordingDate
            )
        }
    }

    private func startLiveRecognition(
        for recordingURL: URL,
        initialTranscript: String = ""
    ) async {
        let languageIdentifier = liveRecognitionLanguageIdentifier

        do {
            try await liveSpeechRecognizer.start(
                localeIdentifier: languageIdentifier,
                onResult: { [weak self] transcript in
                    Task { @MainActor in
                        guard let self,
                              self.isRecording,
                              self.activeRecordingURL == recordingURL else {
                            return
                        }

                        self.liveTranscript = self.mergeLiveTranscript(
                            initialTranscript,
                            with: transcript,
                            languageIdentifier: languageIdentifier
                        )
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor in
                        guard let self, self.isRecording else {
                            return
                        }

                        self.liveTranscript = error.localizedDescription
                    }
                }
            )

            guard isRecording, activeRecordingURL == recordingURL else {
                liveSpeechRecognizer.cancel()
                return
            }
        } catch {
            if isRecording, activeRecordingURL == recordingURL {
                liveTranscript = error.localizedDescription
            }
        }
    }

    private func mergeLiveTranscript(
        _ prefix: String,
        with next: String,
        languageIdentifier: String
    ) -> String {
        let prefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = next.trimmingCharacters(in: .whitespacesAndNewlines)

        guard prefix.isEmpty == false else { return next }
        guard next.isEmpty == false else { return prefix }
        guard prefix != next else { return prefix }

        let languageCode = languageIdentifier.split(separator: "-").first.map(String.init) ?? languageIdentifier
        let usesWordSeparators = ["en", "es", "ar", "pt", "ru", "de", "fr"].contains(languageCode)
        return usesWordSeparators ? "\(prefix) \(next)" : "\(prefix)\(next)"
    }

    private func refreshLocationMetadata(for recordingURL: URL, recordingDate: Date) async {
        guard let locationSnapshot = await locationProvider.locationSnapshotForRecording() else {
            return
        }

        do {
            var metadata = RecordingStore.metadata(for: recordingURL)
            metadata.location = locationSnapshot

            if metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
               let address = locationSnapshot.address?.trimmingCharacters(in: .whitespacesAndNewlines),
               address.isEmpty == false {
                metadata.title = RecordingStore.defaultRecordingTitle(
                    locationName: address,
                    date: recordingDate
                )
            }

            metadata.modifiedAt = Date()
            try RecordingStore.writeMetadata(metadata, for: recordingURL)

            if !isRecording || activeRecordingURL != recordingURL {
                recordings = RecordingStore.loadRecordings()
            }
        } catch {
            guard isRecording, activeRecordingURL == recordingURL else {
                return
            }

            errorMessage = "保存定位信息失败：\(error.localizedDescription)"
        }
    }

    func requestMicrophonePermission() async -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private var liveActivityAppLanguage: AppLanguage {
        AppLanguage.value(
            for: UserDefaults.standard.string(forKey: AppLanguage.storageKey)
                ?? AppLanguage.system.rawValue
        )
    }

    private func startRecordingLiveActivity(recordingURL: URL) async {
        RecordingLiveActivityCommandStore.clearPendingCommand()
        liveActivityStatusText = "Live Activity 启动中"
        await endExistingRecordingLiveActivities()

        guard isRecording, activeRecordingURL == recordingURL else {
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityStatusText = "Live Activity 被系统禁用"
            errorMessage = "系统没有允许实时活动。请在 iPhone 设置里开启 RetroRecorder 的 Live Activities，并确认锁屏允许显示。"
            return
        }

        let timerStartDate = Date().addingTimeInterval(-elapsed)
        recordingLiveActivityTimerStartDate = timerStartDate

        let attributes = RecordingLiveActivityAttributes(
            recordingID: recordingURL.lastPathComponent,
            title: recordingURL.deletingPathExtension().lastPathComponent,
            recordingStatusTitle: liveActivityAppLanguage.text(.recordingInProgress),
            pausedStatusTitle: liveActivityAppLanguage.text(.recordingPaused),
            mode: RecordingLiveActivityMode(
                inputName: liveActivityInputName,
                fileFormat: recordingFileFormat.title,
                sampleSpecification: "\(recordingSampleRate.title) / \(recordingBitDepth.title)",
                noiseReductionName: liveActivityNoiseReductionName,
                isNoiseReductionEnabled: noiseReductionMode != .off,
                echoCancellationName: liveActivityEchoCancellationName,
                isEchoCancellationEnabled: echoCancellationMode != .off
            )
        )
        let state = RecordingLiveActivityAttributes.ContentState(
            timerStartDate: timerStartDate,
            elapsedAtPause: elapsed,
            isPaused: false
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            let activity: Activity<RecordingLiveActivityAttributes>
            if #available(iOS 18.0, *) {
                activity = try Activity<RecordingLiveActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil,
                    style: .standard
                )
            } else {
                activity = try Activity<RecordingLiveActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            }

            recordingLiveActivity = activity
            liveActivityStatusText = "Live Activity 已创建"
            startLiveActivityCommandPolling()
        } catch {
            recordingLiveActivity = nil
            recordingLiveActivityTimerStartDate = nil
            liveActivityStatusText = "Live Activity 启动失败"
            errorMessage = "Live Activities 启动失败：\(error.localizedDescription)"
        }
    }

    private func endExistingRecordingLiveActivities() async {
        for activity in Activity<RecordingLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func updateRecordingLiveActivity() {
        guard let recordingLiveActivity else {
            return
        }

        let timerStartDate: Date
        if isPaused {
            timerStartDate = Date().addingTimeInterval(-elapsed)
        } else {
            timerStartDate = recordingLiveActivityTimerStartDate ?? Date().addingTimeInterval(-elapsed)
            recordingLiveActivityTimerStartDate = timerStartDate
        }

        let state = RecordingLiveActivityAttributes.ContentState(
            timerStartDate: timerStartDate,
            elapsedAtPause: elapsed,
            isPaused: isPaused
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task { [recordingLiveActivity, content] in
            await recordingLiveActivity.update(content)
        }
    }

    private func endRecordingLiveActivity(finalElapsed: TimeInterval) {
        let activity = recordingLiveActivity
        recordingLiveActivity = nil
        recordingLiveActivityTimerStartDate = nil
        RecordingLiveActivityCommandStore.clearPendingCommand()

        guard let activity else {
            return
        }

        let state = RecordingLiveActivityAttributes.ContentState(
            timerStartDate: Date().addingTimeInterval(-finalElapsed),
            elapsedAtPause: finalElapsed,
            isPaused: true
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task { [activity, content] in
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }

    private func startLiveActivityCommandPolling() {
        stopLiveActivityCommandPolling()

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording,
                      let payload = RecordingLiveActivityCommandStore.consumePendingCommand() else {
                    return
                }

                switch payload.command {
                case .togglePause:
                    self.pauseOrResumeRecording()
                case .stop:
                    self.stopRecording()
                }
            }
        }

        liveActivityCommandTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopLiveActivityCommandPolling() {
        liveActivityCommandTimer?.invalidate()
        liveActivityCommandTimer = nil
    }

    private func finishRecording(successfully flag: Bool) {
        let finishedRecordingURL = activeRecordingURL
        let capturedTranscript = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let capturedLanguageIdentifier = liveRecognitionLanguageIdentifier
        let capturedTagTimes = activeRecordingTagTimes
        let finalElapsed = elapsed

        liveSpeechRecognizer.stop()
        stopMeterTimer()
        stopLiveActivityCommandPolling()
        endRecordingLiveActivity(finalElapsed: finalElapsed)
        recorder = nil
        denoisedRecorder = nil
        activeRecordingURL = nil
        isRecording = false
        isPaused = false
        powerLevel = 0
        leftPowerLevel = 0
        rightPowerLevel = 0
        elapsed = 0
        resetWaveformLevels()
        liveTranscript = ""
        liveActivityStatusText = nil
        activeRecordingTagTimes = []

        if flag, let finishedRecordingURL, capturedTagTimes.isEmpty == false {
            do {
                try RecordingStore.saveTagTimes(capturedTagTimes, for: finishedRecordingURL)
            } catch {
                errorMessage = "保存标签失败：\(error.localizedDescription)"
            }
        }

        recordings = RecordingStore.loadRecordings()

        if flag, let finishedRecordingURL {
            scheduleReviewPresentation(
                for: finishedRecordingURL,
                transcript: capturedTranscript,
                languageIdentifier: capturedLanguageIdentifier
            )
        } else if !flag {
            errorMessage = "录音没有成功保存。"
        }

        refreshInputs(activateSession: true)
    }

    private func scheduleReviewPresentation(
        for url: URL,
        transcript: String,
        languageIdentifier: String
    ) {
        let standardizedPath = url.standardizedFileURL.path

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)

            if transcript.isEmpty == false {
                try? RecordingStore.saveTranscript(
                    transcript,
                    languageIdentifier: languageIdentifier,
                    for: url
                )
            }

            recordings = RecordingStore.loadRecordings()

            if let finishedRecording = recordings.first(where: { $0.url.standardizedFileURL.path == standardizedPath }) {
                reviewRecording = finishedRecording
                return
            }

            if let finishedRecording = RecordingStore.loadRecording(at: url) {
                reviewRecording = finishedRecording
            }
        }
    }

    private func refreshReviewRecordingIfNeeded(matching url: URL) {
        let standardizedPath = url.standardizedFileURL.path

        guard reviewRecording?.url.standardizedFileURL.path == standardizedPath,
              let updatedRecording = recordings.first(where: { $0.url.standardizedFileURL.path == standardizedPath }) else {
            return
        }

        reviewRecording = updatedRecording
    }

    private func applyPreferredInput(_ input: AudioInputOption) {
        do {
            try inputManager.selectInput(id: input.id)
            selectedInputID = input.id
        } catch {
            selectedInputID = input.id
        }
    }

    private func stopPlayback() {
        stopPlaybackTimer()
        player?.stop()
        player = nil
        playingRecordingID = nil
        playbackElapsed = 0
        removeRemoteCommandTargets()
        clearNowPlayingInfo()
        refreshInputs(activateSession: playbackSessionLeaseCount == 0)
    }

    private func startPlaybackTimer() {
        stopPlaybackTimer()

        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackProgress()
            }
        }
        playbackTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func updatePlaybackProgress() {
        guard let player, playingRecordingID != nil else {
            playbackElapsed = 0
            stopPlaybackTimer()
            return
        }

        playbackElapsed = min(max(0, player.currentTime), max(0, player.duration))
        updateNowPlayingInfo()
    }

    private func installRemoteCommandHandlers(for recording: RecordingItem) {
        removeRemoteCommandTargets()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        let playToken = commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playFromRemoteControl()
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.playCommand, playToken))

        let pauseToken = commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pauseFromRemoteControl()
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.pauseCommand, pauseToken))

        let toggleToken = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePlaybackFromRemoteControl()
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.togglePlayPauseCommand, toggleToken))

        let backwardToken = commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.jumpPlayback(by: -15)
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.skipBackwardCommand, backwardToken))

        let forwardToken = commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.jumpPlayback(by: 15)
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.skipForwardCommand, forwardToken))

        let positionToken = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task { @MainActor in
                self?.seekPlayback(to: positionEvent.positionTime)
            }
            return .success
        }
        playbackRemoteCommandTargets.append((commandCenter.changePlaybackPositionCommand, positionToken))

        updateNowPlayingInfo(for: recording, force: true)
    }

    private func removeRemoteCommandTargets() {
        for target in playbackRemoteCommandTargets {
            target.command.removeTarget(target.token)
        }
        playbackRemoteCommandTargets.removeAll()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    private func playFromRemoteControl() {
        guard let player, !player.isPlaying else {
            return
        }

        if player.currentTime >= player.duration {
            player.currentTime = 0
            playbackElapsed = 0
        }
        player.play()
        startPlaybackTimer()
        updateNowPlayingInfo(force: true)
    }

    private func pauseFromRemoteControl() {
        guard let player, player.isPlaying else {
            return
        }

        player.pause()
        stopPlaybackTimer()
        updateNowPlayingInfo(force: true)
    }

    private func togglePlaybackFromRemoteControl() {
        if player?.isPlaying == true {
            pauseFromRemoteControl()
        } else {
            playFromRemoteControl()
        }
    }

    private func jumpPlayback(by seconds: TimeInterval) {
        guard let player else {
            return
        }

        player.currentTime = min(max(0, player.currentTime + seconds), max(0, player.duration))
        updatePlaybackProgress()
        updateNowPlayingInfo(force: true)
    }

    private func seekPlayback(to time: TimeInterval) {
        guard let player else {
            return
        }

        player.currentTime = min(max(0, time), max(0, player.duration))
        updatePlaybackProgress()
        updateNowPlayingInfo(force: true)
    }

    private func updateNowPlayingInfo(for recording: RecordingItem? = nil, force: Bool = false) {
        guard let player, let playingRecordingID,
              let activeRecording = recording ?? recordings.first(where: { $0.id == playingRecordingID }) else {
            return
        }

        let time = min(max(0, player.currentTime), max(0, player.duration))
        guard force || abs(time - lastNowPlayingTime) >= 0.25 else {
            return
        }

        lastNowPlayingTime = time
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: activeRecording.title,
            MPMediaItemPropertyArtist: "RetroRecorder",
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? player.rate : 0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: player.rate
        ]
    }

    private func clearNowPlayingInfo() {
        lastNowPlayingTime = -1
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func startInputRefreshTimer() {
        inputRefreshTimer?.invalidate()
        inputRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self,
                      !self.isRecording,
                      self.playingRecordingID == nil,
                      self.playbackSessionLeaseCount == 0 else {
                    return
                }

                self.refreshInputs(activateSession: true)
            }
        }
    }

    private func startMeterTimer() {
        stopMeterTimer()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }

    private func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func resetWaveformLevels() {
        waveformLevels = Array(repeating: 0, count: Self.visualizationBarCount)
        frequencyLevels = Array(repeating: 0, count: Self.frequencyBarCount)
        instantaneousFrequencyLevels = Array(repeating: 0, count: Self.frequencyBarCount)
        liveWaveformSamples = Array(repeating: 0, count: Self.rollingWaveformSampleCount)
        shadertoySpectrumLevels = Array(repeating: 0, count: Self.shadertoyAudioSampleCount)
        shadertoyWaveformSamples = Array(repeating: 0, count: Self.shadertoyAudioSampleCount)
    }

    private func normalizedRecordingTagTimes(_ tagTimes: [TimeInterval]) -> [TimeInterval] {
        Array(Set(tagTimes.map { max(0, $0.rounded()) })).sorted()
    }

    private func applyWaveformLevels(
        _ levels: [Double],
        frequencyLevels frequencies: [Double],
        shadertoySpectrum: [Double],
        shadertoyWaveform: [Double]
    ) {
        guard isRecording, !isPaused else {
            resetWaveformLevels()
            return
        }

        let adjustedWaveformLevels = adjustedLevels(levels, targetCount: Self.visualizationBarCount)
        let adjustedFrequencyLevels = adjustedLevels(frequencies, targetCount: Self.frequencyBarCount)
        let adjustedShadertoySpectrum = adjustedLevels(
            shadertoySpectrum,
            targetCount: Self.shadertoyAudioSampleCount
        )
        let adjustedShadertoyWaveform = adjustedSignedLevels(
            shadertoyWaveform,
            targetCount: Self.shadertoyAudioSampleCount
        )
        instantaneousFrequencyLevels = adjustedFrequencyLevels

        if waveformLevels.count != adjustedWaveformLevels.count {
            waveformLevels = adjustedWaveformLevels
        } else {
            waveformLevels = zip(waveformLevels, adjustedWaveformLevels).map { previous, next in
                let blend = next > previous ? 0.48 : 0.26
                return previous + (next - previous) * blend
            }
        }

        if frequencyLevels.count != adjustedFrequencyLevels.count {
            frequencyLevels = adjustedFrequencyLevels
        } else {
            frequencyLevels = zip(frequencyLevels, adjustedFrequencyLevels).map { previous, next in
                let blend = next > previous ? 0.56 : 0.2
                return previous + (next - previous) * blend
            }
        }

        appendLiveWaveformSamples(from: waveformLevels)

        shadertoySpectrumLevels = zip(shadertoySpectrumLevels, adjustedShadertoySpectrum).map { previous, next in
            let blend = next > previous ? 0.82 : 0.46
            return previous + (next - previous) * blend
        }
        shadertoyWaveformSamples = adjustedShadertoyWaveform
    }

    private func adjustedLevels(_ levels: [Double], targetCount: Int) -> [Double] {
        guard levels.count == targetCount else {
            var adjustedLevels = Array(levels.prefix(targetCount))
            if adjustedLevels.count < targetCount {
                adjustedLevels.append(contentsOf: Array(repeating: 0, count: targetCount - adjustedLevels.count))
            }
            return adjustedLevels
        }

        return levels
    }

    private func adjustedSignedLevels(_ levels: [Double], targetCount: Int) -> [Double] {
        guard levels.count == targetCount else {
            var adjustedLevels = Array(levels.prefix(targetCount)).map { min(1, max(-1, $0)) }
            if adjustedLevels.count < targetCount {
                adjustedLevels.append(contentsOf: Array(repeating: 0, count: targetCount - adjustedLevels.count))
            }
            return adjustedLevels
        }

        return levels.map { min(1, max(-1, $0)) }
    }

    private func appendLiveWaveformSamples(from levels: [Double]) {
        let chunkCount = 8
        var nextSamples: [Double] = []
        nextSamples.reserveCapacity(chunkCount)

        for chunk in 0..<chunkCount {
            let start = chunk * levels.count / chunkCount
            let end = min(levels.count, max(start + 1, (chunk + 1) * levels.count / chunkCount))
            let slice = levels[start..<end]
            let average = slice.reduce(0, +) / Double(slice.count)
            nextSamples.append(min(1, max(0, average)))
        }

        liveWaveformSamples.append(contentsOf: nextSamples)

        if liveWaveformSamples.count > Self.rollingWaveformSampleCount {
            liveWaveformSamples.removeFirst(liveWaveformSamples.count - Self.rollingWaveformSampleCount)
        }
    }

    private func updateMeters() {
        guard let recorder, isRecording, !isPaused else {
            powerLevel = max(0, powerLevel * 0.88)
            leftPowerLevel = max(0, leftPowerLevel * 0.88)
            rightPowerLevel = max(0, rightPowerLevel * 0.88)
            waveformLevels = waveformLevels.map { max(0, $0 * 0.86) }
            frequencyLevels = frequencyLevels.map { max(0, $0 * 0.84) }
            instantaneousFrequencyLevels = instantaneousFrequencyLevels.map { max(0, $0 * 0.58) }
            liveWaveformSamples = liveWaveformSamples.map { max(0, $0 * 0.9) }
            shadertoySpectrumLevels = shadertoySpectrumLevels.map { max(0, $0 * 0.74) }
            shadertoyWaveformSamples = shadertoyWaveformSamples.map { $0 * 0.42 }
            return
        }

        recorder.updateMeters()
        elapsed = recorder.currentTime

        let left = normalizedPower(recorder.averagePower(forChannel: 0))
        let channelCount = Int(recorder.format.channelCount)
        let right = channelCount > 1 ? normalizedPower(recorder.averagePower(forChannel: 1)) : left

        leftPowerLevel = left
        rightPowerLevel = right
        powerLevel = max(left, right)
    }

    private func normalizedPower(_ averagePower: Float) -> Double {
        min(1, max(0, pow(10, Double(averagePower) / 32)))
    }
}

extension AudioRecorderViewModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.finishRecording(successfully: flag)
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.errorMessage = error?.localizedDescription ?? "录音编码失败。"
            self.finishRecording(successfully: false)
        }
    }
}

extension AudioRecorderViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopPlaybackTimer()
            self.playingRecordingID = nil
            self.player = nil
            self.playbackElapsed = 0
            self.removeRemoteCommandTargets()
            self.clearNowPlayingInfo()
            self.refreshInputs()
        }
    }
}

private protocol RealtimeNoiseReductionProcessor: AnyObject {
    var sampleRate: Double { get }
    var frameSize: Int { get }

    func process(frame samples: ArraySlice<Float>) throws -> [Float]
}

private final class PassthroughAudioProcessor: RealtimeNoiseReductionProcessor {
    let sampleRate: Double = 48_000
    let frameSize: Int = 512

    func process(frame samples: ArraySlice<Float>) throws -> [Float] {
        Array(samples)
    }
}

private final class RNNoiseRealtimeProcessor: RealtimeNoiseReductionProcessor {
    let sampleRate: Double = 48_000
    let frameSize: Int

    private let processor: RNNoiseProcessorRef
    private var frameInput: [Float]
    private var frameOutput: [Float]

    init() throws {
        guard let processor = RNNoiseProcessorCreate() else {
            throw noiseReductionError("RNNoise 初始化失败。", domain: "RetroRecorder.RNNoise", code: 2)
        }

        let frameSize = Int(RNNoiseProcessorFrameSize())
        self.processor = processor
        self.frameSize = frameSize
        self.frameInput = Array(repeating: 0, count: frameSize)
        self.frameOutput = Array(repeating: 0, count: frameSize)
    }

    deinit {
        RNNoiseProcessorDestroy(processor)
    }

    func process(frame samples: ArraySlice<Float>) throws -> [Float] {
        for (offset, sample) in samples.enumerated() {
            frameInput[offset] = sample * 32_768
        }

        frameInput.withUnsafeBufferPointer { inputPointer in
            frameOutput.withUnsafeMutableBufferPointer { outputPointer in
                guard let inputAddress = inputPointer.baseAddress,
                      let outputAddress = outputPointer.baseAddress else {
                    return
                }

                RNNoiseProcessorProcessFrame(processor, inputAddress, outputAddress)
            }
        }

        return frameOutput.map { min(1, max(-1, $0 / 32_768)) }
    }
}

private final class DTLNNoiseProcessor: RealtimeNoiseReductionProcessor {
    let sampleRate: Double = 16_000
    let frameSize: Int = DTLNNoiseProcessor.blockShift

    private static let blockLength = 512
    private static let blockShift = 128
    private static let frequencyBins = 257
    private static let recurrentStateCount = 1 * 2 * 128 * 2
    private static let magnitudeShape = [1, 1, frequencyBins].map { NSNumber(value: $0) }
    private static let blockShape = [1, 1, blockLength].map { NSNumber(value: $0) }
    private static let recurrentStateShape = [1, 2, 128, 2].map { NSNumber(value: $0) }
    private static var cachedEnvironment: ORTEnv?

    private let session1: ORTSession
    private let session2: ORTSession
    private let inputNames1: [String]
    private let inputNames2: [String]
    private let outputNames1: [String]
    private let outputNames2: [String]
    private let fft: DTLNFFT

    private var state1 = Array(repeating: Float(0), count: DTLNNoiseProcessor.recurrentStateCount)
    private var state2 = Array(repeating: Float(0), count: DTLNNoiseProcessor.recurrentStateCount)
    private var inputBuffer = Array(repeating: Float(0), count: DTLNNoiseProcessor.blockLength)
    private var outputBuffer = Array(repeating: Float(0), count: DTLNNoiseProcessor.blockLength)

    init() throws {
        guard let fft = DTLNFFT(blockLength: Self.blockLength) else {
            throw noiseReductionError("DTLN FFT 初始化失败。", domain: "RetroRecorder.DTLN", code: 1)
        }

        let environment = try Self.environment()
        let model1 = try Self.makeSession(resourceName: "model_1", environment: environment)
        let model2 = try Self.makeSession(resourceName: "model_2", environment: environment)

        session1 = model1.session
        inputNames1 = model1.inputNames
        outputNames1 = model1.outputNames
        session2 = model2.session
        inputNames2 = model2.inputNames
        outputNames2 = model2.outputNames
        self.fft = fft
    }

    func process(frame samples: ArraySlice<Float>) throws -> [Float] {
        guard samples.count == Self.blockShift else {
            return Array(samples)
        }

        shiftInputBuffer(with: samples)

        let spectrum = fft.forward(inputBuffer)
        let magnitude = (0..<Self.frequencyBins).map { index in
            hypotf(spectrum.real[index], spectrum.imaginary[index])
        }

        let mask = try runFirstModel(magnitude: magnitude)
        var estimatedReal = Array(repeating: Float(0), count: Self.blockLength)
        var estimatedImaginary = Array(repeating: Float(0), count: Self.blockLength)

        for index in 0..<Self.frequencyBins {
            let gain = index < mask.count ? mask[index] : 0
            estimatedReal[index] = spectrum.real[index] * gain
            estimatedImaginary[index] = spectrum.imaginary[index] * gain
        }

        if Self.frequencyBins > 2 {
            for bin in 1..<(Self.frequencyBins - 1) {
                let mirrorBin = Self.blockLength - bin
                estimatedReal[mirrorBin] = estimatedReal[bin]
                estimatedImaginary[mirrorBin] = -estimatedImaginary[bin]
            }
        }

        let estimatedBlock = fft.inverse(real: estimatedReal, imaginary: estimatedImaginary)
        let enhancedBlock = try runSecondModel(block: estimatedBlock)
        return overlapAndEmit(enhancedBlock)
    }

    private static func environment() throws -> ORTEnv {
        if let environment = cachedEnvironment {
            return environment
        }

        let environment = try ORTEnv(loggingLevel: .warning)
        cachedEnvironment = environment
        return environment
    }

    private static func makeSession(resourceName: String, environment: ORTEnv) throws -> (session: ORTSession, inputNames: [String], outputNames: [String]) {
        guard let modelPath = Bundle.main.path(forResource: resourceName, ofType: "onnx") else {
            throw noiseReductionError("找不到 DTLN 模型 \(resourceName).onnx。", domain: "RetroRecorder.DTLN", code: 2)
        }

        let options = try ORTSessionOptions()
        try? options.setIntraOpNumThreads(1)
        try? options.setGraphOptimizationLevel(.all)

        let session = try ORTSession(env: environment, modelPath: modelPath, sessionOptions: options)
        let inputNames = try session.inputNames()
        let outputNames = try session.outputNames()

        guard inputNames.count >= 2, outputNames.count >= 2 else {
            throw noiseReductionError("DTLN 模型输入或输出不完整。", domain: "RetroRecorder.DTLN", code: 3)
        }

        return (session, inputNames, outputNames)
    }

    private func runFirstModel(magnitude: [Float]) throws -> [Float] {
        let inputs = [
            inputNames1[0]: try makeTensorValue(values: magnitude, shape: Self.magnitudeShape),
            inputNames1[1]: try makeTensorValue(values: state1, shape: Self.recurrentStateShape)
        ]
        let outputs = try session1.run(
            withInputs: inputs,
            outputNames: Set(outputNames1),
            runOptions: nil
        )

        guard let maskOutput = outputs[outputNames1[0]],
              let stateOutput = outputs[outputNames1[1]] else {
            throw noiseReductionError("DTLN 频域模型输出无效。", domain: "RetroRecorder.DTLN", code: 4)
        }

        state1 = try floats(from: stateOutput)
        return try floats(from: maskOutput)
    }

    private func runSecondModel(block: [Float]) throws -> [Float] {
        let inputs = [
            inputNames2[0]: try makeTensorValue(values: block, shape: Self.blockShape),
            inputNames2[1]: try makeTensorValue(values: state2, shape: Self.recurrentStateShape)
        ]
        let outputs = try session2.run(
            withInputs: inputs,
            outputNames: Set(outputNames2),
            runOptions: nil
        )

        guard let blockOutput = outputs[outputNames2[0]],
              let stateOutput = outputs[outputNames2[1]] else {
            throw noiseReductionError("DTLN 时域模型输出无效。", domain: "RetroRecorder.DTLN", code: 5)
        }

        state2 = try floats(from: stateOutput)
        return try floats(from: blockOutput)
    }

    private func shiftInputBuffer(with samples: ArraySlice<Float>) {
        for index in 0..<(Self.blockLength - Self.blockShift) {
            inputBuffer[index] = inputBuffer[index + Self.blockShift]
        }

        var writeIndex = Self.blockLength - Self.blockShift
        for sample in samples {
            inputBuffer[writeIndex] = sample
            writeIndex += 1
        }
    }

    private func overlapAndEmit(_ block: [Float]) -> [Float] {
        for index in 0..<(Self.blockLength - Self.blockShift) {
            outputBuffer[index] = outputBuffer[index + Self.blockShift]
        }

        for index in (Self.blockLength - Self.blockShift)..<Self.blockLength {
            outputBuffer[index] = 0
        }

        let count = min(block.count, Self.blockLength)
        for index in 0..<count {
            outputBuffer[index] += block[index]
        }

        return outputBuffer.prefix(Self.blockShift).map { min(1, max(-1, $0)) }
    }

    private func makeTensorValue(values: [Float], shape: [NSNumber]) throws -> ORTValue {
        let byteCount = values.count * MemoryLayout<Float>.stride
        guard let tensorData = NSMutableData(length: byteCount) else {
            throw noiseReductionError("无法创建 DTLN 输入张量。", domain: "RetroRecorder.DTLN", code: 6)
        }

        values.withUnsafeBufferPointer { pointer in
            if let baseAddress = pointer.baseAddress {
                tensorData.mutableBytes.copyMemory(
                    from: UnsafeRawPointer(baseAddress),
                    byteCount: byteCount
                )
            }
        }

        return try ORTValue(
            tensorData: tensorData,
            elementType: .float,
            shape: shape
        )
    }

    private func floats(from value: ORTValue) throws -> [Float] {
        let tensorData = try value.tensorData()
        let count = tensorData.length / MemoryLayout<Float>.stride
        let pointer = tensorData.bytes.assumingMemoryBound(to: Float.self)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}

private struct DeepFilterSpectrumFrame {
    var real: [Float]
    var imaginary: [Float]

    static func zero(count: Int) -> DeepFilterSpectrumFrame {
        DeepFilterSpectrumFrame(
            real: Array(repeating: 0, count: count),
            imaginary: Array(repeating: 0, count: count)
        )
    }
}

private final class DeepFilterNetV3Processor: RealtimeNoiseReductionProcessor {
    let sampleRate: Double = 48_000
    let frameSize: Int = DeepFilterNetV3Processor.hopSize

    private static let fftSize = 960
    private static let hopSize = 480
    private static let positiveFrequencyBins = 481
    private static let erbBands = 32
    private static let dfBins = 96
    private static let dfOrder = 5
    private static let dfLookahead = 2
    private static let contextFrames = 5
    private static let normalizationAlpha: Float = 0.99
    private static let epsilon: Float = 1e-7
    private static let minimumGain: Float = 0.04
    private static let maximumGain: Float = 1.15
    private static let analysisWindow: [Float] = {
        (0..<fftSize).map { index in
            let phase = (2 * Double.pi * Double(index)) / Double(max(1, fftSize - 1))
            let hann = max(0, 0.5 - 0.5 * cos(phase))
            return Float(sqrt(hann))
        }
    }()
    private static let erbBandEdges: [Int] = {
        let nyquist = Double(48_000) / 2
        let maximumErbRate = erbRate(nyquist)
        var edges = [0]

        for band in 1..<erbBands {
            let rate = maximumErbRate * Double(band) / Double(erbBands)
            let frequency = inverseErbRate(rate)
            let proposedBin = Int(round(frequency / nyquist * Double(positiveFrequencyBins - 1)))
            let previousBin = edges.last ?? 0
            let nextBin = min(positiveFrequencyBins - 1, max(previousBin + 1, proposedBin))
            edges.append(nextBin)
        }

        edges.append(positiveFrequencyBins)
        return edges
    }()
    private static let erbBandForBin: [Int] = {
        var bands = Array(repeating: erbBands - 1, count: positiveFrequencyBins)

        for band in 0..<erbBands {
            let start = min(positiveFrequencyBins, erbBandEdges[band])
            let end = min(positiveFrequencyBins, erbBandEdges[band + 1])
            guard start < end else {
                continue
            }

            for bin in start..<end {
                bands[bin] = band
            }
        }

        return bands
    }()
    private static let zeroSpectrumFrame = DeepFilterSpectrumFrame.zero(count: positiveFrequencyBins)
    private static var cachedEnvironment: ORTEnv?

    private let encoderSession: ORTSession
    private let erbDecoderSession: ORTSession
    private let dfDecoderSession: ORTSession
    private let encoderInputNames: [String]
    private let encoderOutputNames: [String]
    private let erbDecoderInputNames: [String]
    private let erbDecoderOutputNames: [String]
    private let dfDecoderInputNames: [String]
    private let dfDecoderOutputNames: [String]
    private let fft: DTLNFFT

    private var inputBuffer = Array(repeating: Float(0), count: DeepFilterNetV3Processor.fftSize)
    private var overlapBuffer = Array(repeating: Float(0), count: DeepFilterNetV3Processor.fftSize)
    private var erbFeatureFrames: [[Float]] = []
    private var specFeatureFrames: [[Float]] = []
    private var spectrumHistory: [DeepFilterSpectrumFrame] = []
    private var erbNormState = Array(repeating: Float(1e-4), count: DeepFilterNetV3Processor.erbBands)
    private var specNormState = Array(repeating: Float(1e-4), count: DeepFilterNetV3Processor.dfBins)

    init() throws {
        guard let fft = DTLNFFT(blockLength: Self.fftSize) else {
            throw noiseReductionError("DeepFilterNet FFT 初始化失败。", domain: "RetroRecorder.DeepFilterNet", code: 1)
        }

        let environment = try Self.environment()
        let encoder = try Self.makeSession(resourceName: "enc", environment: environment)
        let erbDecoder = try Self.makeSession(resourceName: "erb_dec", environment: environment)
        let dfDecoder = try Self.makeSession(resourceName: "df_dec", environment: environment)

        encoderSession = encoder.session
        encoderInputNames = encoder.inputNames
        encoderOutputNames = encoder.outputNames
        erbDecoderSession = erbDecoder.session
        erbDecoderInputNames = erbDecoder.inputNames
        erbDecoderOutputNames = erbDecoder.outputNames
        dfDecoderSession = dfDecoder.session
        dfDecoderInputNames = dfDecoder.inputNames
        dfDecoderOutputNames = dfDecoder.outputNames
        self.fft = fft
    }

    func process(frame samples: ArraySlice<Float>) throws -> [Float] {
        guard samples.count == Self.hopSize else {
            return Array(samples)
        }

        shiftInputBuffer(with: samples)

        var windowedInput = Array(repeating: Float(0), count: Self.fftSize)
        for index in 0..<Self.fftSize {
            windowedInput[index] = inputBuffer[index] * Self.analysisWindow[index]
        }

        let spectrum = fft.forward(windowedInput)
        let positiveFrame = positiveSpectrumFrame(from: spectrum)
        let magnitudes = magnitudes(from: positiveFrame)
        let erbFrame = normalizedErbFeatures(from: magnitudes)
        let specFrame = normalizedSpecFeatures(from: positiveFrame, magnitudes: magnitudes)

        appendRollingFrame(erbFrame, to: &erbFeatureFrames, maxCount: Self.contextFrames)
        appendRollingFrame(specFrame, to: &specFeatureFrames, maxCount: Self.contextFrames)
        appendRollingSpectrum(positiveFrame)

        let frameCount = min(erbFeatureFrames.count, specFeatureFrames.count)
        let encoderOutputs = try runEncoder(frameCount: frameCount)
        let erbMask = try runErbDecoder(encoderOutputs: encoderOutputs, frameCount: frameCount)
        let dfOutput = try runDFDecoder(encoderOutputs: encoderOutputs, frameCount: frameCount)
        let enhancedPositiveSpectrum = enhancedSpectrum(
            mask: erbMask,
            coefficients: dfOutput.coefficients,
            alpha: dfOutput.alpha
        )
        let enhancedSpectrum = fullSpectrum(from: enhancedPositiveSpectrum)
        let enhancedBlock = fft.inverse(real: enhancedSpectrum.real, imaginary: enhancedSpectrum.imaginary)

        return overlapAndEmit(enhancedBlock)
    }

    private static func environment() throws -> ORTEnv {
        if let environment = cachedEnvironment {
            return environment
        }

        let environment = try ORTEnv(loggingLevel: .warning)
        cachedEnvironment = environment
        return environment
    }

    private static func makeSession(resourceName: String, environment: ORTEnv) throws -> (session: ORTSession, inputNames: [String], outputNames: [String]) {
        guard let modelPath = Bundle.main.path(forResource: resourceName, ofType: "onnx") else {
            throw noiseReductionError("找不到 DeepFilterNet 模型 \(resourceName).onnx。", domain: "RetroRecorder.DeepFilterNet", code: 2)
        }

        let options = try ORTSessionOptions()
        try? options.setIntraOpNumThreads(1)
        try? options.setGraphOptimizationLevel(.all)

        let session = try ORTSession(env: environment, modelPath: modelPath, sessionOptions: options)
        let inputNames = try session.inputNames()
        let outputNames = try session.outputNames()

        guard inputNames.isEmpty == false, outputNames.isEmpty == false else {
            throw noiseReductionError("DeepFilterNet 模型输入或输出不完整。", domain: "RetroRecorder.DeepFilterNet", code: 3)
        }

        return (session, inputNames, outputNames)
    }

    private static func erbRate(_ frequency: Double) -> Double {
        21.4 * log10(1 + 0.00437 * frequency)
    }

    private static func inverseErbRate(_ rate: Double) -> Double {
        (pow(10, rate / 21.4) - 1) / 0.00437
    }

    private func shiftInputBuffer(with samples: ArraySlice<Float>) {
        for index in 0..<(Self.fftSize - Self.hopSize) {
            inputBuffer[index] = inputBuffer[index + Self.hopSize]
        }

        var writeIndex = Self.fftSize - Self.hopSize
        for sample in samples {
            inputBuffer[writeIndex] = sample
            writeIndex += 1
        }
    }

    private func positiveSpectrumFrame(from spectrum: (real: [Float], imaginary: [Float])) -> DeepFilterSpectrumFrame {
        var real = Array(repeating: Float(0), count: Self.positiveFrequencyBins)
        var imaginary = Array(repeating: Float(0), count: Self.positiveFrequencyBins)
        let copyCount = min(Self.positiveFrequencyBins, min(spectrum.real.count, spectrum.imaginary.count))

        for bin in 0..<copyCount {
            real[bin] = spectrum.real[bin]
            imaginary[bin] = spectrum.imaginary[bin]
        }

        imaginary[0] = 0
        imaginary[Self.positiveFrequencyBins - 1] = 0
        return DeepFilterSpectrumFrame(real: real, imaginary: imaginary)
    }

    private func magnitudes(from spectrum: DeepFilterSpectrumFrame) -> [Float] {
        (0..<Self.positiveFrequencyBins).map { bin in
            hypotf(spectrum.real[bin], spectrum.imaginary[bin])
        }
    }

    private func normalizedErbFeatures(from magnitudes: [Float]) -> [Float] {
        var features = Array(repeating: Float(0), count: Self.erbBands)

        for band in 0..<Self.erbBands {
            let start = Self.erbBandEdges[band]
            let end = Self.erbBandEdges[band + 1]
            var energy = Float(0)

            if start < end {
                for bin in start..<end {
                    let magnitude = magnitudes[min(bin, magnitudes.count - 1)]
                    energy += magnitude * magnitude
                }

                energy = sqrtf(energy / Float(end - start))
            }

            let previous = max(Self.epsilon, erbNormState[band])
            let normalized = log10f((energy + Self.epsilon) / (previous + Self.epsilon))
            features[band] = Self.clamp(normalized * 2, minValue: -3, maxValue: 3)
            erbNormState[band] = Self.normalizationAlpha * previous + (1 - Self.normalizationAlpha) * energy
        }

        return features
    }

    private func normalizedSpecFeatures(from spectrum: DeepFilterSpectrumFrame, magnitudes: [Float]) -> [Float] {
        var features = Array(repeating: Float(0), count: Self.dfBins * 2)

        for bin in 0..<Self.dfBins {
            let magnitude = bin < magnitudes.count ? magnitudes[bin] : 0
            let previous = max(Self.epsilon, specNormState[bin])
            let scale = max(Self.epsilon, previous)

            features[bin] = Self.clamp(spectrum.real[bin] / scale, minValue: -5, maxValue: 5)
            features[Self.dfBins + bin] = Self.clamp(spectrum.imaginary[bin] / scale, minValue: -5, maxValue: 5)
            specNormState[bin] = Self.normalizationAlpha * previous + (1 - Self.normalizationAlpha) * magnitude
        }

        return features
    }

    private func appendRollingFrame(_ frame: [Float], to frames: inout [[Float]], maxCount: Int) {
        frames.append(frame)

        if frames.count > maxCount {
            frames.removeFirst(frames.count - maxCount)
        }
    }

    private func appendRollingSpectrum(_ spectrum: DeepFilterSpectrumFrame) {
        spectrumHistory.append(spectrum)

        if spectrumHistory.count > Self.dfOrder {
            spectrumHistory.removeFirst(spectrumHistory.count - Self.dfOrder)
        }
    }

    private func runEncoder(frameCount: Int) throws -> EncoderOutputs {
        guard frameCount > 0 else {
            throw noiseReductionError("DeepFilterNet 特征为空。", domain: "RetroRecorder.DeepFilterNet", code: 4)
        }

        let featureTensors = makeFeatureTensorValues(frameCount: frameCount)
        let inputs = [
            "feat_erb": try makeTensorValue(
                values: featureTensors.erb,
                shape: [1, 1, frameCount, Self.erbBands].map { NSNumber(value: $0) }
            ),
            "feat_spec": try makeTensorValue(
                values: featureTensors.spec,
                shape: [1, 2, frameCount, Self.dfBins].map { NSNumber(value: $0) }
            )
        ]
        let outputs = try encoderSession.run(
            withInputs: try matchedInputs(inputs, inputNames: encoderInputNames),
            outputNames: Set(encoderOutputNames),
            runOptions: nil
        )

        guard let e0 = output(named: "e0", fallback: 0, outputs: outputs, outputNames: encoderOutputNames),
              let e1 = output(named: "e1", fallback: 1, outputs: outputs, outputNames: encoderOutputNames),
              let e2 = output(named: "e2", fallback: 2, outputs: outputs, outputNames: encoderOutputNames),
              let e3 = output(named: "e3", fallback: 3, outputs: outputs, outputNames: encoderOutputNames),
              let emb = output(named: "emb", fallback: 4, outputs: outputs, outputNames: encoderOutputNames),
              let c0 = output(named: "c0", fallback: 5, outputs: outputs, outputNames: encoderOutputNames) else {
            throw noiseReductionError("DeepFilterNet Encoder 输出无效。", domain: "RetroRecorder.DeepFilterNet", code: 5)
        }

        return EncoderOutputs(e0: e0, e1: e1, e2: e2, e3: e3, emb: emb, c0: c0)
    }

    private func runErbDecoder(encoderOutputs: EncoderOutputs, frameCount: Int) throws -> [Float] {
        let requestedInputs = [
            "emb": encoderOutputs.emb,
            "e3": encoderOutputs.e3,
            "e2": encoderOutputs.e2,
            "e1": encoderOutputs.e1,
            "e0": encoderOutputs.e0
        ]
        let outputs = try erbDecoderSession.run(
            withInputs: try matchedInputs(requestedInputs, inputNames: erbDecoderInputNames),
            outputNames: Set(erbDecoderOutputNames),
            runOptions: nil
        )

        guard let maskOutput = output(named: "m", fallback: 0, outputs: outputs, outputNames: erbDecoderOutputNames) else {
            throw noiseReductionError("DeepFilterNet ERB Decoder 输出无效。", domain: "RetroRecorder.DeepFilterNet", code: 6)
        }

        return lastFrameValues(try floats(from: maskOutput), frameCount: frameCount, width: Self.erbBands)
    }

    private func runDFDecoder(encoderOutputs: EncoderOutputs, frameCount: Int) throws -> (coefficients: [Float], alpha: Float) {
        let requestedInputs = [
            "emb": encoderOutputs.emb,
            "c0": encoderOutputs.c0
        ]
        let outputs = try dfDecoderSession.run(
            withInputs: try matchedInputs(requestedInputs, inputNames: dfDecoderInputNames),
            outputNames: Set(dfDecoderOutputNames),
            runOptions: nil
        )

        guard dfDecoderOutputNames.count >= 2,
              let coefficientsOutput = outputs[dfDecoderOutputNames[0]],
              let alphaOutput = outputs[dfDecoderOutputNames[1]] else {
            throw noiseReductionError("DeepFilterNet DF Decoder 输出无效。", domain: "RetroRecorder.DeepFilterNet", code: 7)
        }

        let coefficients = lastFrameValues(
            try floats(from: coefficientsOutput),
            frameCount: frameCount,
            width: Self.dfBins * Self.dfOrder * 2
        )
        let alphaValues = lastFrameValues(
            try floats(from: alphaOutput),
            frameCount: frameCount,
            width: 1
        )
        let alpha = Self.clamp(alphaValues.first ?? 0, minValue: 0, maxValue: 1)

        return (coefficients, alpha)
    }

    private func makeFeatureTensorValues(frameCount: Int) -> (erb: [Float], spec: [Float]) {
        let erbFrames = Array(erbFeatureFrames.suffix(frameCount))
        let specFrames = Array(specFeatureFrames.suffix(frameCount))
        let erb = erbFrames.flatMap { $0 }
        var spec = Array(repeating: Float(0), count: 2 * frameCount * Self.dfBins)

        for frameIndex in 0..<frameCount {
            let frame = specFrames[frameIndex]

            for bin in 0..<Self.dfBins {
                spec[frameIndex * Self.dfBins + bin] = frame[bin]
                spec[frameCount * Self.dfBins + frameIndex * Self.dfBins + bin] = frame[Self.dfBins + bin]
            }
        }

        return (erb, spec)
    }

    private func matchedInputs(_ requestedInputs: [String: ORTValue], inputNames: [String]) throws -> [String: ORTValue] {
        var inputs: [String: ORTValue] = [:]

        for name in inputNames {
            guard let value = requestedInputs[name] else {
                throw noiseReductionError("DeepFilterNet 模型缺少输入 \(name)。", domain: "RetroRecorder.DeepFilterNet", code: 8)
            }

            inputs[name] = value
        }

        return inputs
    }

    private func output(
        named name: String,
        fallback index: Int,
        outputs: [String: ORTValue],
        outputNames: [String]
    ) -> ORTValue? {
        if let value = outputs[name] {
            return value
        }

        guard outputNames.indices.contains(index) else {
            return nil
        }

        return outputs[outputNames[index]]
    }

    private func lastFrameValues(_ values: [Float], frameCount: Int, width: Int) -> [Float] {
        guard width > 0 else {
            return []
        }

        let expectedCount = frameCount * width

        if values.count >= expectedCount {
            let start = (max(1, frameCount) - 1) * width
            let end = min(values.count, start + width)
            return Array(values[start..<end])
        }

        if values.count >= width {
            return Array(values.suffix(width))
        }

        var padded = values
        padded.append(contentsOf: Array(repeating: 0, count: width - values.count))
        return padded
    }

    private func enhancedSpectrum(mask: [Float], coefficients: [Float], alpha: Float) -> DeepFilterSpectrumFrame {
        let history = paddedSpectrumHistory()
        let baseIndex = max(0, min(history.count - 1, Self.dfOrder - Self.dfLookahead - 1))
        let base = history[baseIndex]
        var enhanced = DeepFilterSpectrumFrame(real: base.real, imaginary: base.imaginary)

        for bin in 0..<Self.positiveFrequencyBins {
            let gain = maskGain(mask, forBin: bin)
            enhanced.real[bin] *= gain
            enhanced.imaginary[bin] *= gain
        }

        guard coefficients.count >= Self.dfBins * Self.dfOrder * 2 else {
            return enhanced
        }

        let blend = Self.clamp(alpha, minValue: 0, maxValue: 1)

        for bin in 0..<Self.dfBins {
            var filteredReal = Float(0)
            var filteredImaginary = Float(0)

            for order in 0..<Self.dfOrder {
                let source = history[order]
                let coefficientIndex = bin * Self.dfOrder * 2 + order * 2
                let coefficientReal = coefficients[coefficientIndex]
                let coefficientImaginary = coefficients[coefficientIndex + 1]
                let sourceReal = source.real[bin]
                let sourceImaginary = source.imaginary[bin]

                filteredReal += sourceReal * coefficientReal - sourceImaginary * coefficientImaginary
                filteredImaginary += sourceImaginary * coefficientReal + sourceReal * coefficientImaginary
            }

            enhanced.real[bin] = filteredReal * blend + enhanced.real[bin] * (1 - blend)
            enhanced.imaginary[bin] = filteredImaginary * blend + enhanced.imaginary[bin] * (1 - blend)
        }

        enhanced.imaginary[0] = 0
        enhanced.imaginary[Self.positiveFrequencyBins - 1] = 0
        return enhanced
    }

    private func paddedSpectrumHistory() -> [DeepFilterSpectrumFrame] {
        let recentHistory = Array(spectrumHistory.suffix(Self.dfOrder))

        guard recentHistory.count < Self.dfOrder else {
            return recentHistory
        }

        return Array(repeating: Self.zeroSpectrumFrame, count: Self.dfOrder - recentHistory.count) + recentHistory
    }

    private func maskGain(_ mask: [Float], forBin bin: Int) -> Float {
        guard mask.isEmpty == false else {
            return 1
        }

        let band = Self.erbBandForBin[min(bin, Self.erbBandForBin.count - 1)]
        let rawGain = band < mask.count ? mask[band] : mask.last ?? 1
        return Self.clamp(rawGain, minValue: Self.minimumGain, maxValue: Self.maximumGain)
    }

    private func fullSpectrum(from positiveSpectrum: DeepFilterSpectrumFrame) -> (real: [Float], imaginary: [Float]) {
        var real = Array(repeating: Float(0), count: Self.fftSize)
        var imaginary = Array(repeating: Float(0), count: Self.fftSize)

        for bin in 0..<Self.positiveFrequencyBins {
            real[bin] = positiveSpectrum.real[bin]
            imaginary[bin] = positiveSpectrum.imaginary[bin]
        }

        imaginary[0] = 0
        imaginary[Self.positiveFrequencyBins - 1] = 0

        if Self.positiveFrequencyBins > 2 {
            for bin in 1..<(Self.positiveFrequencyBins - 1) {
                let mirrorBin = Self.fftSize - bin
                real[mirrorBin] = real[bin]
                imaginary[mirrorBin] = -imaginary[bin]
            }
        }

        return (real, imaginary)
    }

    private func overlapAndEmit(_ block: [Float]) -> [Float] {
        let count = min(block.count, Self.fftSize)

        for index in 0..<count {
            overlapBuffer[index] += block[index] * Self.analysisWindow[index]
        }

        let emitted = overlapBuffer.prefix(Self.hopSize).map {
            Self.clamp($0, minValue: -1, maxValue: 1)
        }

        for index in 0..<(Self.fftSize - Self.hopSize) {
            overlapBuffer[index] = overlapBuffer[index + Self.hopSize]
        }

        for index in (Self.fftSize - Self.hopSize)..<Self.fftSize {
            overlapBuffer[index] = 0
        }

        return emitted
    }

    private func makeTensorValue(values: [Float], shape: [NSNumber]) throws -> ORTValue {
        let byteCount = values.count * MemoryLayout<Float>.stride
        guard let tensorData = NSMutableData(length: byteCount) else {
            throw noiseReductionError("无法创建 DeepFilterNet 输入张量。", domain: "RetroRecorder.DeepFilterNet", code: 9)
        }

        values.withUnsafeBufferPointer { pointer in
            if let baseAddress = pointer.baseAddress {
                tensorData.mutableBytes.copyMemory(
                    from: UnsafeRawPointer(baseAddress),
                    byteCount: byteCount
                )
            }
        }

        return try ORTValue(
            tensorData: tensorData,
            elementType: .float,
            shape: shape
        )
    }

    private func floats(from value: ORTValue) throws -> [Float] {
        let tensorData = try value.tensorData()
        let count = tensorData.length / MemoryLayout<Float>.stride
        let pointer = tensorData.bytes.assumingMemoryBound(to: Float.self)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }

    private static func clamp(_ value: Float, minValue: Float, maxValue: Float) -> Float {
        min(maxValue, max(minValue, value))
    }

    private struct EncoderOutputs {
        let e0: ORTValue
        let e1: ORTValue
        let e2: ORTValue
        let e3: ORTValue
        let emb: ORTValue
        let c0: ORTValue
    }
}

private final class DTLNFFT {
    private let blockLength: Int
    private let forwardSetup: vDSP_DFT_Setup
    private let inverseSetup: vDSP_DFT_Setup

    init?(blockLength: Int) {
        guard let forwardSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(blockLength),
            .FORWARD
        ),
        let inverseSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(blockLength),
            .INVERSE
        ) else {
            return nil
        }

        self.blockLength = blockLength
        self.forwardSetup = forwardSetup
        self.inverseSetup = inverseSetup
    }

    deinit {
        vDSP_DFT_DestroySetup(forwardSetup)
        vDSP_DFT_DestroySetup(inverseSetup)
    }

    func forward(_ input: [Float]) -> (real: [Float], imaginary: [Float]) {
        var realInput = input
        var imaginaryInput = Array(repeating: Float(0), count: blockLength)
        var realOutput = Array(repeating: Float(0), count: blockLength)
        var imaginaryOutput = Array(repeating: Float(0), count: blockLength)

        vDSP_DFT_Execute(
            forwardSetup,
            &realInput,
            &imaginaryInput,
            &realOutput,
            &imaginaryOutput
        )

        return (realOutput, imaginaryOutput)
    }

    func inverse(real: [Float], imaginary: [Float]) -> [Float] {
        var realInput = real
        var imaginaryInput = imaginary
        var realOutput = Array(repeating: Float(0), count: blockLength)
        var imaginaryOutput = Array(repeating: Float(0), count: blockLength)

        vDSP_DFT_Execute(
            inverseSetup,
            &realInput,
            &imaginaryInput,
            &realOutput,
            &imaginaryOutput
        )

        var scale = Float(1) / Float(blockLength)
        vDSP_vsmul(realOutput, 1, &scale, &realOutput, 1, vDSP_Length(blockLength))
        return realOutput
    }
}

private final class DenoisedAudioRecorder {
    private static let visualizationBarCount = 56
    private static let frequencyBarCount = 48
    private static let visualizationFFTSize = 512
    private static let shadertoyAudioSampleCount = 512
    private static let shadertoyFFTSize = 1_024

    private let engine = AVAudioEngine()
    private let outputFile: AVAudioFile
    private let processingFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let processor: RealtimeNoiseReductionProcessor
    private let frameSize: Int
    private let visualizationFFT: DTLNFFT?
    private let shadertoyFFT: DTLNFFT?
    private let echoCancellationEnabled: Bool
    private let speechBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    private let meterHandler: (Double, Double, TimeInterval) -> Void
    private let visualizationHandler: ([Double], [Double], [Double], [Double]) -> Void
    private let failureHandler: (Error) -> Void

    private var inputConverter: AVAudioConverter?
    private var outputConverter: AVAudioConverter?
    private var pendingSamples: [Float] = []
    private var writtenFrameCount: AVAudioFramePosition = 0
    private var paused = false
    private var hasTap = false

    init(
        url: URL,
        mode: NoiseReductionMode,
        audioConfiguration: RecordingAudioConfiguration,
        echoCancellationEnabled: Bool,
        speechBufferHandler: ((AVAudioPCMBuffer) -> Void)?,
        meterHandler: @escaping (Double, Double, TimeInterval) -> Void,
        visualizationHandler: @escaping ([Double], [Double], [Double], [Double]) -> Void,
        failureHandler: @escaping (Error) -> Void
    ) throws {
        let processor: RealtimeNoiseReductionProcessor

        switch mode {
        case .off:
            processor = PassthroughAudioProcessor()
        case .rnnoise:
            processor = try RNNoiseRealtimeProcessor()
        case .dtln:
            processor = try DTLNNoiseProcessor()
        case .deepFilterNetV3:
            processor = try DeepFilterNetV3Processor()
        }

        guard let processingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: processor.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(
                domain: "RetroRecorder.NoiseReduction",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "无法创建降噪录音格式。"]
            )
        }

        let outputFile = try AVAudioFile(
            forWriting: url,
            settings: audioConfiguration.fileSettings(),
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let outputFormat = outputFile.processingFormat

        self.processingFormat = processingFormat
        self.outputFormat = outputFormat
        self.outputFile = outputFile
        self.processor = processor
        self.frameSize = processor.frameSize
        self.visualizationFFT = DTLNFFT(blockLength: Self.visualizationFFTSize)
        self.shadertoyFFT = DTLNFFT(blockLength: Self.shadertoyFFTSize)
        self.echoCancellationEnabled = echoCancellationEnabled
        self.speechBufferHandler = speechBufferHandler
        self.meterHandler = meterHandler
        self.visualizationHandler = visualizationHandler
        self.failureHandler = failureHandler
        self.pendingSamples.reserveCapacity(processor.frameSize * 4)

        if abs(processingFormat.sampleRate - outputFormat.sampleRate) > 0.5 {
            outputConverter = AVAudioConverter(from: processingFormat, to: outputFormat)
        }
    }

    deinit {
        stop()
    }

    func start() throws {
        let inputNode = engine.inputNode

        if echoCancellationEnabled {
            try inputNode.setVoiceProcessingEnabled(true)
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.channelCount > 0 else {
            throw NSError(
                domain: "RetroRecorder.NoiseReduction",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "没有可用的麦克风输入格式。"]
            )
        }

        inputConverter = AVAudioConverter(from: inputFormat, to: processingFormat)

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { [weak self] buffer, _ in
            self?.handle(buffer)
        }
        hasTap = true

        engine.prepare()
        try engine.start()
    }

    func setPaused(_ paused: Bool) {
        self.paused = paused
    }

    func stop() {
        if hasTap {
            engine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }

        if engine.isRunning {
            engine.stop()
        }

        if echoCancellationEnabled {
            try? engine.inputNode.setVoiceProcessingEnabled(false)
        }
    }

    private func handle(_ buffer: AVAudioPCMBuffer) {
        guard !paused else {
            meterHandler(0, 0, currentElapsed)
            visualizationHandler(
                Self.emptyVisualizationLevels(),
                Self.emptyFrequencyLevels(),
                Self.emptyShadertoySpectrum(),
                Self.emptyShadertoyWaveform()
            )
            return
        }

        speechBufferHandler?(buffer)

        let meters = meterLevels(from: buffer)

        guard let convertedBuffer = convertToProcessingFormat(buffer),
              let channel = convertedBuffer.floatChannelData?[0] else {
            meterHandler(meters.left, meters.right, currentElapsed)
            visualizationHandler(
                Self.emptyVisualizationLevels(),
                Self.emptyFrequencyLevels(),
                Self.emptyShadertoySpectrum(),
                Self.emptyShadertoyWaveform()
            )
            return
        }

        let sampleCount = Int(convertedBuffer.frameLength)
        guard sampleCount > 0 else {
            meterHandler(meters.left, meters.right, currentElapsed)
            visualizationHandler(
                Self.emptyVisualizationLevels(),
                Self.emptyFrequencyLevels(),
                Self.emptyShadertoySpectrum(),
                Self.emptyShadertoyWaveform()
            )
            return
        }

        visualizationHandler(
            Self.visualizationEnvelope(from: channel, sampleCount: sampleCount),
            Self.frequencyHistogram(from: channel, sampleCount: sampleCount, fft: visualizationFFT),
            Self.shadertoySpectrum(from: channel, sampleCount: sampleCount, fft: shadertoyFFT),
            Self.shadertoyWaveform(from: channel, sampleCount: sampleCount)
        )

        for index in 0..<sampleCount {
            pendingSamples.append(channel[index])
        }

        var processedSamples: [Float] = []
        processedSamples.reserveCapacity(sampleCount)

        while pendingSamples.count >= frameSize {
            do {
                processedSamples.append(contentsOf: try processor.process(frame: pendingSamples.prefix(frameSize)))
                pendingSamples.removeFirst(frameSize)
            } catch {
                stop()
                failureHandler(error)
                return
            }
        }

        if processedSamples.isEmpty == false {
            write(samples: processedSamples)
        }

        meterHandler(meters.left, meters.right, currentElapsed)
    }

    private func convertToProcessingFormat(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let inputConverter else {
            return nil
        }

        let ratio = processingFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 32

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: max(1, capacity)) else {
            return nil
        }

        var didProvideInput = false
        var conversionError: NSError?
        let status = inputConverter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }

            didProvideInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, conversionError == nil, convertedBuffer.frameLength > 0 else {
            return nil
        }

        return convertedBuffer
    }

    private func write(samples: [Float]) {
        let sourceFormat = outputConverter == nil ? outputFormat : processingFormat

        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else {
            return
        }

        sourceBuffer.frameLength = AVAudioFrameCount(samples.count)

        if let outputChannel = sourceBuffer.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { pointer in
                if let baseAddress = pointer.baseAddress {
                    outputChannel.update(from: baseAddress, count: pointer.count)
                }
            }
        }

        guard let outputBuffer = convertToOutputFormat(sourceBuffer) else {
            return
        }

        do {
            try outputFile.write(from: outputBuffer)
            writtenFrameCount += AVAudioFramePosition(outputBuffer.frameLength)
        } catch {
            stop()
        }
    }

    private func convertToOutputFormat(_ sourceBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let outputConverter else {
            return sourceBuffer
        }

        let ratio = outputFormat.sampleRate / sourceBuffer.format.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(sourceBuffer.frameLength) * ratio)) + 32

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: max(1, capacity)) else {
            return nil
        }

        var didProvideInput = false
        var conversionError: NSError?
        let status = outputConverter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }

            didProvideInput = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        guard status != .error, conversionError == nil, convertedBuffer.frameLength > 0 else {
            return nil
        }

        return convertedBuffer
    }

    private func meterLevels(from buffer: AVAudioPCMBuffer) -> (left: Double, right: Double) {
        guard let channelData = buffer.floatChannelData else {
            return (0, 0)
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return (0, 0)
        }

        let channelCount = Int(buffer.format.channelCount)
        let left = rmsLevel(channelData[0], frameLength: frameLength)
        let right = channelCount > 1 ? rmsLevel(channelData[1], frameLength: frameLength) : left
        return (left, right)
    }

    private func rmsLevel(_ samples: UnsafePointer<Float>, frameLength: Int) -> Double {
        var sum: Float = 0

        for index in 0..<frameLength {
            let sample = samples[index]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        return min(1, Double(rms) * 3.4)
    }

    private static func emptyVisualizationLevels() -> [Double] {
        Array(repeating: 0, count: visualizationBarCount)
    }

    private static func emptyFrequencyLevels() -> [Double] {
        Array(repeating: 0, count: frequencyBarCount)
    }

    private static func emptyShadertoySpectrum() -> [Double] {
        Array(repeating: 0, count: shadertoyAudioSampleCount)
    }

    private static func emptyShadertoyWaveform() -> [Double] {
        Array(repeating: 0, count: shadertoyAudioSampleCount)
    }

    private static func shadertoyWaveform(
        from samples: UnsafePointer<Float>,
        sampleCount: Int
    ) -> [Double] {
        guard sampleCount > 0 else {
            return emptyShadertoyWaveform()
        }

        var waveform = emptyShadertoyWaveform()
        let copyCount = min(sampleCount, shadertoyAudioSampleCount)
        let sourceStart = max(0, sampleCount - copyCount)
        let destinationStart = shadertoyAudioSampleCount - copyCount

        for index in 0..<copyCount {
            waveform[destinationStart + index] = Double(min(1, max(-1, samples[sourceStart + index])))
        }

        return waveform
    }

    private static func shadertoySpectrum(
        from samples: UnsafePointer<Float>,
        sampleCount: Int,
        fft: DTLNFFT?
    ) -> [Double] {
        guard let fft, sampleCount > 0 else {
            return emptyShadertoySpectrum()
        }

        var input = Array(repeating: Float(0), count: shadertoyFFTSize)
        let copyCount = min(sampleCount, shadertoyFFTSize)
        let sourceStart = max(0, sampleCount - copyCount)
        let destinationStart = shadertoyFFTSize - copyCount

        for index in 0..<copyCount {
            let destinationIndex = destinationStart + index
            let window = Float(
                0.5 - 0.5 * cos(
                    (2 * Double.pi * Double(destinationIndex)) / Double(max(1, shadertoyFFTSize - 1))
                )
            )
            input[destinationIndex] = samples[sourceStart + index] * window
        }

        let transformed = fft.forward(input)
        let amplitudeScale = 4.0 / Double(shadertoyFFTSize)
        var spectrum = emptyShadertoySpectrum()

        for bin in 0..<shadertoyAudioSampleCount {
            let real = Double(transformed.real[bin])
            let imaginary = Double(transformed.imaginary[bin])
            let amplitude = max(0.000_01, sqrt(real * real + imaginary * imaginary) * amplitudeScale)
            let decibels = 20 * log10(amplitude)
            let normalized = min(1, max(0, (decibels + 88) / 68))
            spectrum[bin] = pow(normalized, 1.08)
        }

        return spectrum
    }

    private static func visualizationEnvelope(from samples: UnsafePointer<Float>, sampleCount: Int) -> [Double] {
        guard sampleCount > 0 else {
            return emptyVisualizationLevels()
        }

        var levels = Array(repeating: 0.0, count: visualizationBarCount)

        for bar in 0..<visualizationBarCount {
            let start = bar * sampleCount / visualizationBarCount
            let end = min(sampleCount, max(start + 1, (bar + 1) * sampleCount / visualizationBarCount))
            let frameLength = max(1, end - start)
            var positiveSum: Float = 0
            var absoluteSum: Float = 0

            for index in start..<end {
                let sample = samples[index]
                positiveSum += max(sample, 0)
                absoluteSum += abs(sample)
            }

            let meanPositive = positiveSum / Float(frameLength)
            let meanAbsolute = absoluteSum / Float(frameLength)
            let pooled = Double(meanPositive + meanAbsolute * Float(0.35))
            let boosted = min(6, pooled * 10)
            let compressed = 1.9 * (sigmoid(2.5 * boosted) - 0.5)
            let smoothWindow = 0.42 + 0.58 * sin(Double.pi * Double(bar + 1) / Double(visualizationBarCount + 1))

            levels[bar] = min(1, max(0, compressed * smoothWindow))
        }

        return levels
    }

    private static func sigmoid(_ value: Double) -> Double {
        1 / (1 + exp(-value))
    }

    private static func frequencyHistogram(
        from samples: UnsafePointer<Float>,
        sampleCount: Int,
        fft: DTLNFFT?
    ) -> [Double] {
        guard let fft, sampleCount > 0 else {
            return emptyFrequencyLevels()
        }

        var input = Array(repeating: Float(0), count: visualizationFFTSize)
        let copyCount = min(sampleCount, visualizationFFTSize)
        let start = max(0, sampleCount - copyCount)
        var squaredAmplitude = 0.0

        for index in 0..<copyCount {
            let window = Float(0.5 - 0.5 * cos((2 * Double.pi * Double(index)) / Double(max(1, visualizationFFTSize - 1))))
            let sample = samples[start + index]
            input[index] = sample * window
            squaredAmplitude += Double(sample * sample)
        }

        let rms = sqrt(squaredAmplitude / Double(max(1, copyCount)))
        let loudnessDB = 20 * log10(max(rms, 0.000_001))
        let loudness = min(1, max(0, (loudnessDB + 58) / 46))
        let amplitudeResponse = pow(loudness, 0.58)

        let spectrum = fft.forward(input)
        let usableBinCount = visualizationFFTSize / 2
        var magnitudes = Array(repeating: 0.0, count: usableBinCount)

        for bin in 1..<usableBinCount {
            let real = Double(spectrum.real[bin])
            let imaginary = Double(spectrum.imaginary[bin])
            magnitudes[bin] = sqrt(real * real + imaginary * imaginary)
        }

        guard let peak = magnitudes.max(), peak > 0.0008 else {
            return emptyFrequencyLevels()
        }

        var levels = Array(repeating: 0.0, count: frequencyBarCount)
        let maxBin = max(2, usableBinCount - 1)

        for band in 0..<frequencyBarCount {
            let lowerProgress = pow(Double(band) / Double(frequencyBarCount), 1.72)
            let upperProgress = pow(Double(band + 1) / Double(frequencyBarCount), 1.72)
            let startBin = max(1, min(maxBin - 1, Int(lowerProgress * Double(maxBin))))
            let endBin = max(startBin + 1, min(maxBin, Int(upperProgress * Double(maxBin)) + 1))
            let slice = magnitudes[startBin..<endBin]
            let average = slice.reduce(0, +) / Double(slice.count)
            let relative = min(1, max(0, average / peak))
            let highBandLift = 0.72 + 0.28 * Double(band) / Double(max(1, frequencyBarCount - 1))
            let shaped = pow(relative, 0.38) * highBandLift

            levels[band] = min(1, max(0, shaped * amplitudeResponse))
        }

        return levels
    }

    private var currentElapsed: TimeInterval {
        Double(writtenFrameCount) / outputFormat.sampleRate
    }
}

private func noiseReductionError(_ message: String, domain: String = "RetroRecorder.NoiseReduction", code: Int = 1) -> NSError {
    NSError(
        domain: domain,
        code: code,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}
