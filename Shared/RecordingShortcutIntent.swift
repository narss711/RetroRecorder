import AppIntents
import Foundation

enum AppDeepLinkAction: String, Codable, Hashable {
    case record
    case history
}

enum AppDeepLink {
    static let recordURL = URL(string: "retrorecorder://record")!
    static let historyURL = URL(string: "retrorecorder://history")!

    static func action(for url: URL) -> AppDeepLinkAction? {
        guard url.scheme?.lowercased() == "retrorecorder" else {
            return nil
        }

        let hostAction = url.host?.lowercased()
        let pathAction = url.pathComponents.dropFirst().first?.lowercased()
        let rawAction = hostAction?.isEmpty == false ? hostAction : pathAction

        switch rawAction {
        case "record", "rec":
            return .record
        case "history":
            return .history
        default:
            return nil
        }
    }
}

enum AppLaunchAction: String, Codable, Hashable {
    case record
    case history

    init(deepLinkAction: AppDeepLinkAction) {
        switch deepLinkAction {
        case .record:
            self = .record
        case .history:
            self = .history
        }
    }
}

enum AppLaunchActionStore {
    private static let appGroupID = "group.com.lutan.RetroRecorder.mediawidget"
    private static let pendingActionKey = "retro-recorder-pending-launch-action"

    static func write(_ action: AppLaunchAction) {
        UserDefaults(suiteName: appGroupID)?.set(action.rawValue, forKey: pendingActionKey)
        UserDefaults(suiteName: appGroupID)?.synchronize()
    }

    static func consumePendingAction() -> AppLaunchAction? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let rawAction = defaults.string(forKey: pendingActionKey),
              let action = AppLaunchAction(rawValue: rawAction) else {
            return nil
        }

        defaults.removeObject(forKey: pendingActionKey)
        return action
    }
}

struct StartRetroRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Retro REC"
    static var description = IntentDescription("Open RetroRecorder and start recording.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AppLaunchActionStore.write(.record)
        return .result()
    }
}
