import AVFoundation
import Foundation

enum AudioInputKind: String, CaseIterable {
    case builtIn
    case headset
    case usb
    case bluetooth
    case other

    var title: String {
        title(language: .simplifiedChinese)
    }

    func title(language: AppLanguage) -> String {
        if language.resolvedLanguage == .english {
            switch self {
            case .builtIn:
                return "Phone Mic"
            case .headset:
                return "Headset Mic"
            case .usb:
                return "USB Mic"
            case .bluetooth:
                return "Bluetooth Mic"
            case .other:
                return "Other Input"
            }
        }

        switch self {
        case .builtIn:
            return "手机麦克风"
        case .headset:
            return "耳机麦克风"
        case .usb:
            return "USB 麦克风"
        case .bluetooth:
            return "蓝牙麦克风"
        case .other:
            return "其他音源"
        }
    }

    var iconName: String {
        switch self {
        case .builtIn:
            return "iphone"
        case .headset:
            return "headphones"
        case .usb:
            return "cable.connector"
        case .bluetooth:
            return "wave.3.right.circle"
        case .other:
            return "mic"
        }
    }

    var sortPriority: Int {
        switch self {
        case .builtIn:
            return 0
        case .headset:
            return 1
        case .usb:
            return 2
        case .bluetooth:
            return 3
        case .other:
            return 4
        }
    }
}

struct AudioInputOption: Identifiable, Hashable {
    let id: String
    let kind: AudioInputKind
    let deviceName: String
    let portType: String

    var title: String {
        kind.title
    }

    func title(language: AppLanguage) -> String {
        kind.title(language: language)
    }

    var subtitle: String {
        deviceName == title ? portType : deviceName
    }

    func subtitle(language: AppLanguage) -> String {
        let localizedTitle = title(language: language)
        return deviceName == kind.title || deviceName == localizedTitle ? portType : deviceName
    }

    var iconName: String {
        kind.iconName
    }

    var sortPriority: Int {
        kind.sortPriority
    }

    init(port: AVAudioSessionPortDescription) {
        id = port.uid
        kind = AudioInputKind(portType: port.portType)
        deviceName = port.portName
        portType = port.portType.rawValue
    }
}

private extension AudioInputKind {
    init(portType: AVAudioSession.Port) {
        switch portType {
        case .builtInMic:
            self = .builtIn
        case .headsetMic:
            self = .headset
        case .usbAudio:
            self = .usb
        case .bluetoothHFP:
            self = .bluetooth
        default:
            self = .other
        }
    }
}
