import ActivityKit
import Foundation

struct RecordingLiveActivityMode: Codable, Hashable {
    var inputName: String
    var fileFormat: String
    var sampleSpecification: String
    var noiseReductionName: String
    var isNoiseReductionEnabled: Bool
    var echoCancellationName: String
    var isEchoCancellationEnabled: Bool
}

struct RecordingLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timerStartDate: Date
        var elapsedAtPause: TimeInterval
        var isPaused: Bool

        var timerInterval: ClosedRange<Date> {
            timerStartDate...timerStartDate.addingTimeInterval(7 * 24 * 60 * 60)
        }

        var timerPauseDate: Date? {
            guard isPaused else {
                return nil
            }

            return timerStartDate.addingTimeInterval(max(0, elapsedAtPause))
        }
    }

    var recordingID: String
    var title: String
    var recordingStatusTitle: String
    var pausedStatusTitle: String
    var mode: RecordingLiveActivityMode

    static func formatElapsed(_ interval: TimeInterval) -> String {
        let safeInterval = max(0, Int(interval.rounded()))
        let hours = safeInterval / 3600
        let minutes = (safeInterval % 3600) / 60
        let seconds = safeInterval % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum RecordingLiveActivityCommand: String, Codable, Hashable {
    case togglePause
    case stop
}

struct RecordingLiveActivityCommandPayload: Codable, Hashable {
    var id: UUID
    var command: RecordingLiveActivityCommand
    var createdAt: Date
}

enum RecordingLiveActivityCommandStore {
    private static let appGroupID = "group.com.lutan.RetroRecorder.mediawidget"
    private static let pendingCommandKey = "recording-live-activity-pending-command"

    static func write(_ command: RecordingLiveActivityCommand) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(
                RecordingLiveActivityCommandPayload(
                    id: UUID(),
                    command: command,
                    createdAt: Date()
                )
              ) else {
            return
        }

        defaults.set(data, forKey: pendingCommandKey)
        defaults.synchronize()
    }

    static func consumePendingCommand() -> RecordingLiveActivityCommandPayload? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: pendingCommandKey),
              let payload = try? JSONDecoder().decode(RecordingLiveActivityCommandPayload.self, from: data) else {
            return nil
        }

        defaults.removeObject(forKey: pendingCommandKey)
        return payload
    }

    static func clearPendingCommand() {
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: pendingCommandKey)
    }
}
