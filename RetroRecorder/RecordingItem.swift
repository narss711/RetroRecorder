import Foundation

struct RecordingItem: Identifiable, Equatable {
    let url: URL
    let createdAt: Date
    let duration: TimeInterval
    let languageIdentifier: String?
    let transcript: String?
    let customTitle: String?
    let tagTimes: [TimeInterval]
    let metadata: RecordingMetadata

    var id: URL {
        url
    }

    var title: String {
        if let customTitle,
           customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return customTitle
        }

        let fileTitle = url.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return fileTitle.isEmpty ? "Recording \(Self.dateTimeFormatter.string(from: createdAt))" : fileTitle
    }

    var subtitle: String {
        Self.shortDateTimeFormatter.string(from: createdAt)
    }

    var durationText: String {
        Self.format(duration)
    }

    var resolvedLanguageIdentifier: String {
        languageIdentifier ?? SpeechLanguageOption.defaultIdentifier
    }

    var languageTitle: String {
        SpeechLanguageOption.option(for: resolvedLanguageIdentifier).displayName
    }

    var transcriptCharacterCount: Int {
        transcript?
            .filter { !$0.isWhitespace && !$0.isNewline }
            .count ?? 0
    }

    static func format(_ interval: TimeInterval) -> String {
        let safeInterval = max(0, Int(interval.rounded()))
        let hours = safeInterval / 3600
        let minutes = (safeInterval % 3600) / 60
        let seconds = safeInterval % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()

    private static let shortDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
