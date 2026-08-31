import SwiftUI
import UIKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese
    case traditionalChinese
    case english
    case spanish
    case arabic
    case portuguese
    case russian
    case japanese
    case german
    case french

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch resolvedLanguage {
        case .system:
            return "zh-Hans"
        case .simplifiedChinese:
            return "zh-Hans"
        case .traditionalChinese:
            return "zh-Hant"
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .arabic:
            return "ar"
        case .portuguese:
            return "pt"
        case .russian:
            return "ru"
        case .japanese:
            return "ja"
        case .german:
            return "de"
        case .french:
            return "fr"
        }
    }

    var title: String {
        title(displayLanguage: self)
    }

    func title(displayLanguage: AppLanguage) -> String {
        switch self {
        case .system:
            return displayLanguage.text(.followSystem)
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .arabic:
            return "العربية"
        case .portuguese:
            return "Português"
        case .russian:
            return "Русский"
        case .japanese:
            return "日本語"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        }
    }

    var subtitle: String {
        subtitle(displayLanguage: self)
    }

    func subtitle(displayLanguage: AppLanguage) -> String {
        switch self {
        case .system:
            return displayLanguage.text(.followSystemSubtitle)
        case .simplifiedChinese:
            return "Simplified Chinese"
        case .traditionalChinese:
            return "Traditional Chinese"
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .arabic:
            return "Arabic"
        case .portuguese:
            return "Portuguese"
        case .russian:
            return "Russian"
        case .japanese:
            return "Japanese"
        case .german:
            return "German"
        case .french:
            return "French"
        }
    }

    var resolvedLanguage: AppLanguage {
        guard self == .system else {
            return self
        }

        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "zh"

        if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") {
            return .traditionalChinese
        }

        if preferred.hasPrefix("zh") {
            return .simplifiedChinese
        }

        if preferred.hasPrefix("es") { return .spanish }
        if preferred.hasPrefix("ar") { return .arabic }
        if preferred.hasPrefix("pt") { return .portuguese }
        if preferred.hasPrefix("ru") { return .russian }
        if preferred.hasPrefix("ja") { return .japanese }
        if preferred.hasPrefix("de") { return .german }
        if preferred.hasPrefix("fr") { return .french }

        return .english
    }

    func text(_ copy: AppCopy) -> String {
        switch resolvedLanguage {
        case .system, .simplifiedChinese:
            return copy.zhHans
        case .traditionalChinese:
            return copy.zhHant
        case .english:
            return copy.english
        case .spanish:
            return copy.spanish
        case .arabic:
            return copy.arabic
        case .portuguese:
            return copy.portuguese
        case .russian:
            return copy.russian
        case .japanese:
            return copy.japanese
        case .german:
            return copy.german
        case .french:
            return copy.french
        }
    }

    var layoutDirection: LayoutDirection {
        resolvedLanguage == .arabic ? .rightToLeft : .leftToRight
    }

    func format(_ copy: AppCopy, _ arguments: CVarArg...) -> String {
        String(format: text(copy), locale: Locale(identifier: localeIdentifier), arguments: arguments)
    }

    static func value(for rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .system
    }
}

enum InterfaceRetroFont: String, CaseIterable, Identifiable {
    case system
    case vt323
    case pressStart2P
    case silkscreen
    case specialElite

    static let storageKey = "interfaceRetroFont"

    var id: String { rawValue }

    static func value(for rawValue: String) -> InterfaceRetroFont {
        InterfaceRetroFont(rawValue: rawValue) ?? .system
    }

    var title: String {
        switch self {
        case .system:
            return "System Mono"
        case .vt323:
            return "VT323"
        case .pressStart2P:
            return "Press Start 2P"
        case .silkscreen:
            return "Silkscreen"
        case .specialElite:
            return "Special Elite"
        }
    }

    var subtitle: String {
        switch self {
        case .system:
            return "Default pixel UI"
        case .vt323:
            return "CRT terminal"
        case .pressStart2P:
            return "8-bit arcade"
        case .silkscreen:
            return "Early web pixel"
        case .specialElite:
            return "Vintage typewriter"
        }
    }

    var sampleText: String {
        switch self {
        case .system:
            return "RETRO REC"
        case .vt323:
            return "TAPE READY"
        case .pressStart2P:
            return "PRESS REC"
        case .silkscreen:
            return "INPUT WAVE"
        case .specialElite:
            return "New Recording"
        }
    }

    private var postScriptName: String? {
        switch self {
        case .system:
            return nil
        case .vt323:
            return "VT323-Regular"
        case .pressStart2P:
            return "PressStart2P-Regular"
        case .silkscreen:
            return "Silkscreen-Regular"
        case .specialElite:
            return "SpecialElite-Regular"
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        guard let postScriptName else {
            return .system(size: size, weight: weight, design: design)
        }

        return .custom(postScriptName, size: adjustedSize(size), relativeTo: .body)
    }

    private func adjustedSize(_ size: CGFloat) -> CGFloat {
        switch self {
        case .system:
            return size
        case .vt323:
            return size * 1.18
        case .pressStart2P:
            return size * 0.72
        case .silkscreen:
            return size * 0.92
        case .specialElite:
            return size * 1.05
        }
    }
}

private struct InterfaceRetroFontEnvironmentKey: EnvironmentKey {
    static let defaultValue = InterfaceRetroFont.system
}

extension EnvironmentValues {
    var interfaceRetroFont: InterfaceRetroFont {
        get { self[InterfaceRetroFontEnvironmentKey.self] }
        set { self[InterfaceRetroFontEnvironmentKey.self] = newValue }
    }
}

private struct RetroUIFontModifier: ViewModifier {
    @Environment(\.interfaceRetroFont) private var interfaceRetroFont

    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content.font(interfaceRetroFont.font(size: size, weight: weight, design: design))
    }
}

extension View {
    func retroFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(RetroUIFontModifier(size: size, weight: weight, design: design))
    }

    func recordingTagToast(_ toast: Binding<RecordingTagToast?>) -> some View {
        modifier(RecordingTagToastModifier(toast: toast))
    }
}

enum AppCopy: Hashable {
    case alertTitle
    case ok
    case settings
    case done
    case source
    case currentSource
    case sourcePickerTitle
    case sourcePickerMessage
    case sourceUnavailable
    case refreshSource
    case noSource
    case noInputs
    case recentRecordings
    case all
    case noRecordings
    case viewHistoryFormat
    case transcribe
    case transcript
    case copyText
    case delete
    case select
    case selectedCountFormat
    case history
    case characterCountFormat
    case appLanguage
    case transcriptionModel
    case followSystem
    case followSystemSubtitle
    case cassetteStyle
    case current
    case manualInput
    case use
    case availableLanguages
    case searchLanguage
    case recognitionLanguage
    case interfaceTheme
    case interfaceFont
    case waveformFilter
    case asciiVideoFilter
    case asciiVideoFilterSubtitle
    case audioRecordingSettings
    case audioFileFormat
    case audioSampleRate
    case audioBitDepth
    case cancel
    case noiseReduction
    case noiseReductionMode
    case noiseReductionOff
    case noiseReductionOffSubtitle
    case rnnoiseTitle
    case rnnoiseSubtitle
    case deepFilterNetV3Title
    case deepFilterNetV3Subtitle
    case dtlnTitle
    case dtlnSubtitle
    case requiresRuntime
    case share
    case liveText
    case liveTextPlaceholder
    case startRec
    case historySwipeHint
}

extension AppCopy {
    var zhHans: String {
        switch self {
        case .alertTitle:
            return "提示"
        case .ok:
            return "好"
        case .settings:
            return "设置"
        case .done:
            return "完成"
        case .source:
            return "音源"
        case .currentSource:
            return "当前音源"
        case .sourcePickerTitle:
            return "切换音源"
        case .sourcePickerMessage:
            return "默认会自动切换到最新检测到的音源。"
        case .sourceUnavailable:
            return "音源不可用"
        case .refreshSource:
            return "刷新音源"
        case .noSource:
            return "无音源"
        case .noInputs:
            return "未检测到可用输入"
        case .recentRecordings:
            return "最近录音"
        case .all:
            return "全部"
        case .noRecordings:
            return "暂无录音"
        case .viewHistoryFormat:
            return "查看 %d 条历史录音"
        case .transcribe:
            return "转文本"
        case .transcript:
            return "转写文本"
        case .copyText:
            return "复制文本"
        case .delete:
            return "删除"
        case .select:
            return "选择"
        case .selectedCountFormat:
            return "已选择 %d 条"
        case .history:
            return "历史录音"
        case .characterCountFormat:
            return "%d 字"
        case .appLanguage:
            return "APP 语言"
        case .transcriptionModel:
            return "语音识别模型"
        case .followSystem:
            return "跟随系统"
        case .followSystemSubtitle:
            return "使用 iPhone 当前语言"
        case .cassetteStyle:
            return "磁带样式"
        case .current:
            return "当前"
        case .manualInput:
            return "手动输入"
        case .use:
            return "使用"
        case .availableLanguages:
            return "可选语言"
        case .searchLanguage:
            return "搜索语言或代码"
        case .recognitionLanguage:
            return "识别语言"
        case .interfaceTheme:
            return "界面主题"
        case .interfaceFont:
            return "界面字体"
        case .waveformFilter:
            return "波形滤镜"
        case .asciiVideoFilter:
            return "ASCII 字符滤镜"
        case .asciiVideoFilterSubtitle:
            return "用字符密度显示实时音频画面"
        case .audioRecordingSettings:
            return "音频录制"
        case .audioFileFormat:
            return "文件格式"
        case .audioSampleRate:
            return "采样率"
        case .audioBitDepth:
            return "位数深度"
        case .cancel:
            return "取消"
        case .noiseReduction:
            return "降噪"
        case .noiseReductionMode:
            return "RNNoise"
        case .noiseReductionOff:
            return "关闭"
        case .noiseReductionOffSubtitle:
            return "原始录音"
        case .rnnoiseTitle:
            return "RNNoise"
        case .rnnoiseSubtitle:
            return "已内置，低延迟"
        case .deepFilterNetV3Title:
            return "DeepFilterNet V3"
        case .deepFilterNetV3Subtitle:
            return "高质量神经网络降噪"
        case .dtlnTitle:
            return "DTLN"
        case .dtlnSubtitle:
            return "ONNX 本地实时模型"
        case .requiresRuntime:
            return "需运行时"
        case .share:
            return "分享"
        case .liveText:
            return "实时文本"
        case .liveTextPlaceholder:
            return "正在识别语音输入..."
        case .startRec:
            return "开始录制"
        case .historySwipeHint:
            return "上滑约 1/5 快速进入历史录音"
        }
    }

    var english: String {
        switch self {
        case .alertTitle:
            return "Notice"
        case .ok:
            return "OK"
        case .settings:
            return "Settings"
        case .done:
            return "Done"
        case .source:
            return "Input"
        case .currentSource:
            return "Current Input"
        case .sourcePickerTitle:
            return "Switch Input"
        case .sourcePickerMessage:
            return "The latest detected input is selected automatically by default."
        case .sourceUnavailable:
            return "No Input"
        case .refreshSource:
            return "Refresh Inputs"
        case .noSource:
            return "No Input"
        case .noInputs:
            return "No input detected"
        case .recentRecordings:
            return "Recent Recordings"
        case .all:
            return "All"
        case .noRecordings:
            return "No recordings yet"
        case .viewHistoryFormat:
            return "View %d recordings"
        case .transcribe:
            return "Transcribe"
        case .transcript:
            return "Transcript"
        case .copyText:
            return "Copy Text"
        case .delete:
            return "Delete"
        case .select:
            return "Select"
        case .selectedCountFormat:
            return "%d selected"
        case .history:
            return "History"
        case .characterCountFormat:
            return "%d chars"
        case .appLanguage:
            return "App Language"
        case .transcriptionModel:
            return "Speech Model"
        case .followSystem:
            return "Follow System"
        case .followSystemSubtitle:
            return "Use the current iPhone language"
        case .cassetteStyle:
            return "Cassette Style"
        case .current:
            return "Current"
        case .manualInput:
            return "Manual Entry"
        case .use:
            return "Use"
        case .availableLanguages:
            return "Available Languages"
        case .searchLanguage:
            return "Search language or code"
        case .recognitionLanguage:
            return "Recognition Language"
        case .interfaceTheme:
            return "Interface Theme"
        case .interfaceFont:
            return "Interface Font"
        case .waveformFilter:
            return "Waveform Filter"
        case .asciiVideoFilter:
            return "ASCII Character Filter"
        case .asciiVideoFilterSubtitle:
            return "Render live audio visuals through character density"
        case .audioRecordingSettings:
            return "Audio Recording"
        case .audioFileFormat:
            return "File Format"
        case .audioSampleRate:
            return "Sample Rate"
        case .audioBitDepth:
            return "Bit Depth"
        case .cancel:
            return "Cancel"
        case .noiseReduction:
            return "Noise Reduction"
        case .noiseReductionMode:
            return "RNNoise"
        case .noiseReductionOff:
            return "Off"
        case .noiseReductionOffSubtitle:
            return "Raw recording"
        case .rnnoiseTitle:
            return "RNNoise"
        case .rnnoiseSubtitle:
            return "Built in, low latency"
        case .deepFilterNetV3Title:
            return "DeepFilterNet V3"
        case .deepFilterNetV3Subtitle:
            return "High-quality neural denoising"
        case .dtlnTitle:
            return "DTLN"
        case .dtlnSubtitle:
            return "Local ONNX real-time model"
        case .requiresRuntime:
            return "Runtime needed"
        case .share:
            return "Share"
        case .liveText:
            return "Live Text"
        case .liveTextPlaceholder:
            return "Listening for speech..."
        case .startRec:
            return "Start Rec"
        case .historySwipeHint:
            return "SWIPE UP 1/5 TO OPEN HISTORY"
        }
    }
}

private extension AppCopy {
    var zhHant: String {
        localized([
            .alertTitle: "提示",
            .ok: "好",
            .settings: "設定",
            .done: "完成",
            .source: "音源",
            .currentSource: "目前音源",
            .sourcePickerTitle: "切換音源",
            .sourcePickerMessage: "預設會自動切換到最新偵測到的音源。",
            .sourceUnavailable: "音源不可用",
            .refreshSource: "重新整理音源",
            .noSource: "無音源",
            .noInputs: "未偵測到可用輸入",
            .recentRecordings: "最近錄音",
            .all: "全部",
            .noRecordings: "暫無錄音",
            .viewHistoryFormat: "查看 %d 筆歷史錄音",
            .transcribe: "轉文字",
            .transcript: "轉寫文字",
            .copyText: "複製文字",
            .delete: "刪除",
            .select: "選擇",
            .selectedCountFormat: "已選擇 %d 筆",
            .history: "歷史錄音",
            .characterCountFormat: "%d 字",
            .appLanguage: "APP 語言",
            .transcriptionModel: "語音識別模型",
            .followSystem: "跟隨系統",
            .followSystemSubtitle: "使用 iPhone 目前語言",
            .cassetteStyle: "磁帶樣式",
            .current: "目前",
            .manualInput: "手動輸入",
            .use: "使用",
            .availableLanguages: "可選語言",
            .searchLanguage: "搜尋語言或代碼",
            .recognitionLanguage: "識別語言",
            .interfaceTheme: "介面主題",
            .cancel: "取消",
            .noiseReduction: "降噪",
            .noiseReductionMode: "RNNoise",
            .noiseReductionOff: "關閉",
            .noiseReductionOffSubtitle: "原始錄音",
            .rnnoiseTitle: "RNNoise",
            .rnnoiseSubtitle: "已內建，低延遲",
            .deepFilterNetV3Title: "DeepFilterNet V3",
            .deepFilterNetV3Subtitle: "高品質神經網路降噪",
            .dtlnTitle: "DTLN",
            .dtlnSubtitle: "ONNX 本地即時模型",
            .requiresRuntime: "需執行環境",
            .share: "分享",
            .liveText: "即時文字",
            .liveTextPlaceholder: "正在識別語音輸入...",
            .startRec: "開始錄製"
        ])
    }

    var spanish: String {
        localized([
            .alertTitle: "Aviso",
            .ok: "Aceptar",
            .settings: "Ajustes",
            .done: "Hecho",
            .source: "Entrada",
            .currentSource: "Entrada actual",
            .sourcePickerTitle: "Cambiar entrada",
            .sourcePickerMessage: "La entrada detectada más reciente se selecciona automáticamente.",
            .sourceUnavailable: "Entrada no disponible",
            .refreshSource: "Actualizar entradas",
            .noSource: "Sin entrada",
            .noInputs: "No se detectó entrada",
            .recentRecordings: "Grabaciones recientes",
            .all: "Todo",
            .noRecordings: "Sin grabaciones",
            .viewHistoryFormat: "Ver %d grabaciones",
            .transcribe: "Transcribir",
            .transcript: "Transcripción",
            .copyText: "Copiar texto",
            .delete: "Eliminar",
            .select: "Seleccionar",
            .selectedCountFormat: "%d seleccionadas",
            .history: "Historial",
            .characterCountFormat: "%d caracteres",
            .appLanguage: "Idioma de la app",
            .transcriptionModel: "Modelo de voz",
            .followSystem: "Seguir sistema",
            .followSystemSubtitle: "Usar el idioma actual del iPhone",
            .cassetteStyle: "Estilo de casete",
            .current: "Actual",
            .manualInput: "Entrada manual",
            .use: "Usar",
            .availableLanguages: "Idiomas disponibles",
            .searchLanguage: "Buscar idioma o código",
            .recognitionLanguage: "Idioma de reconocimiento",
            .interfaceTheme: "Tema de interfaz",
            .cancel: "Cancelar",
            .noiseReduction: "Reducción de ruido",
            .noiseReductionOff: "Desactivado",
            .noiseReductionOffSubtitle: "Grabación original",
            .rnnoiseSubtitle: "Integrado, baja latencia",
            .deepFilterNetV3Subtitle: "Reducción neuronal de alta calidad",
            .dtlnSubtitle: "Modelo ONNX local en tiempo real",
            .requiresRuntime: "Requiere runtime",
            .share: "Compartir",
            .liveText: "Texto en vivo",
            .liveTextPlaceholder: "Escuchando voz...",
            .startRec: "Iniciar"
        ])
    }

    var arabic: String {
        localized([
            .alertTitle: "تنبيه",
            .ok: "حسنًا",
            .settings: "الإعدادات",
            .done: "تم",
            .source: "الإدخال",
            .currentSource: "الإدخال الحالي",
            .sourcePickerTitle: "تبديل الإدخال",
            .sourcePickerMessage: "يتم اختيار أحدث إدخال مكتشف تلقائيًا.",
            .sourceUnavailable: "الإدخال غير متاح",
            .refreshSource: "تحديث الإدخالات",
            .noSource: "لا يوجد إدخال",
            .noInputs: "لم يتم اكتشاف إدخال",
            .recentRecordings: "التسجيلات الأخيرة",
            .all: "الكل",
            .noRecordings: "لا توجد تسجيلات",
            .viewHistoryFormat: "عرض %d تسجيلات",
            .transcribe: "تحويل لنص",
            .transcript: "النص",
            .copyText: "نسخ النص",
            .delete: "حذف",
            .select: "تحديد",
            .selectedCountFormat: "تم تحديد %d",
            .history: "السجل",
            .characterCountFormat: "%d حرف",
            .appLanguage: "لغة التطبيق",
            .transcriptionModel: "نموذج الكلام",
            .followSystem: "اتباع النظام",
            .followSystemSubtitle: "استخدام لغة iPhone الحالية",
            .cassetteStyle: "نمط الشريط",
            .current: "الحالي",
            .manualInput: "إدخال يدوي",
            .use: "استخدام",
            .availableLanguages: "اللغات المتاحة",
            .searchLanguage: "ابحث عن لغة أو رمز",
            .recognitionLanguage: "لغة التعرف",
            .interfaceTheme: "سمة الواجهة",
            .cancel: "إلغاء",
            .noiseReduction: "تقليل الضوضاء",
            .noiseReductionOff: "إيقاف",
            .noiseReductionOffSubtitle: "تسجيل أصلي",
            .rnnoiseSubtitle: "مدمج، بزمن تأخير منخفض",
            .deepFilterNetV3Subtitle: "تقليل ضوضاء عصبي عالي الجودة",
            .dtlnSubtitle: "نموذج ONNX محلي فوري",
            .requiresRuntime: "يتطلب runtime",
            .share: "مشاركة",
            .liveText: "نص مباشر",
            .liveTextPlaceholder: "جار الاستماع للصوت...",
            .startRec: "بدء التسجيل"
        ])
    }

    var portuguese: String {
        localized([
            .alertTitle: "Aviso",
            .ok: "OK",
            .settings: "Ajustes",
            .done: "Concluído",
            .source: "Entrada",
            .currentSource: "Entrada atual",
            .sourcePickerTitle: "Trocar entrada",
            .sourcePickerMessage: "A entrada detectada mais recente é selecionada automaticamente.",
            .sourceUnavailable: "Entrada indisponível",
            .refreshSource: "Atualizar entradas",
            .noSource: "Sem entrada",
            .noInputs: "Nenhuma entrada detectada",
            .recentRecordings: "Gravações recentes",
            .all: "Tudo",
            .noRecordings: "Sem gravações",
            .viewHistoryFormat: "Ver %d gravações",
            .transcribe: "Transcrever",
            .transcript: "Transcrição",
            .copyText: "Copiar texto",
            .delete: "Excluir",
            .select: "Selecionar",
            .selectedCountFormat: "%d selecionadas",
            .history: "Histórico",
            .characterCountFormat: "%d caracteres",
            .appLanguage: "Idioma do app",
            .transcriptionModel: "Modelo de fala",
            .followSystem: "Seguir sistema",
            .followSystemSubtitle: "Usar o idioma atual do iPhone",
            .cassetteStyle: "Estilo da fita",
            .current: "Atual",
            .manualInput: "Entrada manual",
            .use: "Usar",
            .availableLanguages: "Idiomas disponíveis",
            .searchLanguage: "Buscar idioma ou código",
            .recognitionLanguage: "Idioma de reconhecimento",
            .interfaceTheme: "Tema da interface",
            .cancel: "Cancelar",
            .noiseReduction: "Redução de ruído",
            .noiseReductionOff: "Desativado",
            .noiseReductionOffSubtitle: "Gravação original",
            .rnnoiseSubtitle: "Integrado, baixa latência",
            .deepFilterNetV3Subtitle: "Redução neural de alta qualidade",
            .dtlnSubtitle: "Modelo ONNX local em tempo real",
            .requiresRuntime: "Requer runtime",
            .share: "Compartilhar",
            .liveText: "Texto ao vivo",
            .liveTextPlaceholder: "Ouvindo fala...",
            .startRec: "Iniciar"
        ])
    }

    var russian: String {
        localized([
            .alertTitle: "Уведомление",
            .ok: "OK",
            .settings: "Настройки",
            .done: "Готово",
            .source: "Вход",
            .currentSource: "Текущий вход",
            .sourcePickerTitle: "Сменить вход",
            .sourcePickerMessage: "Последний обнаруженный вход выбирается автоматически.",
            .sourceUnavailable: "Вход недоступен",
            .refreshSource: "Обновить входы",
            .noSource: "Нет входа",
            .noInputs: "Входы не найдены",
            .recentRecordings: "Недавние записи",
            .all: "Все",
            .noRecordings: "Записей пока нет",
            .viewHistoryFormat: "Показать %d записей",
            .transcribe: "Распознать",
            .transcript: "Текст",
            .copyText: "Копировать текст",
            .delete: "Удалить",
            .select: "Выбрать",
            .selectedCountFormat: "Выбрано: %d",
            .history: "История",
            .characterCountFormat: "%d симв.",
            .appLanguage: "Язык приложения",
            .transcriptionModel: "Модель речи",
            .followSystem: "Как в системе",
            .followSystemSubtitle: "Использовать текущий язык iPhone",
            .cassetteStyle: "Стиль кассеты",
            .current: "Текущий",
            .manualInput: "Ручной ввод",
            .use: "Использовать",
            .availableLanguages: "Доступные языки",
            .searchLanguage: "Поиск языка или кода",
            .recognitionLanguage: "Язык распознавания",
            .interfaceTheme: "Тема интерфейса",
            .cancel: "Отмена",
            .noiseReduction: "Шумоподавление",
            .noiseReductionOff: "Выкл.",
            .noiseReductionOffSubtitle: "Исходная запись",
            .rnnoiseSubtitle: "Встроено, малая задержка",
            .deepFilterNetV3Subtitle: "Нейронное шумоподавление высокого качества",
            .dtlnSubtitle: "Локальная ONNX-модель в реальном времени",
            .requiresRuntime: "Нужен runtime",
            .share: "Поделиться",
            .liveText: "Живой текст",
            .liveTextPlaceholder: "Слушаю речь...",
            .startRec: "Начать"
        ])
    }

    var japanese: String {
        localized([
            .alertTitle: "通知",
            .ok: "OK",
            .settings: "設定",
            .done: "完了",
            .source: "入力",
            .currentSource: "現在の入力",
            .sourcePickerTitle: "入力を切替",
            .sourcePickerMessage: "最後に検出された入力を自動選択します。",
            .sourceUnavailable: "入力不可",
            .refreshSource: "入力を更新",
            .noSource: "入力なし",
            .noInputs: "利用可能な入力がありません",
            .recentRecordings: "最近の録音",
            .all: "すべて",
            .noRecordings: "録音はまだありません",
            .viewHistoryFormat: "%d 件の録音を表示",
            .transcribe: "文字起こし",
            .transcript: "文字起こし",
            .copyText: "テキストをコピー",
            .delete: "削除",
            .select: "選択",
            .selectedCountFormat: "%d 件選択中",
            .history: "履歴",
            .characterCountFormat: "%d 文字",
            .appLanguage: "アプリ言語",
            .transcriptionModel: "音声モデル",
            .followSystem: "システムに従う",
            .followSystemSubtitle: "現在の iPhone 言語を使用",
            .cassetteStyle: "カセットスタイル",
            .current: "現在",
            .manualInput: "手動入力",
            .use: "使用",
            .availableLanguages: "利用可能な言語",
            .searchLanguage: "言語またはコードを検索",
            .recognitionLanguage: "認識言語",
            .interfaceTheme: "インターフェーステーマ",
            .cancel: "キャンセル",
            .noiseReduction: "ノイズ低減",
            .noiseReductionOff: "オフ",
            .noiseReductionOffSubtitle: "元の録音",
            .rnnoiseSubtitle: "内蔵、低遅延",
            .deepFilterNetV3Subtitle: "高品質ニューラルノイズ低減",
            .dtlnSubtitle: "ローカル ONNX リアルタイムモデル",
            .requiresRuntime: "Runtime が必要",
            .share: "共有",
            .liveText: "ライブテキスト",
            .liveTextPlaceholder: "音声を認識中...",
            .startRec: "録音開始"
        ])
    }

    var german: String {
        localized([
            .alertTitle: "Hinweis",
            .ok: "OK",
            .settings: "Einstellungen",
            .done: "Fertig",
            .source: "Eingang",
            .currentSource: "Aktueller Eingang",
            .sourcePickerTitle: "Eingang wechseln",
            .sourcePickerMessage: "Der zuletzt erkannte Eingang wird automatisch gewählt.",
            .sourceUnavailable: "Eingang nicht verfügbar",
            .refreshSource: "Eingänge aktualisieren",
            .noSource: "Kein Eingang",
            .noInputs: "Kein Eingang erkannt",
            .recentRecordings: "Letzte Aufnahmen",
            .all: "Alle",
            .noRecordings: "Noch keine Aufnahmen",
            .viewHistoryFormat: "%d Aufnahmen anzeigen",
            .transcribe: "Transkribieren",
            .transcript: "Transkript",
            .copyText: "Text kopieren",
            .delete: "Löschen",
            .select: "Auswählen",
            .selectedCountFormat: "%d ausgewählt",
            .history: "Verlauf",
            .characterCountFormat: "%d Zeichen",
            .appLanguage: "App-Sprache",
            .transcriptionModel: "Sprachmodell",
            .followSystem: "System folgen",
            .followSystemSubtitle: "Aktuelle iPhone-Sprache verwenden",
            .cassetteStyle: "Kassettenstil",
            .current: "Aktuell",
            .manualInput: "Manuelle Eingabe",
            .use: "Verwenden",
            .availableLanguages: "Verfügbare Sprachen",
            .searchLanguage: "Sprache oder Code suchen",
            .recognitionLanguage: "Erkennungssprache",
            .interfaceTheme: "Oberflächenthema",
            .cancel: "Abbrechen",
            .noiseReduction: "Rauschminderung",
            .noiseReductionOff: "Aus",
            .noiseReductionOffSubtitle: "Originalaufnahme",
            .rnnoiseSubtitle: "Integriert, geringe Latenz",
            .deepFilterNetV3Subtitle: "Hochwertige neuronale Rauschminderung",
            .dtlnSubtitle: "Lokales ONNX-Echtzeitmodell",
            .requiresRuntime: "Runtime nötig",
            .share: "Teilen",
            .liveText: "Live-Text",
            .liveTextPlaceholder: "Sprache wird erkannt...",
            .startRec: "Start"
        ])
    }

    var french: String {
        localized([
            .alertTitle: "Avis",
            .ok: "OK",
            .settings: "Réglages",
            .done: "Terminé",
            .source: "Entrée",
            .currentSource: "Entrée actuelle",
            .sourcePickerTitle: "Changer d’entrée",
            .sourcePickerMessage: "La dernière entrée détectée est sélectionnée automatiquement.",
            .sourceUnavailable: "Entrée indisponible",
            .refreshSource: "Actualiser les entrées",
            .noSource: "Aucune entrée",
            .noInputs: "Aucune entrée détectée",
            .recentRecordings: "Enregistrements récents",
            .all: "Tout",
            .noRecordings: "Aucun enregistrement",
            .viewHistoryFormat: "Voir %d enregistrements",
            .transcribe: "Transcrire",
            .transcript: "Transcription",
            .copyText: "Copier le texte",
            .delete: "Supprimer",
            .select: "Sélectionner",
            .selectedCountFormat: "%d sélectionnés",
            .history: "Historique",
            .characterCountFormat: "%d caractères",
            .appLanguage: "Langue de l’app",
            .transcriptionModel: "Modèle vocal",
            .followSystem: "Suivre le système",
            .followSystemSubtitle: "Utiliser la langue actuelle de l’iPhone",
            .cassetteStyle: "Style cassette",
            .current: "Actuel",
            .manualInput: "Saisie manuelle",
            .use: "Utiliser",
            .availableLanguages: "Langues disponibles",
            .searchLanguage: "Rechercher une langue ou un code",
            .recognitionLanguage: "Langue de reconnaissance",
            .interfaceTheme: "Thème de l’interface",
            .cancel: "Annuler",
            .noiseReduction: "Réduction du bruit",
            .noiseReductionOff: "Désactivé",
            .noiseReductionOffSubtitle: "Enregistrement original",
            .rnnoiseSubtitle: "Intégré, faible latence",
            .deepFilterNetV3Subtitle: "Réduction neuronale de haute qualité",
            .dtlnSubtitle: "Modèle ONNX local en temps réel",
            .requiresRuntime: "Runtime requis",
            .share: "Partager",
            .liveText: "Texte en direct",
            .liveTextPlaceholder: "Écoute de la parole...",
            .startRec: "Démarrer"
        ])
    }

    private func localized(_ values: [AppCopy: String]) -> String {
        values[self] ?? english
    }
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppLanguage.system
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}

extension NoiseReductionMode {
    var iconName: String {
        switch self {
        case .off:
            return "waveform.slash"
        case .rnnoise:
            return "waveform.badge.magnifyingglass"
        case .deepFilterNetV3:
            return "brain.head.profile"
        case .dtln:
            return "cpu"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .off:
            return language.text(.noiseReductionOff)
        case .rnnoise:
            return language.text(.rnnoiseTitle)
        case .deepFilterNetV3:
            return language.text(.deepFilterNetV3Title)
        case .dtln:
            return language.text(.dtlnTitle)
        }
    }

    func subtitle(language: AppLanguage) -> String {
        guard isAvailable else {
            return language.text(.requiresRuntime)
        }

        switch self {
        case .off:
            return language.text(.noiseReductionOffSubtitle)
        case .rnnoise:
            return language.text(.rnnoiseSubtitle)
        case .deepFilterNetV3:
            return language.text(.deepFilterNetV3Subtitle)
        case .dtln:
            return language.text(.dtlnSubtitle)
        }
    }
}

extension EchoCancellationMode {
    var iconName: String {
        switch self {
        case .off:
            return "speaker.slash"
        case .voiceProcessing:
            return "speaker.wave.2.bubble"
        case .speexDSP:
            return "waveform.badge.magnifyingglass"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .off:
            return localizedTitle(
                language: language,
                zhHans: "关闭",
                zhHant: "關閉",
                english: "Off",
                spanish: "Desactivado",
                arabic: "إيقاف",
                portuguese: "Desativado",
                russian: "Выкл.",
                japanese: "オフ",
                german: "Aus",
                french: "Désactivé"
            )
        case .voiceProcessing:
            return localizedTitle(
                language: language,
                zhHans: "系统 AEC",
                zhHant: "系統 AEC",
                english: "System AEC",
                spanish: "AEC sistema",
                arabic: "AEC النظام",
                portuguese: "AEC sistema",
                russian: "Системный AEC",
                japanese: "システム AEC",
                german: "System-AEC",
                french: "AEC système"
            )
        case .speexDSP:
            return "SpeexDSP AEC"
        }
    }

    func subtitle(language: AppLanguage) -> String {
        switch self {
        case .off:
            return localizedTitle(
                language: language,
                zhHans: "不处理回声",
                zhHant: "不處理回聲",
                english: "No echo processing",
                spanish: "Sin eco",
                arabic: "بدون معالجة صدى",
                portuguese: "Sem eco",
                russian: "Без обработки эха",
                japanese: "エコー処理なし",
                german: "Keine Echoverarbeitung",
                french: "Sans traitement d’écho"
            )
        case .voiceProcessing:
            return localizedTitle(
                language: language,
                zhHans: "使用 iOS Voice Processing",
                zhHant: "使用 iOS Voice Processing",
                english: "Uses iOS Voice Processing",
                spanish: "Usa Voice Processing de iOS",
                arabic: "يستخدم معالجة الصوت في iOS",
                portuguese: "Usa Voice Processing do iOS",
                russian: "Использует iOS Voice Processing",
                japanese: "iOS Voice Processing を使用",
                german: "Nutzt iOS Voice Processing",
                french: "Utilise Voice Processing iOS"
            )
        case .speexDSP:
            return localizedTitle(
                language: language,
                zhHans: "需扬声器参考流",
                zhHant: "需喇叭參考流",
                english: "Needs playback reference",
                spanish: "Requiere referencia",
                arabic: "يتطلب مرجع تشغيل",
                portuguese: "Requer referência",
                russian: "Нужен опорный звук",
                japanese: "再生参照が必要",
                german: "Benötigt Playback-Referenz",
                french: "Référence requise"
            )
        }
    }

    private func localizedTitle(
        language: AppLanguage,
        zhHans: String,
        zhHant: String,
        english: String,
        spanish: String,
        arabic: String,
        portuguese: String,
        russian: String,
        japanese: String,
        german: String,
        french: String
    ) -> String {
        switch language.resolvedLanguage {
        case .system, .simplifiedChinese:
            return zhHans
        case .traditionalChinese:
            return zhHant
        case .english:
            return english
        case .spanish:
            return spanish
        case .arabic:
            return arabic
        case .portuguese:
            return portuguese
        case .russian:
            return russian
        case .japanese:
            return japanese
        case .german:
            return german
        case .french:
            return french
        }
    }
}

extension TranscriptionEngine {
    var iconName: String {
        switch self {
        case .appleSpeech:
            return "waveform.and.person.filled"
        case .whisper:
            return "sparkles"
        case .deepSpeech:
            return "archivebox"
        }
    }

    func title(language: AppLanguage) -> String {
        modelName
    }

    func subtitle(language: AppLanguage) -> String {
        switch self {
        case .appleSpeech:
            return localizedSubtitle(
                language: language,
                zhHans: "系统内置，当前可用",
                zhHant: "系統內建，目前可用",
                english: "Built in, available now",
                spanish: "Integrado, disponible ahora",
                arabic: "مدمج ومتاح الآن",
                portuguese: "Integrado, disponível agora",
                russian: "Встроено, доступно сейчас",
                japanese: "内蔵、現在利用可能",
                german: "Integriert, sofort verfügbar",
                french: "Intégré, disponible maintenant"
            )
        case .whisper:
            return localizedSubtitle(
                language: language,
                zhHans: "OpenAI Whisper，需本地运行时",
                zhHant: "OpenAI Whisper，需本地執行環境",
                english: "OpenAI Whisper, needs local runtime",
                spanish: "OpenAI Whisper, requiere runtime local",
                arabic: "OpenAI Whisper، يتطلب runtime محليًا",
                portuguese: "OpenAI Whisper, requer runtime local",
                russian: "OpenAI Whisper, нужен локальный runtime",
                japanese: "OpenAI Whisper、ローカル Runtime が必要",
                german: "OpenAI Whisper, lokale Runtime nötig",
                french: "OpenAI Whisper, runtime local requis"
            )
        case .deepSpeech:
            return localizedSubtitle(
                language: language,
                zhHans: "Mozilla DeepSpeech，已停止维护",
                zhHant: "Mozilla DeepSpeech，已停止維護",
                english: "Mozilla DeepSpeech, discontinued",
                spanish: "Mozilla DeepSpeech, descontinuado",
                arabic: "Mozilla DeepSpeech، متوقف",
                portuguese: "Mozilla DeepSpeech, descontinuado",
                russian: "Mozilla DeepSpeech, поддержка прекращена",
                japanese: "Mozilla DeepSpeech、開発終了",
                german: "Mozilla DeepSpeech, eingestellt",
                french: "Mozilla DeepSpeech, arrêté"
            )
        }
    }

    func status(language: AppLanguage) -> String {
        guard isAvailable else {
            return language.text(.requiresRuntime)
        }

        return localizedSubtitle(
            language: language,
            zhHans: "可用",
            zhHant: "可用",
            english: "Ready",
            spanish: "Listo",
            arabic: "جاهز",
            portuguese: "Pronto",
            russian: "Готово",
            japanese: "利用可",
            german: "Bereit",
            french: "Prêt"
        )
    }

    private func localizedSubtitle(
        language: AppLanguage,
        zhHans: String,
        zhHant: String,
        english: String,
        spanish: String,
        arabic: String,
        portuguese: String,
        russian: String,
        japanese: String,
        german: String,
        french: String
    ) -> String {
        switch language.resolvedLanguage {
        case .system, .simplifiedChinese:
            return zhHans
        case .traditionalChinese:
            return zhHant
        case .english:
            return english
        case .spanish:
            return spanish
        case .arabic:
            return arabic
        case .portuguese:
            return portuguese
        case .russian:
            return russian
        case .japanese:
            return japanese
        case .german:
            return german
        case .french:
            return french
        }
    }
}

private struct HistorySwipeHintView: View {
    @Environment(\.appLanguage) private var appLanguage

    let progress: CGFloat

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: progress >= 1 ? "arrow.up.circle.fill" : "arrow.up")
                .font(.system(size: 17, weight: .black))

            Text(appLanguage.text(.historySwipeHint).uppercased())
                .retroFont(size: 10, weight: .black, design: .monospaced)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .foregroundStyle(.pixelInk.opacity(0.54 + progress * 0.4))
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .scaleEffect(0.96 + progress * 0.04)
        .animation(.easeOut(duration: 0.12), value: progress)
        .accessibilityLabel(appLanguage.text(.historySwipeHint))
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var recorder = AudioRecorderViewModel()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var tagToast: RecordingTagToast?
    @GestureState private var historySwipeTranslation: CGFloat = 0
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage(InterfaceRetroFont.storageKey) private var interfaceFontRaw = InterfaceRetroFont.system.rawValue
    @AppStorage(InterfaceColorTheme.storageKey) private var interfaceColorThemeRaw = InterfaceColorTheme.pocketOlive.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRaw)
    }

    private var interfaceFont: InterfaceRetroFont {
        guard appLanguage.resolvedLanguage == .english else {
            return .system
        }

        return InterfaceRetroFont.value(for: interfaceFontRaw)
    }

    private var interfacePalette: InterfaceThemePalette {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        return InterfaceColorTheme.value(for: interfaceColorThemeRaw)
            .palette(for: UITraitCollection(userInterfaceStyle: style))
    }

    private var selectedInput: AudioInputOption? {
        recorder.inputs.first { $0.id == recorder.selectedInputID } ?? recorder.inputs.first
    }

    private var deckSourceTitle: String {
        selectedInput?.title(language: appLanguage) ?? appLanguage.text(.noSource)
    }

    private var deckSourceIconName: String {
        selectedInput?.iconName ?? "mic.slash"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveAppBackground()

                GeometryReader { proxy in
                    let isCompactHeight = proxy.size.height < 720
                    let surfaceHeight = max(0, proxy.size.height - 12)
                    let waveVisualHeight = min(
                        isCompactHeight ? 230 : 410,
                        max(
                            isCompactHeight ? 128 : 168,
                            proxy.size.height
                                - (isCompactHeight ? 438 : 420)
                                - (recorder.isRecording ? 0 : 34)
                        )
                    )

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: isCompactHeight ? 5 : 8) {
                            header

                            InputNoiseSelectorRow(
                                inputs: recorder.inputs,
                                selectedInputID: recorder.selectedInputID,
                                sourceTitle: deckSourceTitle,
                                sourceIconName: deckSourceIconName,
                                noiseReductionMode: recorder.noiseReductionMode,
                                echoCancellationMode: recorder.echoCancellationMode,
                                isEnabled: !recorder.isRecording,
                                onInputSelect: { recorder.selectInput($0) },
                                onInputRefresh: { recorder.refreshInputs() },
                                onNoiseReductionSelect: { mode in
                                    guard mode.isAvailable, !recorder.isRecording else {
                                        return
                                    }

                                    recorder.noiseReductionMode = mode
                                },
                                onEchoCancellationSelect: { mode in
                                    guard mode.isAvailable, !recorder.isRecording else {
                                        return
                                    }

                                    recorder.echoCancellationMode = mode
                                }
                            )

                            RecorderLCDPanel(
                                recorder: recorder,
                                visualHeight: waveVisualHeight
                            )

                            GameBoyBottomControlsView(
                                recorder: recorder,
                                onAddTag: addTagWithToast
                            )

                            if !recorder.isRecording {
                                HistorySwipeHintView(
                                    progress: historySwipeProgress(
                                        viewportHeight: proxy.size.height
                                    )
                                )
                            }
                        }
                        .padding(isCompactHeight ? 7 : 10)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: surfaceHeight)
                        .background(Color(interfacePalette.pixelPanel), in: PixelCornerShape(cornerRadius: 8))
                        .overlay {
                            PixelCornerShape(cornerRadius: 8)
                                .stroke(Color(interfacePalette.pixelInk), lineWidth: 3)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 6)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 16)
                            .updating($historySwipeTranslation) { value, state, _ in
                                guard !recorder.isRecording else {
                                    return
                                }

                                state = value.translation.height
                            }
                            .onEnded { value in
                                guard !recorder.isRecording else {
                                    return
                                }

                                let threshold = proxy.size.height * 0.2
                                guard value.translation.height <= -threshold else {
                                    return
                                }

                                showingHistory = true
                            }
                    )
                }
            }
            .recordingTagToast($tagToast)
            .animation(.easeOut(duration: 0.18), value: interfaceColorThemeRaw)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .environment(\.appLanguage, appLanguage)
            .environment(\.layoutDirection, appLanguage.layoutDirection)
            .environment(\.interfaceRetroFont, interfaceFont)
            .environment(\.font, interfaceFont.font(size: 15, weight: .regular))
            .navigationDestination(isPresented: $showingHistory) {
                RecordingHistoryView(recorder: recorder)
                    .environment(\.appLanguage, appLanguage)
                    .environment(\.layoutDirection, appLanguage.layoutDirection)
                    .environment(\.interfaceRetroFont, interfaceFont)
                    .environment(\.font, interfaceFont.font(size: 15, weight: .regular))
            }
            .task {
                await recorder.prepare()
                handlePendingLaunchAction()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }

                handlePendingLaunchAction()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .alert(appLanguage.text(.alertTitle), isPresented: Binding(
                get: { recorder.errorMessage != nil },
                set: { if !$0 { recorder.errorMessage = nil } }
            )) {
                Button(appLanguage.text(.ok), role: .cancel) {
                    recorder.errorMessage = nil
                }
            } message: {
                Text(recorder.errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(recorder: recorder)
            }
            .fullScreenCover(item: $recorder.reviewRecording) { recording in
                RecordingPlaybackView(recording: recording, recorder: recorder)
                    .environment(\.appLanguage, appLanguage)
                    .environment(\.layoutDirection, appLanguage.layoutDirection)
                    .environment(\.interfaceRetroFont, interfaceFont)
                    .environment(\.font, interfaceFont.font(size: 15, weight: .regular))
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let action = AppDeepLink.action(for: url) else {
            return
        }

        handleLaunchAction(AppLaunchAction(deepLinkAction: action))
    }

    private func handlePendingLaunchAction() {
        guard let action = AppLaunchActionStore.consumePendingAction() else {
            return
        }

        handleLaunchAction(action)
    }

    private func handleLaunchAction(_ action: AppLaunchAction) {
        switch action {
        case .record:
            startRecordingFromExternalTrigger()
        case .history:
            showingSettings = false
            recorder.reviewRecording = nil
            showingHistory = true
        }
    }

    private func startRecordingFromExternalTrigger() {
        showingSettings = false
        showingHistory = false
        recorder.reviewRecording = nil

        Task {
            await recorder.prepare()

            guard !recorder.isRecording else {
                return
            }

            await recorder.startRecording()
        }
    }

    private func addTagWithToast() {
        guard let result = recorder.addTagAtCurrentRecordingTime() else {
            return
        }

        showTagToast(result)
    }

    private func showTagToast(_ result: RecordingTagAddResult) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            tagToast = RecordingTagToast(result: result)
        }
    }

    private func historySwipeProgress(viewportHeight: CGFloat) -> CGFloat {
        let threshold = max(1, viewportHeight * 0.2)
        return min(1, max(0, -historySwipeTranslation / threshold))
    }

    private var header: some View {
        HStack(spacing: 8) {
            headerButton(systemName: "list.bullet.rectangle") {
                showingSettings = false
                recorder.reviewRecording = nil
                showingHistory = true
            }

            Text("RETRO REC")
                .retroFont(size: 20, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)

            headerButton(systemName: "gearshape.fill") {
                showingSettings = true
            }
        }
        .padding(.horizontal, 7)
        .frame(height: 42)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }

    private func headerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.pixelInk)
                .frame(width: 34, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sourceMenuTitle(for input: AudioInputOption) -> String {
        let selectedPrefix = input.id == recorder.selectedInputID ? "✓ " : ""
        return selectedPrefix + input.title(language: appLanguage) + " · " + input.subtitle(language: appLanguage)
    }
}

private struct InputNoiseSelectorRow: View {
    @Environment(\.appLanguage) private var appLanguage

    let inputs: [AudioInputOption]
    let selectedInputID: AudioInputOption.ID?
    let sourceTitle: String
    let sourceIconName: String
    let noiseReductionMode: NoiseReductionMode
    let echoCancellationMode: EchoCancellationMode
    let isEnabled: Bool
    let onInputSelect: (AudioInputOption) -> Void
    let onInputRefresh: () -> Void
    let onNoiseReductionSelect: (NoiseReductionMode) -> Void
    let onEchoCancellationSelect: (EchoCancellationMode) -> Void

    var body: some View {
        HStack(spacing: 5) {
            inputMenu
                .frame(maxWidth: .infinity, minHeight: 0)
            noiseReductionMenu
                .frame(maxWidth: .infinity, minHeight: 0)
            echoCancellationMenu
                .frame(maxWidth: .infinity, minHeight: 0)
        }
        .padding(4)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }

    private var inputMenu: some View {
        PixelDropdownPanel(label: "INPUT") {
            Menu {
                ForEach(inputs) { input in
                    Button(inputMenuTitle(for: input)) {
                        onInputSelect(input)
                    }
                }

                Button(appLanguage.text(.refreshSource)) {
                    onInputRefresh()
                }
            } label: {
                dropdownLabel(systemName: sourceIconName, title: sourceTitle, isEnabled: isEnabled)
            }
            .disabled(!isEnabled)
        }
    }

    private var noiseReductionMenu: some View {
        PixelDropdownPanel(label: "NR") {
            Menu {
                ForEach(NoiseReductionMode.allCases) { mode in
                    Button(noiseReductionMenuTitle(for: mode)) {
                        guard mode.isAvailable else {
                            return
                        }

                        onNoiseReductionSelect(mode)
                    }
                    .disabled(!mode.isAvailable)
                }
            } label: {
                dropdownLabel(
                    systemName: noiseReductionMode.iconName,
                    title: noiseReductionMode.title(language: appLanguage),
                    isEnabled: isEnabled
                )
            }
            .disabled(!isEnabled)
        }
    }

    private var echoCancellationMenu: some View {
        PixelDropdownPanel(label: "AEC") {
            Menu {
                ForEach(EchoCancellationMode.allCases) { mode in
                    Button(echoCancellationMenuTitle(for: mode)) {
                        guard mode.isAvailable else {
                            return
                        }

                        onEchoCancellationSelect(mode)
                    }
                    .disabled(!mode.isAvailable)
                }
            } label: {
                dropdownLabel(
                    systemName: echoCancellationMode.iconName,
                    title: echoCancellationMode.title(language: appLanguage),
                    isEnabled: isEnabled
                )
            }
            .disabled(!isEnabled)
        }
    }

    private func dropdownLabel(systemName: String, title: String, isEnabled: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .black))
                .frame(width: 10)

            Text(title)
                .retroFont(size: 9, weight: .black, design: .monospaced)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 2)

            Image(systemName: "chevron.down")
                .font(.system(size: 7, weight: .black))
        }
        .foregroundStyle(isEnabled ? .pixelInk : .pixelInk.opacity(0.42))
        .padding(.horizontal, 3)
        .frame(height: 19)
    }

    private func inputMenuTitle(for input: AudioInputOption) -> String {
        let selectedPrefix = input.id == selectedInputID ? "✓ " : ""
        return selectedPrefix + input.title(language: appLanguage)
    }

    private func noiseReductionMenuTitle(for mode: NoiseReductionMode) -> String {
        let selectedPrefix = mode == noiseReductionMode ? "✓ " : ""
        return selectedPrefix + mode.title(language: appLanguage)
    }

    private func echoCancellationMenuTitle(for mode: EchoCancellationMode) -> String {
        let selectedPrefix = mode == echoCancellationMode ? "✓ " : ""
        return selectedPrefix + mode.title(language: appLanguage) + " · " + mode.subtitle(language: appLanguage)
    }
}

private struct PixelDropdownPanel<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .retroFont(size: 7, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.62))
                .lineLimit(1)

            content
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RecorderLCDPanel: View {
    @Environment(\.appLanguage) private var appLanguage
    @ObservedObject var recorder: AudioRecorderViewModel

    let visualHeight: CGFloat

    private var liveText: String {
        guard recorder.isRecording else {
            return ""
        }

        return recorder.liveTranscript.isEmpty ? appLanguage.text(.liveTextPlaceholder) : recorder.liveTranscript
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(recorder.isRecording ? (recorder.isPaused ? "PAUSE" : "REC") : "STANDBY")
                    .foregroundStyle(recorder.isRecording && !recorder.isPaused ? .pixelRed : .pixelInk)

                Spacer(minLength: 6)

                Text(recorder.recordingQualityText.uppercased())
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text("CH 1/2")
                    .opacity(0.62)
            }
            .retroFont(size: 9, weight: .black, design: .monospaced)
            .foregroundStyle(.pixelInk)

            RealtimeWaveformDeckView(
                isRecording: recorder.isRecording,
                isPaused: recorder.isPaused,
                elapsed: recorder.elapsed,
                levels: recorder.waveformLevels,
                frequencyLevels: recorder.frequencyLevels,
                instantaneousFrequencyLevels: recorder.instantaneousFrequencyLevels,
                liveSamples: recorder.liveWaveformSamples,
                shadertoySpectrum: recorder.shadertoySpectrumLevels,
                shadertoyWaveform: recorder.shadertoyWaveformSamples,
                liveText: liveText,
                isLiveTextActive: recorder.isRecording && !recorder.isPaused,
                audioQualityText: recorder.recordingQualityText,
                canAddTag: recorder.isRecording,
                currentTagTimeText: RecordingItem.format(recorder.elapsed),
                hasCurrentTag: recorder.hasTagAtCurrentRecordingTime,
                visualHeight: visualHeight,
                onAddTag: {
                    recorder.addTagAtCurrentRecordingTime()
                }
            )

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(recorder.isRecording ? RecordingItem.format(recorder.elapsed) : " ")
                    .retroFont(size: 27, weight: .black, design: .monospaced)
                    .lineLimit(1)
                    .frame(minHeight: 32)

                Spacer(minLength: 4)

                Text(recorder.isRecording ? (recorder.isPaused ? "HOLD" : "LIVE") : "READY")
                    .retroFont(size: 10, weight: .black, design: .monospaced)
                    .opacity(0.62)
            }
            .foregroundStyle(.pixelInk)

            LiveTranscriptPanel(
                text: liveText,
                isActive: recorder.isRecording && !recorder.isPaused,
                canAddTag: recorder.isRecording,
                currentTagTimeText: RecordingItem.format(recorder.elapsed),
                hasCurrentTag: recorder.hasTagAtCurrentRecordingTime,
                onAddTag: recorder.addTagAtCurrentRecordingTime
            )
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 3)
        }
    }
}

private struct RecordingQualityPill: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .retroFont(size: 10, weight: .black, design: .monospaced)
            .foregroundStyle(.pixelInk)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, 12)
            .frame(height: 22)
            .background(Color.pixelPaper.opacity(0.86), in: PixelCornerShape(cornerRadius: 6))
            .overlay {
                PixelCornerShape(cornerRadius: 6)
                    .stroke(.pixelInk, lineWidth: 2)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                PixelSpeakerGrille()
                    .frame(width: 28, height: 18)
                    .opacity(0.22)
                    .padding(.leading, 14)
            }
            .overlay(alignment: .trailing) {
                PixelSpeakerGrille()
                    .frame(width: 28, height: 18)
                    .opacity(0.22)
                    .padding(.trailing, 14)
            }
    }
}

private struct LiveTranscriptPanel: View {
    @Environment(\.appLanguage) private var appLanguage
    @State private var showingFullText = false

    let text: String
    let isActive: Bool
    var canAddTag = false
    var currentTagTimeText = "00:00"
    var hasCurrentTag = false
    var onAddTag: () -> RecordingTagAddResult? = { nil }

    private var displayText: String {
        text.isEmpty ? " " : text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(appLanguage.text(.liveText).uppercased())
                    .retroFont(size: 11, weight: .black, design: .monospaced)

                Spacer()

                if isActive {
                    PixelBlinkDot()
                }

                Button {
                    showingFullText = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.pixelInk)
                        .frame(width: 24, height: 18)
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
            }
            .foregroundStyle(.pixelInk)

            Text(displayText)
                .retroFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.pixelPaper, in: PixelCornerShape(cornerRadius: 4))
                .overlay {
                    PixelCornerShape(cornerRadius: 4)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 3]))
                        .foregroundStyle(.pixelInk)
                }
        }
        .padding(.horizontal, 1)
        .sheet(isPresented: $showingFullText) {
            MainLiveTextDetailSheet(
                title: appLanguage.text(.liveText),
                text: text,
                canAddTag: canAddTag,
                currentTagTimeText: currentTagTimeText,
                hasCurrentTag: hasCurrentTag,
                onAddTag: onAddTag
            )
        }
    }
}

private struct MainLiveTextDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage
    @State private var tagToast: RecordingTagToast?

    let title: String
    let text: String
    let canAddTag: Bool
    let currentTagTimeText: String
    let hasCurrentTag: Bool
    let onAddTag: () -> RecordingTagAddResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text.isEmpty ? " " : text)
                    .retroFont(size: 17, weight: .regular, design: .monospaced)
                    .lineSpacing(5)
                    .foregroundStyle(.pixelInk)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }
            .background(Color.pixelPaper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if canAddTag {
                    Button {
                        addCurrentTag()
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: hasCurrentTag ? "tag.fill" : "tag")
                                .font(.system(size: 15, weight: .black))

                            Text("TAG \(currentTagTimeText)")
                                .retroFont(size: 15, weight: .black, design: .monospaced)
                        }
                        .foregroundStyle(Color.pixelPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.pixelInk, in: PixelCornerShape(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.pixelPanel.opacity(0.96))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(.done)) {
                        dismiss()
                    }
                }
            }
        }
        .environment(\.appLanguage, appLanguage)
        .recordingTagToast($tagToast)
    }

    private func addCurrentTag() {
        guard let result = onAddTag() else {
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            tagToast = RecordingTagToast(result: result)
        }
    }
}

private struct GameBoyBottomControlsView: View {
    @ObservedObject var recorder: AudioRecorderViewModel
    let onAddTag: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if recorder.isRecording {
                HStack(spacing: 8) {
                    compactControlButton(
                        title: recorder.isPaused ? "REC" : "PAUSE",
                        systemName: recorder.isPaused ? "play.fill" : "pause.fill"
                    ) {
                        recorder.pauseOrResumeRecording()
                    }

                    compactControlButton(title: "STOP", systemName: "stop.fill") {
                        recorder.stopRecording()
                    }

                    compactControlButton(
                        title: "TAG",
                        systemName: recorder.hasTagAtCurrentRecordingTime ? "tag.fill" : "tag"
                    ) {
                        onAddTag()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
            } else {
                startButton
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: recorder.isRecording ? 76 : 110)
    }

    private var startButton: some View {
        Button {
            Task {
                await recorder.startRecording()
            }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(.pixelInk)
                        .frame(width: 84, height: 84)
                        .shadow(color: .black.opacity(0.24), radius: 0, x: 3, y: 4)

                    Circle()
                        .fill(.pixelPaper)
                        .frame(width: 72, height: 72)

                    Circle()
                        .stroke(.pixelInk.opacity(0.7), lineWidth: 3)
                        .frame(width: 68, height: 68)

                    Circle()
                        .fill(.pixelRed)
                        .frame(width: 56, height: 56)
                        .overlay {
                            Circle()
                                .stroke(.pixelInk.opacity(0.48), lineWidth: 2)
                        }
                }
                .frame(width: 88, height: 88)

                Text("START REC")
                    .retroFont(size: 13, weight: .black, design: .monospaced)
            }
            .foregroundStyle(.pixelInk)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PixelRecordButtonStyle())
        .accessibilityLabel("Start recording")
    }

    private func compactControlButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 46, height: 38)
                    .background(Color.pixelPaper, in: PixelCornerShape(cornerRadius: 4))
                    .overlay {
                        PixelCornerShape(cornerRadius: 4)
                            .stroke(.pixelInk, lineWidth: 2)
                    }

                Text(title)
                    .retroFont(size: 8, weight: .black, design: .monospaced)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .foregroundStyle(.pixelInk)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct PixelRecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PixelBlinkDot: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let isOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0

            Rectangle()
                .fill(isOn ? Color.pixelInk : Color.pixelInk.opacity(0.18))
                .frame(width: 9, height: 9)
        }
    }
}

struct RecordingTagToast: Identifiable, Equatable {
    let id = UUID()
    let result: RecordingTagAddResult
}

extension RecordingTagAddResult {
    func toastMessage(language: AppLanguage) -> String {
        let timeText = RecordingItem.format(TimeInterval(second))

        switch self {
        case .added:
            switch language.resolvedLanguage {
            case .system, .simplifiedChinese:
                return "已添加标签 \(timeText)"
            case .traditionalChinese:
                return "已新增標籤 \(timeText)"
            case .english:
                return "Tag added at \(timeText)"
            case .spanish:
                return "Etiqueta añadida \(timeText)"
            case .arabic:
                return "تمت إضافة الوسم \(timeText)"
            case .portuguese:
                return "Tag adicionada em \(timeText)"
            case .russian:
                return "Метка добавлена \(timeText)"
            case .japanese:
                return "タグを追加 \(timeText)"
            case .german:
                return "Tag gesetzt bei \(timeText)"
            case .french:
                return "Tag ajouté à \(timeText)"
            }
        case .alreadyExists:
            switch language.resolvedLanguage {
            case .system, .simplifiedChinese:
                return "该时间点已有标签 \(timeText)"
            case .traditionalChinese:
                return "此時間點已有標籤 \(timeText)"
            case .english:
                return "Tag already exists at \(timeText)"
            case .spanish:
                return "Ya hay etiqueta en \(timeText)"
            case .arabic:
                return "يوجد وسم بالفعل عند \(timeText)"
            case .portuguese:
                return "Tag já existe em \(timeText)"
            case .russian:
                return "Метка уже есть \(timeText)"
            case .japanese:
                return "この時刻にはタグがあります \(timeText)"
            case .german:
                return "Tag existiert schon bei \(timeText)"
            case .french:
                return "Tag déjà présent à \(timeText)"
            }
        }
    }
}

struct RecordingTagToastBanner: View {
    @Environment(\.appLanguage) private var appLanguage

    let toast: RecordingTagToast

    var body: some View {
        Label {
            Text(toast.result.toastMessage(language: appLanguage))
                .retroFont(size: 14, weight: .black, design: .monospaced)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: toast.result.isAdded ? "tag.fill" : "tag")
                .font(.system(size: 16, weight: .black))
        }
        .foregroundStyle(toast.result.isAdded ? Color.pixelPaper : Color.pixelInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(toast.result.isAdded ? Color.pixelInk : Color.pixelPanel, in: PixelCornerShape(cornerRadius: 5))
        .overlay {
            PixelCornerShape(cornerRadius: 5)
                .stroke(Color.pixelInk, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.16), radius: 0, x: 3, y: 3)
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }
}

private struct RecordingTagToastModifier: ViewModifier {
    @Binding var toast: RecordingTagToast?
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    RecordingTagToastBanner(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .onChange(of: toast?.id) { _, newID in
                dismissTask?.cancel()

                guard newID != nil else {
                    return
                }

                dismissTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)

                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.18)) {
                            toast = nil
                        }
                    }
                }
            }
    }
}

private struct TransportControlsView: View {
    @ObservedObject var recorder: AudioRecorderViewModel
    let onAddTag: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: recorder.isRecording ? 12 : 0) {
                if recorder.isRecording {
                    PixelTransportButton(
                        title: recorder.isPaused ? "REC" : "PAUSE",
                        systemName: recorder.isPaused ? "play.fill" : "pause.fill",
                        accent: .pixelInk
                    ) {
                        recorder.pauseOrResumeRecording()
                    }

                    PixelTransportButton(
                        title: "STOP",
                        systemName: "stop.fill",
                        accent: .pixelInk
                    ) {
                        recorder.stopRecording()
                    }

                    PixelTransportButton(
                        title: "TAG",
                        systemName: recorder.hasTagAtCurrentRecordingTime ? "tag.fill" : "tag",
                        accent: .pixelInk
                    ) {
                        onAddTag()
                    }
                } else {
                    Button {
                        Task {
                            await recorder.startRecording()
                        }
                    } label: {
                        ZStack {
                            HStack {
                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .rotationEffect(.degrees(-90))
                                    .opacity(0.78)

                                Spacer()

                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .rotationEffect(.degrees(90))
                                    .opacity(0.78)
                            }
                            .foregroundStyle(.pixelPaper)
                            .padding(.horizontal, 22)

                            VStack(spacing: 7) {
                                Rectangle()
                                    .fill(.pixelInk)
                                    .frame(width: 25, height: 25)
                                    .clipShape(PixelCornerShape(cornerRadius: 5))

                                Text("START\nREC")
                                    .retroFont(size: 20, weight: .black, design: .monospaced)
                                    .foregroundStyle(.pixelInk)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(0)
                            }
                            .frame(width: 142, height: 118)
                            .background(Color.pixelPaper, in: PixelCornerShape(cornerRadius: 18))
                            .overlay {
                                PixelCornerShape(cornerRadius: 18)
                                    .stroke(.pixelInk, lineWidth: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(Color.pixelInk.opacity(0.54), in: PixelCornerShape(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                }
            }

            if recorder.isRecording, let statusText = recorder.liveActivityStatusText {
                Text(statusText)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(0.68))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .pixelPanel()
    }
}

private struct PixelTransportButton: View {
    let title: String
    let systemName: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 25, weight: .black))
                    .frame(width: 58, height: 52)
                    .background(Color.pixelPaper, in: PixelCornerShape(cornerRadius: 4))
                    .overlay {
                        PixelCornerShape(cornerRadius: 4)
                            .stroke(accent, lineWidth: 2)
                    }

                Text(title)
                    .retroFont(size: 18, weight: .black, design: .monospaced)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct PixelCornerShape: Shape {
    var cornerRadius: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width, rect.height) / 3)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.closeSubpath()

        return path
    }
}

private struct PixelPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.pixelPanel, in: PixelCornerShape(cornerRadius: 6))
            .overlay {
                LCDTextureOverlay(opacity: 0.055)
                    .clipShape(PixelCornerShape(cornerRadius: 6))
                    .allowsHitTesting(false)
            }
            .overlay {
                PixelCornerShape(cornerRadius: 6)
                    .stroke(.pixelInk, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.06), radius: 0, x: 3, y: 3)
    }
}

private struct AdaptiveAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(InterfaceColorTheme.storageKey) private var interfaceColorThemeRaw = InterfaceColorTheme.pocketOlive.rawValue

    private var palette: InterfaceThemePalette {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        return InterfaceColorTheme.value(for: interfaceColorThemeRaw)
            .palette(for: UITraitCollection(userInterfaceStyle: style))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(palette.appBackgroundTop),
                    Color(palette.appBackgroundMiddle),
                    Color(palette.appBackgroundBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LCDTextureOverlay(opacity: 0.11, inkColor: Color(palette.pixelInk))
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

private struct LCDTextureOverlay: View {
    var opacity: Double
    var inkColor: Color = .pixelInk

    var body: some View {
        Canvas { context, size in
            let lineStep: CGFloat = 4
            var y: CGFloat = 0

            while y < size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(inkColor.opacity(opacity)), lineWidth: 1)
                y += lineStep
            }

            let dotStep: CGFloat = 9
            var dotY: CGFloat = 2
            while dotY < size.height {
                var dotX: CGFloat = 2
                while dotX < size.width {
                    let rect = CGRect(x: dotX, y: dotY, width: 1, height: 1)
                    context.fill(Path(rect), with: .color(inkColor.opacity(opacity * 0.6)))
                    dotX += dotStep
                }
                dotY += dotStep
            }
        }
    }
}

private struct PixelSpeakerGrille: View {
    var body: some View {
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<5, id: \.self) { row in
                GridRow {
                    ForEach(0..<5, id: \.self) { column in
                        let distance = abs(row - 2) + abs(column - 2)
                        Rectangle()
                            .fill(Color.pixelInk.opacity(distance <= 3 ? 0.84 : 0.0))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}

private extension View {
    func pixelPanel() -> some View {
        modifier(PixelPanelModifier())
    }
}

private struct RecordingOptionsView: View {
    @Environment(\.appLanguage) private var appLanguage

    @ObservedObject var recorder: AudioRecorderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                sectionHeader(appLanguage.text(.noiseReduction))

                Spacer()

                Text(title(for: recorder.noiseReductionMode))
                    .font(.caption.weight(.black))
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(NoiseReductionMode.allCases) { mode in
                    Button {
                        guard mode.isAvailable else {
                            return
                        }

                        recorder.noiseReductionMode = mode
                    } label: {
                        NoiseReductionModeRow(
                            mode: mode,
                            title: title(for: mode),
                            subtitle: subtitle(for: mode),
                            isSelected: recorder.noiseReductionMode == mode,
                            isEnabled: mode.isAvailable && !recorder.isRecording
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!mode.isAvailable || recorder.isRecording)
                }
            }
        }
        .disabled(recorder.isRecording)
        .opacity(recorder.isRecording ? 0.62 : 1)
    }

    private func title(for mode: NoiseReductionMode) -> String {
        switch mode {
        case .off:
            return appLanguage.text(.noiseReductionOff)
        case .rnnoise:
            return appLanguage.text(.rnnoiseTitle)
        case .deepFilterNetV3:
            return appLanguage.text(.deepFilterNetV3Title)
        case .dtln:
            return appLanguage.text(.dtlnTitle)
        }
    }

    private func subtitle(for mode: NoiseReductionMode) -> String {
        guard mode.isAvailable else {
            return appLanguage.text(.requiresRuntime)
        }

        switch mode {
        case .off:
            return appLanguage.text(.noiseReductionOffSubtitle)
        case .rnnoise:
            return appLanguage.text(.rnnoiseSubtitle)
        case .deepFilterNetV3:
            return appLanguage.text(.deepFilterNetV3Subtitle)
        case .dtln:
            return appLanguage.text(.dtlnSubtitle)
        }
    }
}

private struct NoiseReductionModeRow: View {
    let mode: NoiseReductionMode
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isEnabled: Bool

    private var iconName: String {
        switch mode {
        case .off:
            return "waveform.slash"
        case .rnnoise:
            return "waveform.badge.magnifyingglass"
        case .deepFilterNetV3:
            return "brain.head.profile"
        case .dtln:
            return "cpu"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : (isEnabled ? 0.72 : 0.34)))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(isEnabled ? 1 : 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.pixelInk.opacity(isEnabled ? 0.56 : 0.32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 4)

            Image(systemName: isSelected ? "checkmark.circle.fill" : (isEnabled ? "circle" : "lock.fill"))
                .font(.caption.weight(.black))
                .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : (isEnabled ? 0.32 : 0.24)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(minHeight: 66)
        .background(Color.pixelPanel.opacity(isSelected ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
        .overlay {
            PixelCornerShape(cornerRadius: 6)
                .stroke(.pixelInk.opacity(isSelected ? 0.84 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
    }
}

private struct RecordingLibraryView: View {
    @Environment(\.appLanguage) private var appLanguage

    @ObservedObject var recorder: AudioRecorderViewModel

    var body: some View {
        NavigationLink {
            RecordingHistoryView(recorder: recorder)
        } label: {
            HStack(spacing: 10) {
                Text("HISTORY")
                    .retroFont(size: 21, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk)

                Spacer()

                Text(recorder.recordings.isEmpty ? appLanguage.text(.noRecordings) : "\(recorder.recordings.count)")
                    .retroFont(size: 14, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.pixelInk)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .pixelPanel()
        }
        .buttonStyle(.plain)
    }
}

private struct RecordingRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let recording: RecordingItem
    @ObservedObject var recorder: AudioRecorderViewModel
    var isSelectionMode = false
    var isSelected = false
    var onToggleSelection: () -> Void = {}
    var onDelete: () -> Void = {}
    var onOpenFullscreen: () -> Void = {}

    @State private var isExpanded = false
    @State private var showingLanguagePicker = false
    @State private var showingRenamePrompt = false
    @State private var showingDetails = false
    @State private var renameText = ""

    private var primaryTitle: String {
        recording.title
    }

    private var durationDisplayText: String {
        guard recorder.playingRecordingID == recording.id else {
            return recording.durationText
        }

        let elapsed = min(max(0, recorder.playbackElapsed), max(0, recording.duration))
        return "\(RecordingItem.format(elapsed))/\(recording.durationText)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if isSelectionMode {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.title3.weight(.black))
                            .foregroundStyle(isSelected ? .pixelInk : .pixelInk.opacity(0.42))
                    }
                    .buttonStyle(.plain)
                } else if !isExpanded {
                    rowIconButton(
                        systemName: recorder.playingRecordingID == recording.id ? "stop.fill" : "play.fill",
                        tint: .pixelInk
                    ) {
                        recorder.play(recording)
                    }
                }

                Button {
                    if isSelectionMode {
                        onToggleSelection()
                    } else {
                        toggleExpanded()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(primaryTitle)
                            .retroFont(size: 15, weight: .black, design: .monospaced)
                            .foregroundStyle(.pixelInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)

                        HStack(spacing: 7) {
                            InfoTag(systemName: "timer", text: durationDisplayText)

                            Text(recording.subtitle)
                                .retroFont(size: 10, weight: .bold, design: .monospaced)
                                .foregroundStyle(.pixelInk.opacity(0.52))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !isSelectionMode {
                    if isExpanded {
                        rowIconButton(systemName: "pencil", tint: .pixelInk.opacity(0.82)) {
                            renameText = recording.title
                            showingRenamePrompt = true
                        }
                    }

                    rowIconButton(systemName: "arrow.up.left.and.arrow.down.right", tint: .pixelInk.opacity(0.82)) {
                        onOpenFullscreen()
                    }

                    rowIconButton(systemName: "chevron.down", tint: .pixelInk.opacity(0.62)) {
                        toggleExpanded()
                    }
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }

            if isExpanded && !isSelectionMode {
                VStack(alignment: .leading, spacing: 8) {
                    MiniPixelWaveformStrip(
                        seed: recording.id.absoluteString,
                        isPlaying: recorder.playingRecordingID == recording.id
                    )
                    .frame(height: 34)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            Button {
                                recorder.play(recording)
                            } label: {
                                DetailActionButton(
                                    systemName: recorder.playingRecordingID == recording.id ? "stop.circle.fill" : "play.circle.fill",
                                    title: recorder.playingRecordingID == recording.id ? "STOP" : "PLAY",
                                    tint: .pixelInk
                                )
                            }
                            .buttonStyle(.plain)

                            if recorder.transcribingRecordingID == recording.id {
                                ProgressView()
                                    .tint(.pixelInk)
                                    .frame(width: 62, height: 54)
                            } else {
                                Button {
                                    Task {
                                        await recorder.transcribe(recording)
                                    }
                                } label: {
                                    DetailActionButton(
                                        systemName: "text.viewfinder",
                                        title: appLanguage.text(.transcribe),
                                        tint: .pixelInk
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                showingDetails = true
                            } label: {
                                DetailActionButton(
                                    systemName: "info.circle",
                                    title: "DETAIL",
                                    tint: .pixelInk
                                )
                            }
                            .buttonStyle(.plain)

                            ShareLink(item: recording.url) {
                                DetailActionButton(
                                    systemName: "square.and.arrow.up",
                                    title: appLanguage.text(.share),
                                    tint: .pixelInk
                                )
                            }

                            Button {
                                onDelete()
                            } label: {
                                DetailActionButton(
                                    systemName: "trash.fill",
                                    title: appLanguage.text(.delete),
                                    tint: .pixelInk
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 7) {
                        InfoTag(systemName: "textformat.size", text: appLanguage.format(.characterCountFormat, recording.transcriptCharacterCount))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    transcriptView
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isExpanded ? 11 : 9)
        .background(isExpanded ? Color.pixelPanel.opacity(0.42) : Color.pixelPaper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.pixelInk.opacity(0.58))
                .frame(height: 2)
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(recorder: recorder, recording: recording)
        }
        .sheet(isPresented: $showingDetails) {
            RecordingDetailsView(recording: recording)
        }
        .alert("编辑录音名称", isPresented: $showingRenamePrompt) {
            TextField("录音名称", text: $renameText)

            Button("保存") {
                recorder.renameRecording(recording, to: renameText)
            }

            Button("取消", role: .cancel) {}
        } message: {
            Text("修改后将覆盖当前录音名称。")
        }
        .onAppear {
            isExpanded = false
        }
    }

    private func toggleExpanded() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            isExpanded.toggle()
        }
    }

    private func rowIconButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var transcriptView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(appLanguage.text(.transcript))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.pixelInk.opacity(0.58))

                Spacer()

                Button {
                    showingLanguagePicker = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "globe")
                            .font(.headline.weight(.semibold))

                        Text(recorder.languageTitle(for: recording))
                            .retroFont(size: 9, weight: .black, design: .monospaced)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.55)
                    }
                    .frame(maxWidth: 126, alignment: .trailing)
                    .foregroundStyle(.pixelInk)
                }
                .buttonStyle(.plain)

                if let transcript = recording.transcript {
                    Button {
                        UIPasteboard.general.string = transcript
                        recorder.markTranscriptCopied(recording)
                    } label: {
                        Image(systemName: recorder.copiedRecordingID == recording.id ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.pixelInk)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appLanguage.text(.copyText))
                }
            }

            if let transcript = recording.transcript {
                Text(transcript)
                    .retroFont(size: 13, weight: .semibold, design: .monospaced)
                    .foregroundStyle(.pixelInk.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 2)
    }
}

private struct DetailActionButton: View {
    let systemName: String
    let title: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .frame(height: 22)

            Text(title)
                .retroFont(size: 9, weight: .black, design: .monospaced)
                .lineLimit(1)
                .minimumScaleFactor(0.52)
                .frame(width: 54)
        }
        .foregroundStyle(tint)
        .frame(width: 62, height: 54)
    }
}

private struct RecordingDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let recording: RecordingItem

    private var metadata: RecordingMetadata {
        recording.metadata
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveAppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        detailSection("RAW RECORDING") {
                            detailRow("FILE", recording.url.lastPathComponent)
                            detailRow("NAME", recording.title)
                            detailRow("DURATION", recording.durationText)
                            detailRow("RECORDED", dateText(metadata.recordedAt ?? recording.createdAt))
                        }

                        detailSection("LOCATION") {
                            if let location = metadata.location {
                                detailRow("ADDRESS", location.address ?? "Unavailable")
                                detailRow(
                                    "COORDINATES",
                                    String(format: "%.6f, %.6f", location.latitude, location.longitude)
                                )

                                if let altitude = location.altitude {
                                    detailRow("ALTITUDE", String(format: "%.1f m", altitude))
                                }

                                if let accuracy = location.horizontalAccuracy {
                                    detailRow("ACCURACY", String(format: "± %.1f m", accuracy))
                                }

                                if let timestamp = location.timestamp {
                                    detailRow("LOCATION TIME", dateText(timestamp))
                                }
                            } else {
                                detailRow("STATUS", "No location saved")
                            }
                        }

                        detailSection("AUDIO PARAMETERS") {
                            detailRow("FORMAT", metadata.fileFormat ?? "Unavailable")
                            detailRow("SAMPLE RATE", sampleRateText(metadata.sampleRate))
                            detailRow("BIT DEPTH", metadata.bitDepth.map { "\($0)-bit" } ?? "Unavailable")
                            detailRow("CHANNELS", metadata.channelCount.map(String.init) ?? "Unavailable")
                        }

                        detailSection("INPUT DEVICE") {
                            detailRow("DEVICE", metadata.inputName ?? "Unavailable")
                            detailRow("PORT", metadata.inputPortType ?? "Unavailable")
                            detailRow("UID", metadata.inputUID ?? "Unavailable")
                        }

                        detailSection("PROCESSING") {
                            detailRow("NOISE REDUCTION", metadata.noiseReductionMode ?? "Unavailable")
                            detailRow("ECHO CANCELLATION", metadata.echoCancellationMode ?? "Unavailable")
                        }

                        detailSection("ENCODING") {
                            detailRow("ENCODER", metadata.encoding ?? "Unavailable")
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("RECORDING DETAIL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .retroFont(size: 11, weight: .black, design: .monospaced)
                }
            }
        }
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .retroFont(size: 11, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.7))
                .padding(.bottom, 7)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.pixelPaper.opacity(0.72), in: PixelCornerShape(cornerRadius: 5))
            .overlay {
                PixelCornerShape(cornerRadius: 5)
                    .stroke(.pixelInk.opacity(0.22), lineWidth: 1)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .retroFont(size: 9, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.52))
                .frame(width: 106, alignment: .leading)

            Text(value)
                .retroFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.pixelInk.opacity(0.1))
                .frame(height: 1)
        }
    }

    private func dateText(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func sampleRateText(_ sampleRate: Double?) -> String {
        guard let sampleRate else {
            return "Unavailable"
        }

        return sampleRate.rounded() == sampleRate
            ? "\(Int(sampleRate)) Hz"
            : String(format: "%.2f Hz", sampleRate)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

private struct MiniPixelWaveformStrip: View {
    let seed: String
    let isPlaying: Bool

    private var levels: [Double] {
        let scalars = Array(seed.unicodeScalars).map { Int($0.value) }
        let base = scalars.reduce(17) { ($0 * 31 + $1) % 997 }

        return (0..<42).map { index in
            let value = (base + index * 37 + (index * index * 11)) % 100
            return 0.18 + Double(value) / 130.0
        }
    }

    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 3
            let gap: CGFloat = 3
            let step = cell + gap
            let midY = size.height * 0.5
            let maxRows = max(2, Int(size.height / step / 2))

            for index in levels.indices {
                let x = CGFloat(index) * step
                guard x < size.width else {
                    continue
                }

                let level = levels[index]
                let rows = max(1, Int((level * Double(maxRows)).rounded(.up)))

                for offset in -rows...rows {
                    let y = midY + CGFloat(offset) * step
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    let opacity = isPlaying ? 0.86 : 0.48
                    context.fill(Path(rect), with: .color(.pixelInk.opacity(opacity)))
                }
            }
        }
        .background(Color.pixelPanel.opacity(0.35))
        .overlay {
            Rectangle()
                .stroke(.pixelInk.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct RecordingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    @ObservedObject var recorder: AudioRecorderViewModel
    @State private var isSelectionMode = false
    @State private var selectedRecordingIDs: Set<RecordingItem.ID> = []
    @State private var fullScreenRecording: RecordingItem?
    @State private var showingShareSheet = false
    @State private var shareURLs: [URL] = []

    var body: some View {
        ZStack {
            AdaptiveAppBackground()

            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 8) {
                    historyHeader

                    Group {
                        if recorder.recordings.isEmpty {
                            VStack(spacing: 12) {
                                PixelSpeakerGrille()
                                    .frame(width: 64, height: 52)
                                    .opacity(0.44)

                                Text(appLanguage.text(.noRecordings).uppercased())
                                    .retroFont(size: 14, weight: .black, design: .monospaced)
                                    .foregroundStyle(.pixelInk.opacity(0.62))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(recorder.recordings) { recording in
                                        RecordingRowView(
                                            recording: recording,
                                            recorder: recorder,
                                            isSelectionMode: isSelectionMode,
                                            isSelected: selectedRecordingIDs.contains(recording.id),
                                            onToggleSelection: {
                                                toggleSelection(for: recording)
                                            },
                                            onDelete: {
                                                recorder.delete(recording)
                                                selectedRecordingIDs.remove(recording.id)
                                            },
                                            onOpenFullscreen: {
                                                openFullScreenPlayback(recording)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pixelPaper)
                    .overlay {
                        Rectangle()
                            .stroke(.pixelInk, lineWidth: 3)
                    }

                    historyFooter
                }
                .padding(9)
                .frame(
                    width: max(0, proxy.size.width - 14),
                    height: max(0, proxy.size.height - 12)
                )
                .background(Color.pixelPanel)
                .overlay {
                    PixelCornerShape(cornerRadius: 8)
                        .stroke(.pixelInk, lineWidth: 3)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode {
                HStack(spacing: 12) {
                    Text(appLanguage.format(.selectedCountFormat, selectedRecordingIDs.count))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.pixelInk.opacity(0.72))

                    Spacer()

                    Button {
                        shareSelectedRecordings()
                    } label: {
                        Label(appLanguage.text(.share), systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedRecordingIDs.isEmpty ? .pixelInk.opacity(0.42) : .pixelPaper)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedRecordingIDs.isEmpty ? Color.pixelInk.opacity(0.12) : Color.pixelInk, in: PixelCornerShape(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedRecordingIDs.isEmpty)

                    Button {
                        deleteSelectedRecordings()
                    } label: {
                        Label(appLanguage.text(.delete), systemImage: "trash.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedRecordingIDs.isEmpty ? .pixelInk.opacity(0.42) : .pixelPaper)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedRecordingIDs.isEmpty ? Color.pixelInk.opacity(0.12) : Color.pixelInk, in: PixelCornerShape(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedRecordingIDs.isEmpty)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.pixelPanel.opacity(0.96))
            }
        }
        .fullScreenCover(item: $fullScreenRecording) { recording in
            RecordingPlaybackView(recording: recording, recorder: recorder)
        }
        .sheet(isPresented: $showingShareSheet) {
            SystemShareSheet(activityItems: shareURLs.map { $0 as Any })
        }
        .onChange(of: recorder.recordings) { _, recordings in
            let existingIDs = Set(recordings.map(\.id))
            selectedRecordingIDs = selectedRecordingIDs.intersection(existingIDs)
            if let fullScreenRecording, existingIDs.contains(fullScreenRecording.id) == false {
                self.fullScreenRecording = nil
            }
            if recordings.isEmpty {
                isSelectionMode = false
            }
        }
    }

    private var historyHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.pixelInk)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)

            Text("HISTORY")
                .retroFont(size: 22, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.66)
                .frame(maxWidth: .infinity)

            if recorder.recordings.isEmpty {
                PixelSpeakerGrille()
                    .frame(width: 42, height: 38)
                    .opacity(0.58)
            } else {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isSelectionMode.toggle()
                        selectedRecordingIDs.removeAll()
                    }
                } label: {
                    Text(isSelectionMode ? appLanguage.text(.cancel).uppercased() : appLanguage.text(.select).uppercased())
                        .retroFont(size: 12, weight: .black, design: .monospaced)
                        .foregroundStyle(.pixelInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.56)
                        .multilineTextAlignment(.center)
                        .frame(width: 68, height: 38)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 46)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }

    private var historyFooter: some View {
        HStack {
            PixelSpeakerGrille()
                .frame(width: 42, height: 28)
                .opacity(0.54)

            Spacer()

            Text("\(recorder.recordings.count) RECORDINGS")
                .retroFont(size: 13, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.64))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            PixelSpeakerGrille()
                .frame(width: 42, height: 28)
                .opacity(0.54)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
    }

    private func openFullScreenPlayback(_ recording: RecordingItem) {
        recorder.stopCurrentPlayback()
        fullScreenRecording = recording
    }

    private func toggleSelection(for recording: RecordingItem) {
        if selectedRecordingIDs.contains(recording.id) {
            selectedRecordingIDs.remove(recording.id)
        } else {
            selectedRecordingIDs.insert(recording.id)
        }
    }

    private func deleteSelectedRecordings() {
        recorder.deleteRecordings(with: selectedRecordingIDs)
        selectedRecordingIDs.removeAll()
        isSelectionMode = false
    }

    private func shareSelectedRecordings() {
        let selectedURLs = recorder.recordings
            .filter { selectedRecordingIDs.contains($0.id) }
            .map(\.url)

        guard selectedURLs.isEmpty == false else {
            return
        }

        shareURLs = selectedURLs
        showingShareSheet = true
    }
}

private struct SystemShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct RecordingTagCloud: View {
    @Environment(\.appLanguage) private var appLanguage

    let recording: RecordingItem
    @ObservedObject var recorder: AudioRecorderViewModel
    let onLanguageTap: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            InfoTag(systemName: "timer", text: recording.durationText)

            Button(action: onLanguageTap) {
                InfoTag(
                    systemName: "globe",
                    text: recorder.languageTitle(for: recording),
                    isInteractive: true
                )
            }
            .buttonStyle(.plain)

            if recording.transcript != nil {
                InfoTag(systemName: "textformat.size", text: appLanguage.format(.characterCountFormat, recording.transcriptCharacterCount))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InfoTag: View {
    let systemName: String
    let text: String
    var isInteractive = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2.weight(.bold))

            Text(text)
                .retroFont(size: 11, weight: .bold)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(isInteractive ? .pixelInk : .pixelInk.opacity(0.72))
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage(InterfaceRetroFont.storageKey) private var interfaceFontRaw = InterfaceRetroFont.system.rawValue
    @AppStorage(InterfaceColorTheme.storageKey) private var interfaceColorThemeRaw = InterfaceColorTheme.pocketOlive.rawValue
    @AppStorage(WaveformVisualFilterSettings.asciiVideoEnabledStorageKey) private var isASCIIFilterEnabled = false
    @ObservedObject var recorder: AudioRecorderViewModel

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRaw)
    }

    private var interfaceFont: InterfaceRetroFont {
        guard appLanguage.resolvedLanguage == .english else {
            return .system
        }

        return InterfaceRetroFont.value(for: interfaceFontRaw)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveAppBackground()

                GeometryReader { proxy in
                    VStack(alignment: .leading, spacing: 8) {
                        settingsHeader

                        ScrollView {
                            VStack(alignment: .leading, spacing: 22) {
                                InterfaceColorThemePickerView(selectedRawValue: $interfaceColorThemeRaw)
                                WaveformFilterSettingsView(isASCIIFilterEnabled: $isASCIIFilterEnabled)
                                AppLanguagePickerView(selectedRawValue: $appLanguageRaw)

                                if appLanguage.resolvedLanguage == .english {
                                    InterfaceRetroFontPickerView(selectedRawValue: $interfaceFontRaw)
                                }

                                TranscriptionModelPickerView(selectedEngine: $recorder.transcriptionEngine)
                                AudioRecordingSettingsPickerView(
                                    selectedFormat: $recorder.recordingFileFormat,
                                    selectedSampleRate: $recorder.recordingSampleRate,
                                    selectedBitDepth: $recorder.recordingBitDepth,
                                    isEnabled: !recorder.isRecording
                                )
                            }
                            .padding(11)
                        }
                        .background(Color.pixelPaper)
                        .overlay {
                            Rectangle()
                                .stroke(.pixelInk, lineWidth: 3)
                        }
                    }
                    .padding(9)
                    .frame(
                        width: max(0, proxy.size.width - 14),
                        height: max(0, proxy.size.height - 12)
                    )
                    .background(Color.pixelPanel)
                    .overlay {
                        PixelCornerShape(cornerRadius: 8)
                            .stroke(.pixelInk, lineWidth: 3)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.appLanguage, appLanguage)
        .environment(\.layoutDirection, appLanguage.layoutDirection)
        .environment(\.interfaceRetroFont, interfaceFont)
        .environment(\.font, interfaceFont.font(size: 15, weight: .regular))
        .animation(.easeOut(duration: 0.18), value: interfaceColorThemeRaw)
    }

    private var settingsHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.pixelInk)
                .frame(width: 34, height: 34)

            Text(appLanguage.text(.settings).uppercased())
                .retroFont(size: 21, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.66)
                .frame(maxWidth: .infinity)

            Button {
                dismiss()
            } label: {
                Text(appLanguage.text(.done).uppercased())
                    .retroFont(size: 11, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .frame(width: 62, height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 7)
        .frame(height: 44)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }
}

private struct WaveformFilterSettingsView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var isASCIIFilterEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.waveformFilter))

            Toggle(isOn: $isASCIIFilterEnabled) {
                HStack(spacing: 11) {
                    Image(systemName: "textformat.alt")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.pixelInk)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appLanguage.text(.asciiVideoFilter))
                            .retroFont(size: 15, weight: .black, design: .monospaced)
                            .foregroundStyle(.pixelInk)

                        Text(appLanguage.text(.asciiVideoFilterSubtitle))
                            .retroFont(size: 11, weight: .semibold, design: .monospaced)
                            .foregroundStyle(.pixelInk.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .toggleStyle(.switch)
            .tint(.pixelInk)
            .padding(12)
            .background(Color.pixelPanel.opacity(0.5), in: PixelCornerShape(cornerRadius: 6))
            .overlay {
                PixelCornerShape(cornerRadius: 6)
                    .stroke(.pixelInk.opacity(0.24), lineWidth: 1)
            }
            .accessibilityHint("Applies to every realtime waveform visualization")
        }
    }
}

private struct InterfaceColorThemePickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedRawValue: String

    private var selectedTheme: InterfaceColorTheme {
        InterfaceColorTheme.value(for: selectedRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.interfaceTheme))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 10)], spacing: 10) {
                ForEach(InterfaceColorTheme.allCases) { theme in
                    Button {
                        selectedRawValue = theme.rawValue
                    } label: {
                        InterfaceColorThemeRow(
                            theme: theme,
                            isSelected: theme == selectedTheme
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct InterfaceColorThemeRow: View {
    @Environment(\.appLanguage) private var appLanguage

    let theme: InterfaceColorTheme
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(theme.title)
                    .retroFont(size: 15, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : 0.38))
            }

            HStack(spacing: 5) {
                ForEach(Array(theme.previewSwatches.enumerated()), id: \.offset) { _, color in
                    Rectangle()
                        .fill(color)
                        .frame(height: 18)
                        .overlay {
                            Rectangle()
                                .stroke(.pixelInk.opacity(0.2), lineWidth: 1)
                        }
                }
            }

            Text(theme.subtitle(language: appLanguage))
                .retroFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(Color.pixelPanel.opacity(isSelected ? 0.98 : 0.72), in: PixelCornerShape(cornerRadius: 7))
        .overlay {
            PixelCornerShape(cornerRadius: 7)
                .stroke(.pixelInk.opacity(isSelected ? 0.92 : 0.24), lineWidth: isSelected ? 2 : 1)
        }
    }
}

private struct AppLanguagePickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedRawValue: String

    private var selectedLanguage: AppLanguage {
        AppLanguage.value(for: selectedRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.appLanguage))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selectedRawValue = language.rawValue
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(language.title(displayLanguage: appLanguage))
                                    .retroFont(size: 15, weight: .black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                Spacer(minLength: 2)

                                Image(systemName: language == selectedLanguage ? "checkmark.circle.fill" : "circle")
                                    .font(.caption.weight(.black))
                            }

                            Text(language.subtitle(displayLanguage: appLanguage))
                                .retroFont(size: 11, weight: .semibold)
                                .foregroundStyle(.pixelInk.opacity(0.54))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .foregroundStyle(.pixelInk)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                        .background(Color.pixelPanel.opacity(language == selectedLanguage ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
                        .overlay {
                            PixelCornerShape(cornerRadius: 6)
                                .stroke(.pixelInk.opacity(language == selectedLanguage ? 0.84 : 0.18), lineWidth: language == selectedLanguage ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct InterfaceRetroFontPickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedRawValue: String

    private var selectedFont: InterfaceRetroFont {
        InterfaceRetroFont.value(for: selectedRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.interfaceFont))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 10)], spacing: 10) {
                ForEach(InterfaceRetroFont.allCases) { font in
                    Button {
                        selectedRawValue = font.rawValue
                    } label: {
                        InterfaceRetroFontRow(
                            option: font,
                            isSelected: selectedFont == font
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct InterfaceRetroFontRow: View {
    let option: InterfaceRetroFont
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(option.title)
                    .font(option.font(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : 0.3))
            }

            Text(option.sampleText)
                .font(option.font(size: 19, weight: .black, design: .monospaced))
                .foregroundStyle(.pixelInk.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.44)
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)

            Text(option.subtitle)
                .font(option.font(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.pixelInk.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(Color.pixelPanel.opacity(isSelected ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
        .overlay {
            PixelCornerShape(cornerRadius: 6)
                .stroke(.pixelInk.opacity(isSelected ? 0.84 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
    }
}

private struct TranscriptionModelPickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedEngine: TranscriptionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.transcriptionModel))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 10)], spacing: 10) {
                ForEach(TranscriptionEngine.allCases) { engine in
                    Button {
                        selectedEngine = engine
                    } label: {
                        TranscriptionModelRow(
                            engine: engine,
                            isSelected: selectedEngine == engine
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TranscriptionModelRow: View {
    @Environment(\.appLanguage) private var appLanguage

    let engine: TranscriptionEngine
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: engine.iconName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : 0.7))
                    .frame(width: 24)

                Spacer(minLength: 4)

                Text(engine.status(language: appLanguage))
                    .retroFont(size: 10, weight: .black, design: .rounded)
                    .foregroundStyle(engine.isAvailable ? .pixelInk : .pixelInk.opacity(0.44))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.pixelPaper.opacity(0.42), in: PixelCornerShape(cornerRadius: 4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(engine.title(language: appLanguage))
                .retroFont(size: 15, weight: .black)
                .foregroundStyle(.pixelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(engine.subtitle(language: appLanguage))
                .retroFont(size: 11, weight: .semibold)
                .foregroundStyle(.pixelInk.opacity(engine.isAvailable ? 0.58 : 0.42))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack {
                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : 0.3))
            }
        }
        .padding(12)
        .frame(minHeight: 116, alignment: .topLeading)
        .background(Color.pixelPanel.opacity(isSelected ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
        .overlay {
            PixelCornerShape(cornerRadius: 6)
                .stroke(.pixelInk.opacity(isSelected ? 0.84 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
    }
}

private struct AudioRecordingSettingsPickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedFormat: RecordingAudioFileFormat
    @Binding var selectedSampleRate: RecordingSampleRate
    @Binding var selectedBitDepth: RecordingBitDepth
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                sectionHeader(appLanguage.text(.audioRecordingSettings))

                Spacer()

                Text("\(selectedFormat.title) · \(selectedSampleRate.title) · \(selectedBitDepth.title)")
                    .retroFont(size: 12, weight: .black)
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(appLanguage.text(.audioFileFormat))
                    .retroFont(size: 12, weight: .black)
                    .foregroundStyle(.pixelInk.opacity(0.62))
                    .textCase(.uppercase)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                    ForEach(RecordingAudioFileFormat.allCases) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            AudioFormatOptionRow(
                                title: format.title,
                                subtitle: format.subtitle(language: appLanguage),
                                systemName: iconName(for: format),
                                isSelected: selectedFormat == format,
                                isEnabled: isEnabled
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEnabled)
                    }
                }
            }

            optionGrid(
                title: appLanguage.text(.audioSampleRate),
                options: RecordingSampleRate.allCases,
                selectedOption: selectedSampleRate,
                label: { $0.title },
                onSelect: { selectedSampleRate = $0 }
            )

            optionGrid(
                title: appLanguage.text(.audioBitDepth),
                options: RecordingBitDepth.allCases,
                selectedOption: selectedBitDepth,
                label: { $0.title },
                onSelect: { selectedBitDepth = $0 }
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.62)
    }

    private func optionGrid<Option: Identifiable & Equatable>(
        title: String,
        options: [Option],
        selectedOption: Option,
        label: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) -> some View where Option.ID: Hashable {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .retroFont(size: 12, weight: .black)
                .foregroundStyle(.pixelInk.opacity(0.62))
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        HStack(spacing: 6) {
                            Text(label(option))
                                .retroFont(size: 13, weight: .black, design: .monospaced)
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)

                            Spacer(minLength: 2)

                            Image(systemName: selectedOption == option ? "checkmark.circle.fill" : "circle")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(.pixelInk.opacity(selectedOption == option ? 1 : 0.74))
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .background(Color.pixelPanel.opacity(selectedOption == option ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
                        .overlay {
                            PixelCornerShape(cornerRadius: 6)
                                .stroke(.pixelInk.opacity(selectedOption == option ? 0.84 : 0.18), lineWidth: selectedOption == option ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func iconName(for format: RecordingAudioFileFormat) -> String {
        switch format {
        case .caf:
            return "waveform"
        case .wav:
            return "waveform.path"
        case .m4a:
            return "music.note"
        case .aiff:
            return "doc.richtext"
        }
    }
}

private struct AudioFormatOptionRow: View {
    let title: String
    let subtitle: String
    let systemName: String
    let isSelected: Bool
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.headline.weight(.black))
                .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : (isEnabled ? 0.7 : 0.34)))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .retroFont(size: 15, weight: .black)
                    .foregroundStyle(.pixelInk.opacity(isEnabled ? 1 : 0.42))
                    .lineLimit(1)

                Text(subtitle)
                    .retroFont(size: 11, weight: .semibold)
                    .foregroundStyle(.pixelInk.opacity(isEnabled ? 0.56 : 0.32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 4)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.black))
                .foregroundStyle(.pixelInk.opacity(isSelected ? 1 : 0.3))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(Color.pixelPanel.opacity(isSelected ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
        .overlay {
            PixelCornerShape(cornerRadius: 6)
                .stroke(.pixelInk.opacity(isSelected ? 0.84 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
    }
}

private struct CassetteStylePickerView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedRawValue: String

    private var selectedStyle: CassetteDeckStyle {
        CassetteDeckStyle(rawValue: selectedRawValue) ?? .studioBlack
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(appLanguage.text(.cassetteStyle))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CassetteDeckStyle.allCases) { style in
                        Button {
                            selectedRawValue = style.rawValue
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                CassetteStyleThumbnail(style: style)
                                    .frame(width: 168, height: 104)

                                HStack(alignment: .center, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(style.title(language: appLanguage))
                                            .font(.subheadline.weight(.black))
                                            .foregroundStyle(.pixelInk)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.72)

                                        Text(style.subtitle(language: appLanguage))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.pixelInk.opacity(0.56))
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 4)

                                    Image(systemName: style == selectedStyle ? "checkmark.circle.fill" : "circle")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.pixelInk.opacity(style == selectedStyle ? 1 : 0.34))
                                }
                            }
                            .padding(10)
                            .frame(width: 188)
                            .background(Color.pixelPanel.opacity(style == selectedStyle ? 0.78 : 0.38), in: PixelCornerShape(cornerRadius: 6))
                            .overlay {
                                PixelCornerShape(cornerRadius: 6)
                                    .stroke(.pixelInk.opacity(style == selectedStyle ? 0.84 : 0.18), lineWidth: style == selectedStyle ? 2 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }
}

struct LanguagePickerView: View {
    @Environment(\.appLanguage) private var appLanguage
    @ObservedObject var recorder: AudioRecorderViewModel
    let recording: RecordingItem
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var customIdentifier = ""

    private var currentIdentifier: String {
        recorder.localeIdentifier(for: recording)
    }

    private var filteredOptions: [SpeechLanguageOption] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedSearch.isEmpty == false else {
            return recorder.localeChoices
        }

        return recorder.localeChoices.filter { option in
            option.title.localizedCaseInsensitiveContains(trimmedSearch)
                || option.subtitle.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(appLanguage.text(.current)) {
                    LanguageOptionRow(
                        option: SpeechLanguageOption.option(for: currentIdentifier),
                        isSelected: true
                    )
                }

                Section(appLanguage.text(.manualInput)) {
                    HStack(spacing: 12) {
                        TextField("zh-CN / en-US / yue-Hant-HK", text: $customIdentifier)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button(appLanguage.text(.use)) {
                            recorder.setLocaleIdentifier(customIdentifier, for: recording)
                            dismiss()
                        }
                        .font(.subheadline.weight(.bold))
                    }
                }

                Section(appLanguage.text(.availableLanguages)) {
                    ForEach(filteredOptions) { option in
                        Button {
                            recorder.setLocaleIdentifier(option.id, for: recording)
                            dismiss()
                        } label: {
                            LanguageOptionRow(
                                option: option,
                                isSelected: option.id == currentIdentifier
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: appLanguage.text(.searchLanguage))
            .navigationTitle(appLanguage.text(.recognitionLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appLanguage.text(.done)) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                customIdentifier = currentIdentifier
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct LanguageOptionRow: View {
    let option: SpeechLanguageOption
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(option.title)
                    .font(.body.weight(.semibold))

                Text(option.subtitle)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct TransportButton: View {
    let systemName: String
    let tint: Color
    let isEnabled: Bool
    var size: CGFloat = 76
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(isEnabled ? tint : .pixelInk.opacity(0.24))
                .frame(width: size, height: size)
                .background(.black.opacity(isEnabled ? 0.32 : 0.16), in: Circle())
                .overlay {
                    Circle()
                        .stroke(isEnabled ? tint.opacity(0.58) : .pixelInk.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

@ViewBuilder
private func sectionHeader(_ title: String) -> some View {
    Text(title)
        .retroFont(size: 13, weight: .black, design: .monospaced)
        .foregroundStyle(.pixelInk.opacity(0.82))
        .textCase(.uppercase)
}
