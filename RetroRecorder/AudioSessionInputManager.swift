import AVFoundation
import Foundation

final class AudioSessionInputManager {
    private let session = AVAudioSession.sharedInstance()

    func prepareSession(echoCancellationEnabled: Bool = false) throws {
        try session.setCategory(
            .playAndRecord,
            mode: echoCancellationEnabled ? .voiceChat : .default,
            options: [.allowBluetoothHFP, .defaultToSpeaker]
        )
        try session.setActive(true)
    }

    func availableInputs() -> [AudioInputOption] {
        var ports = session.availableInputs ?? []

        if ports.isEmpty {
            ports = session.currentRoute.inputs
        }

        return ports
            .map(AudioInputOption.init(port:))
            .sorted { left, right in
                if left.sortPriority == right.sortPriority {
                    return left.deviceName.localizedCompare(right.deviceName) == .orderedAscending
                }
                return left.sortPriority < right.sortPriority
            }
    }

    func selectInput(id: AudioInputOption.ID) throws {
        guard let port = session.availableInputs?.first(where: { $0.uid == id }) else {
            throw NSError(
                domain: "RetroRecorder.AudioInput",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "所选录音设备当前不可用，请刷新后重新选择。"]
            )
        }

        try session.setPreferredInput(port)
    }

    var currentInputID: AudioInputOption.ID? {
        session.preferredInput?.uid ?? session.currentRoute.inputs.first?.uid
    }
}
