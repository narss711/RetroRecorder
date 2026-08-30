import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct RetroRecordControlWidget: ControlWidget {
    static let kind = "com.lutan.RetroRecorder.RecordControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: StartRetroRecordingIntent()) {
                Label("Retro REC", systemImage: "record.circle.fill")
            }
            .tint(.red)
        }
        .displayName("Retro REC")
        .description("Open RetroRecorder and start recording.")
    }
}

struct ToggleRecordingPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "暂停或继续录音"

    func perform() async throws -> some IntentResult {
        RecordingLiveActivityCommandStore.write(.togglePause)
        return .result()
    }
}

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "停止录音"

    func perform() async throws -> some IntentResult {
        RecordingLiveActivityCommandStore.write(.stop)
        return .result()
    }
}

struct RecordingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingLiveActivityAttributes.self) { context in
            RecordingLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.055))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RecordingLiveActivityStatus(context: context, showsTitle: false)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RecordingLiveActivityElapsedText(context: context)
                        .font(.title3.weight(.bold))
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        RecordingLiveActivityCompactModeSummary(mode: context.attributes.mode)

                        RecordingLiveActivityStopButton(compact: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "record.circle.fill")
                    .foregroundStyle(context.state.isPaused ? .yellow : .red)
            } compactTrailing: {
                RecordingLiveActivityElapsedText(context: context)
                    .font(.caption2.monospacedDigit().weight(.bold))
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "record.circle.fill")
                    .foregroundStyle(context.state.isPaused ? .yellow : .red)
            }
        }
    }
}

private struct RecordingLiveActivityLockScreenView: View {
    var context: ActivityViewContext<RecordingLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                RecordingLiveActivityStatus(context: context, showsTitle: false)

                RecordingLiveActivityElapsedText(context: context)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                RecordingLiveActivityStopButton()
            }

            RecordingLiveActivityModeSummary(mode: context.attributes.mode)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
    }
}

private struct RecordingLiveActivityStatus: View {
    var context: ActivityViewContext<RecordingLiveActivityAttributes>
    var showsTitle = true

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.state.isPaused ? "pause.circle.fill" : "record.circle.fill")
                .foregroundStyle(context.state.isPaused ? .yellow : .red)
                .font(.system(size: 20, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.isPaused ? "录音已暂停" : "录音中")
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(1)

                if showsTitle {
                    Text(context.attributes.title)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct RecordingLiveActivityElapsedText: View {
    var context: ActivityViewContext<RecordingLiveActivityAttributes>

    var body: some View {
        Group {
            if context.state.isPaused {
                Text(RecordingLiveActivityAttributes.formatElapsed(context.state.elapsedAtPause))
            } else {
                Text(context.state.timerStartDate, style: .timer)
            }
        }
        .monospacedDigit()
        .contentTransition(.numericText(countsDown: false))
        .accessibilityLabel("当前录音时长")
    }
}

private struct RecordingLiveActivityStopButton: View {
    var compact = false

    var body: some View {
        Button(intent: StopRecordingIntent()) {
            Label(compact ? "STOP" : "停止", systemImage: "stop.fill")
                .font((compact ? Font.caption2 : Font.caption).weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, compact ? 10 : 12)
                .frame(height: compact ? 32 : 40)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("停止录音")
    }
}

private struct RecordingLiveActivityModeSummary: View {
    var mode: RecordingLiveActivityMode

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                RecordingLiveActivityModeValue(
                    label: "MIC",
                    value: mode.inputName,
                    systemName: "mic.fill"
                )

                Divider()
                    .overlay(.white.opacity(0.18))

                RecordingLiveActivityModeValue(
                    label: "FILE",
                    value: mode.fileFormat,
                    systemName: "doc.fill"
                )

                Divider()
                    .overlay(.white.opacity(0.18))

                RecordingLiveActivityModeValue(
                    label: "SPEC",
                    value: mode.sampleSpecification,
                    systemName: "waveform"
                )
            }
            .frame(height: 34)

            HStack(spacing: 14) {
                RecordingLiveActivitySwitchStatus(
                    label: "NR",
                    value: mode.noiseReductionName,
                    isEnabled: mode.isNoiseReductionEnabled
                )

                RecordingLiveActivitySwitchStatus(
                    label: "AEC",
                    value: mode.echoCancellationName,
                    isEnabled: mode.isEchoCancellationEnabled
                )
            }
        }
    }
}

private struct RecordingLiveActivityModeValue: View {
    var label: String
    var value: String
    var systemName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))

            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RecordingLiveActivitySwitchStatus: View {
    var label: String
    var value: String
    var isEnabled: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isEnabled ? Color.green : Color.white.opacity(0.32))
                .frame(width: 6, height: 6)

            Text("\(label) \(isEnabled ? "ON" : "OFF")")
                .font(.caption2.weight(.heavy))

            if isEnabled {
                Text("· \(value)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RecordingLiveActivityCompactModeSummary: View {
    var mode: RecordingLiveActivityMode

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(mode.inputName) · \(mode.fileFormat) · \(mode.sampleSpecification)")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)

            Text("NR \(mode.isNoiseReductionEnabled ? mode.noiseReductionName : "OFF") · AEC \(mode.isEchoCancellationEnabled ? mode.echoCancellationName : "OFF")")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.64))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct MediaWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecordingLiveActivityWidget()

        if #available(iOS 18.0, *) {
            RetroRecordControlWidget()
        }
    }
}
