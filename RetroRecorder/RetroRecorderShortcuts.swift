import AppIntents

struct RetroRecorderShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .red

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRetroRecordingIntent(),
            phrases: [
                "Start recording with \(.applicationName)",
                "Record with \(.applicationName)",
                "用 \(.applicationName) 开始录音",
                "使用 \(.applicationName) 录音"
            ],
            shortTitle: "Retro REC",
            systemImageName: "record.circle.fill"
        )
    }
}
