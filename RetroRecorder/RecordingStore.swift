import AVFoundation
import Foundation

struct RecordingLocationMetadata: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var horizontalAccuracy: Double?
    var timestamp: Date?
    var address: String?
}

struct RecordingMetadata: Codable, Equatable {
    var languageIdentifier: String?
    var title: String?
    var tagTimes: [TimeInterval]?
    var recordIdentifier: String? = nil
    var modifiedAt: Date? = nil
    var recordedAt: Date? = nil
    var location: RecordingLocationMetadata? = nil
    var fileFormat: String? = nil
    var sampleRate: Double? = nil
    var bitDepth: Int? = nil
    var channelCount: Int? = nil
    var inputName: String? = nil
    var inputUID: String? = nil
    var inputPortType: String? = nil
    var noiseReductionMode: String? = nil
    var echoCancellationMode: String? = nil
    var encoding: String? = nil
}

enum RecordingStore {
    static var directory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
    }

    static func makeRecordingURL(fileExtension: String = "m4a") throws -> URL {
        try ensureDirectory()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let cleanExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let filename = "Recording-\(formatter.string(from: Date())).\(cleanExtension)"

        return directory.appendingPathComponent(filename)
    }

    static func defaultRecordingTitle(locationName: String?, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: date)

        let cleanLocation = locationName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        guard let cleanLocation, cleanLocation.isEmpty == false else {
            return timestamp
        }

        return "\(cleanLocation)-\(timestamp)"
    }

    static func saveRecordingMetadata(_ metadata: RecordingMetadata, for recordingURL: URL) throws {
        var metadata = metadata
        metadata.modifiedAt = metadata.modifiedAt ?? Date()
        try saveMetadata(metadata, for: recordingURL)
        CloudSyncStore.shared.sync(recordingURL: recordingURL)
    }

    static func makeRecordingURL(filename: String, fileExtension: String = "m4a") throws -> URL {
        try ensureDirectory()

        let cleanExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let baseName = sanitizedFileBaseName(filename)
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension(cleanExtension)

        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName)-\(index)")
                .appendingPathExtension(cleanExtension)
            index += 1
        }

        return candidate
    }

    static func loadRecordings() -> [RecordingItem] {
        try? ensureDirectory()

        let localRecordings = loadLocalRecordings()
        CloudSyncStore.shared.reconcile(localRecordings: localRecordings)
        CloudSyncStore.shared.restoreCloudRecordings()
        return loadLocalRecordings()
    }

    static func metadata(for recordingURL: URL) -> RecordingMetadata {
        readMetadata(for: recordingURL)
    }

    static func writeMetadata(_ metadata: RecordingMetadata, for recordingURL: URL) throws {
        try saveMetadata(metadata, for: recordingURL)
    }

    static func writeTranscript(_ transcript: String, for recordingURL: URL) throws {
        try transcript.write(to: transcriptURL(for: recordingURL), atomically: true, encoding: .utf8)
    }

    static func deleteCloudRecord(for recording: RecordingItem) {
        CloudSyncStore.shared.markDeleted(recording: recording)
    }

    private static func loadLocalRecordings() -> [RecordingItem] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return files
            .filter { supportedAudioExtensions.contains($0.pathExtension.lowercased()) }
            .map { url in
                let values = try? url.resourceValues(forKeys: [.creationDateKey])
                let metadata = readMetadata(for: url)
                return RecordingItem(
                    url: url,
                    createdAt: metadata.recordedAt ?? values?.creationDate ?? Date(),
                    duration: duration(for: url),
                    languageIdentifier: metadata.languageIdentifier,
                    transcript: readTranscript(for: url),
                    customTitle: metadata.title,
                    tagTimes: normalizedTagTimes(metadata.tagTimes ?? []),
                    metadata: metadata
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func loadRecording(at url: URL) -> RecordingItem? {
        guard supportedAudioExtensions.contains(url.pathExtension.lowercased()),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let values = try? url.resourceValues(forKeys: [.creationDateKey])
        let metadata = readMetadata(for: url)
        return RecordingItem(
            url: url,
            createdAt: metadata.recordedAt ?? values?.creationDate ?? Date(),
            duration: duration(for: url),
            languageIdentifier: metadata.languageIdentifier,
            transcript: readTranscript(for: url),
            customTitle: metadata.title,
            tagTimes: normalizedTagTimes(metadata.tagTimes ?? []),
            metadata: metadata
        )
    }

    private static let supportedAudioExtensions: Set<String> = ["m4a", "caf", "wav", "aif", "aiff"]

    static func saveTranscript(_ transcript: String, languageIdentifier: String, for recordingURL: URL) throws {
        let cleanTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        try cleanTranscript.write(to: transcriptURL(for: recordingURL), atomically: true, encoding: .utf8)
        try saveLanguageIdentifier(languageIdentifier, for: recordingURL)
    }

    static func saveLanguageIdentifier(_ languageIdentifier: String, for recordingURL: URL) throws {
        var metadata = readMetadata(for: recordingURL)
        metadata.languageIdentifier = SpeechLanguageOption.normalized(languageIdentifier)
        metadata.modifiedAt = Date()
        try saveMetadata(metadata, for: recordingURL)
        CloudSyncStore.shared.sync(recordingURL: recordingURL)
    }

    static func saveTitle(_ title: String, for recordingURL: URL) throws {
        var metadata = readMetadata(for: recordingURL)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        metadata.title = cleanTitle.isEmpty ? nil : cleanTitle
        metadata.modifiedAt = Date()
        try saveMetadata(metadata, for: recordingURL)
        CloudSyncStore.shared.sync(recordingURL: recordingURL)
    }

    static func saveTagTimes(_ tagTimes: [TimeInterval], for recordingURL: URL) throws {
        var metadata = readMetadata(for: recordingURL)
        metadata.tagTimes = normalizedTagTimes(tagTimes)
        metadata.modifiedAt = Date()
        try saveMetadata(metadata, for: recordingURL)
        CloudSyncStore.shared.sync(recordingURL: recordingURL)
    }

    static func delete(_ recording: RecordingItem) throws {
        deleteCloudRecord(for: recording)
        let urls = [
            recording.url,
            transcriptURL(for: recording.url),
            metadataURL(for: recording.url)
        ]

        for url in urls where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    static func delete(_ recordings: [RecordingItem]) throws {
        for recording in recordings {
            try delete(recording)
        }
    }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func sanitizedFileBaseName(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
            .union(.newlines)
            .union(.controlCharacters)

        let cleaned = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? "Recording" : cleaned
    }

    private static func transcriptURL(for recordingURL: URL) -> URL {
        recordingURL.deletingPathExtension().appendingPathExtension("txt")
    }

    private static func metadataURL(for recordingURL: URL) -> URL {
        recordingURL.deletingPathExtension().appendingPathExtension("json")
    }

    private static func saveMetadata(_ metadata: RecordingMetadata, for recordingURL: URL) throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL(for: recordingURL), options: .atomic)
    }

    private static func readMetadata(for recordingURL: URL) -> RecordingMetadata {
        guard let data = try? Data(contentsOf: metadataURL(for: recordingURL)),
              let metadata = try? JSONDecoder().decode(RecordingMetadata.self, from: data) else {
            return RecordingMetadata(languageIdentifier: nil)
        }

        return metadata
    }

    private static func readTranscript(for recordingURL: URL) -> String? {
        guard let text = try? String(contentsOf: transcriptURL(for: recordingURL), encoding: .utf8) else {
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func duration(for url: URL) -> TimeInterval {
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            return 0
        }

        return player.duration
    }

    private static func normalizedTagTimes(_ tagTimes: [TimeInterval]) -> [TimeInterval] {
        Array(Set(tagTimes.map { max(0, $0.rounded()) })).sorted()
    }
}
