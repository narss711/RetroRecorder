import SwiftUI
import UIKit

enum WaveformVisualFilterSettings {
    static let asciiVideoEnabledStorageKey = "waveformASCIIVisualFilterEnabled"
}

enum CassetteDeckStyle: String, CaseIterable, Identifiable {
    case studioBlack
    case creamRainbow
    case redMixtape
    case blueClear
    case lineSketch

    var id: String { rawValue }

    var title: String {
        title(language: .simplifiedChinese)
    }

    func title(language: AppLanguage) -> String {
        if language.resolvedLanguage == .english {
            switch self {
            case .studioBlack:
                return "Studio Black"
            case .creamRainbow:
                return "Cream Rainbow"
            case .redMixtape:
                return "Red Mixtape"
            case .blueClear:
                return "Clear Blue"
            case .lineSketch:
                return "Line Sketch"
            }
        }

        switch self {
        case .studioBlack:
            return "黑胶工作室"
        case .creamRainbow:
            return "奶油彩带"
        case .redMixtape:
            return "红标混音"
        case .blueClear:
            return "透明蓝"
        case .lineSketch:
            return "线条机"
        }
    }

    var subtitle: String {
        subtitle(language: .simplifiedChinese)
    }

    func subtitle(language: AppLanguage) -> String {
        if language.resolvedLanguage == .english {
            switch self {
            case .studioBlack:
                return "Dark body"
            case .creamRainbow:
                return "Vintage stripes"
            case .redMixtape:
                return "Bold label"
            case .blueClear:
                return "Transparent shell"
            case .lineSketch:
                return "Minimal lines"
            }
        }

        switch self {
        case .studioBlack:
            return "深色机身"
        case .creamRainbow:
            return "复古彩条"
        case .redMixtape:
            return "醒目标签"
        case .blueClear:
            return "半透明外壳"
        case .lineSketch:
            return "极简线稿"
        }
    }

    fileprivate var theme: CassetteTheme {
        switch self {
        case .studioBlack:
            return CassetteTheme(
                panel: Color(red: 0.025, green: 0.027, blue: 0.03),
                shellTop: Color(red: 0.04, green: 0.04, blue: 0.04),
                shellBottom: Color(red: 0.11, green: 0.105, blue: 0.095),
                border: Color(red: 0.86, green: 0.84, blue: 0.78).opacity(0.32),
                label: Color(red: 0.92, green: 0.9, blue: 0.84),
                labelLine: Color(red: 0.18, green: 0.18, blue: 0.17).opacity(0.7),
                primaryText: Color(red: 0.06, green: 0.06, blue: 0.055),
                secondaryText: Color(red: 0.93, green: 0.9, blue: 0.78),
                window: Color(red: 0.02, green: 0.02, blue: 0.018),
                reelFace: Color(red: 0.74, green: 0.73, blue: 0.68),
                reelRing: Color(red: 0.38, green: 0.38, blue: 0.35),
                tape: Color(red: 0.19, green: 0.11, blue: 0.055),
                lower: Color(red: 0.02, green: 0.02, blue: 0.02),
                accent: Color(red: 0.87, green: 0.04, blue: 0.05),
                stripeColors: [Color(red: 0.92, green: 0.03, blue: 0.05)],
                brand: "RETRO",
                side: "SIDE A",
                length: "90",
                note: "NORMAL POSITION",
                isTransparent: false
            )
        case .creamRainbow:
            return CassetteTheme(
                panel: Color(red: 0.11, green: 0.09, blue: 0.06),
                shellTop: Color(red: 0.79, green: 0.73, blue: 0.55),
                shellBottom: Color(red: 0.61, green: 0.55, blue: 0.39),
                border: Color(red: 0.24, green: 0.21, blue: 0.14).opacity(0.55),
                label: Color(red: 0.96, green: 0.94, blue: 0.86),
                labelLine: Color(red: 0.66, green: 0.61, blue: 0.48).opacity(0.6),
                primaryText: Color(red: 0.23, green: 0.24, blue: 0.22),
                secondaryText: Color(red: 0.96, green: 0.94, blue: 0.82),
                window: Color(red: 0.08, green: 0.075, blue: 0.062),
                reelFace: Color(red: 0.9, green: 0.86, blue: 0.74),
                reelRing: Color(red: 0.47, green: 0.43, blue: 0.31),
                tape: Color(red: 0.18, green: 0.07, blue: 0.025),
                lower: Color(red: 0.2, green: 0.26, blue: 0.25),
                accent: Color(red: 0.95, green: 0.36, blue: 0.39),
                stripeColors: [
                    Color(red: 0.2, green: 0.72, blue: 0.23),
                    Color(red: 0.96, green: 0.78, blue: 0.18),
                    Color(red: 0.93, green: 0.38, blue: 0.18),
                    Color(red: 0.43, green: 0.27, blue: 0.78),
                    Color(red: 0.17, green: 0.48, blue: 0.86)
                ],
                brand: "TRUE SOUND",
                side: "A SIDE",
                length: "60",
                note: "FOR VOICE",
                isTransparent: false
            )
        case .redMixtape:
            return CassetteTheme(
                panel: Color(red: 0.06, green: 0.035, blue: 0.035),
                shellTop: Color(red: 0.04, green: 0.035, blue: 0.032),
                shellBottom: Color(red: 0.13, green: 0.12, blue: 0.105),
                border: Color(red: 0.95, green: 0.9, blue: 0.78).opacity(0.28),
                label: Color(red: 0.86, green: 0.08, blue: 0.08),
                labelLine: Color(red: 1.0, green: 0.86, blue: 0.76).opacity(0.55),
                primaryText: Color(red: 0.96, green: 0.92, blue: 0.8),
                secondaryText: Color(red: 0.98, green: 0.92, blue: 0.78),
                window: Color(red: 0.015, green: 0.015, blue: 0.014),
                reelFace: Color(red: 0.59, green: 0.57, blue: 0.51),
                reelRing: Color(red: 0.24, green: 0.23, blue: 0.21),
                tape: Color(red: 0.15, green: 0.09, blue: 0.05),
                lower: Color(red: 0.02, green: 0.02, blue: 0.019),
                accent: Color(red: 1.0, green: 0.18, blue: 0.16),
                stripeColors: [Color(red: 0.95, green: 0.88, blue: 0.72)],
                brand: "MIXTAPE",
                side: "SIDE B",
                length: "90",
                note: "MONDAY",
                isTransparent: false
            )
        case .blueClear:
            return CassetteTheme(
                panel: Color(red: 0.02, green: 0.05, blue: 0.11),
                shellTop: Color(red: 0.02, green: 0.28, blue: 0.74).opacity(0.86),
                shellBottom: Color(red: 0.02, green: 0.16, blue: 0.46).opacity(0.88),
                border: Color(red: 0.45, green: 0.78, blue: 1.0).opacity(0.42),
                label: Color(red: 0.04, green: 0.16, blue: 0.48).opacity(0.7),
                labelLine: Color(red: 0.62, green: 0.82, blue: 1.0).opacity(0.35),
                primaryText: Color(red: 0.9, green: 0.96, blue: 1.0),
                secondaryText: Color(red: 0.84, green: 0.92, blue: 1.0),
                window: Color(red: 0.01, green: 0.025, blue: 0.08),
                reelFace: Color(red: 0.31, green: 0.67, blue: 1.0),
                reelRing: Color(red: 0.7, green: 0.86, blue: 1.0),
                tape: Color(red: 0.02, green: 0.03, blue: 0.07),
                lower: Color(red: 0.015, green: 0.04, blue: 0.12).opacity(0.78),
                accent: Color(red: 0.62, green: 0.9, blue: 1.0),
                stripeColors: [
                    Color(red: 0.74, green: 0.89, blue: 1.0).opacity(0.82),
                    Color(red: 0.08, green: 0.28, blue: 0.82).opacity(0.78)
                ],
                brand: "CD-IT",
                side: "SIDE A",
                length: "90",
                note: "HIGH BIAS",
                isTransparent: true
            )
        case .lineSketch:
            return CassetteTheme(
                panel: .deckPanel,
                shellTop: .clear,
                shellBottom: .clear,
                border: .cream.opacity(0.52),
                label: .clear,
                labelLine: .cream.opacity(0.34),
                primaryText: .cream,
                secondaryText: .cream.opacity(0.78),
                window: .clear,
                reelFace: .clear,
                reelRing: .cream,
                tape: .cream.opacity(0.32),
                lower: .clear,
                accent: .mintGlow,
                stripeColors: [.cream],
                brand: "LINE",
                side: "SIDE A",
                length: "∞",
                note: "SKETCH",
                isTransparent: false
            )
        }
    }
}

struct RealtimeWaveformDeckView: View {
    @Environment(\.appLanguage) private var appLanguage
    @AppStorage(RealtimeWaveformMode.storageKey) private var selectedMode = RealtimeWaveformMode.seeWav
    @AppStorage(WaveformVisualFilterSettings.asciiVideoEnabledStorageKey) private var isASCIIFilterEnabled = false

    let isRecording: Bool
    let isPaused: Bool
    let elapsed: TimeInterval
    let levels: [Double]
    let frequencyLevels: [Double]
    let instantaneousFrequencyLevels: [Double]
    let liveSamples: [Double]
    let shadertoySpectrum: [Double]
    let shadertoyWaveform: [Double]
    let liveText: String
    let isLiveTextActive: Bool
    let audioQualityText: String
    let canAddTag: Bool
    let currentTagTimeText: String
    let hasCurrentTag: Bool
    let visualHeight: CGFloat
    let onAddTag: () -> RecordingTagAddResult?

    private var isActive: Bool {
        isRecording && !isPaused
    }

    private var statusText: String {
        if isPaused {
            return "PAUSE"
        }

        return isRecording ? "REC" : "READY"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 7) {
                DeckLiveDot()
                    .opacity(isActive ? 1 : 0.22)

                Menu {
                    Picker("VISUAL EFFECT", selection: $selectedMode) {
                        ForEach(RealtimeWaveformMode.allCases) { mode in
                            Text(mode.title)
                                .tag(mode)
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(selectedMode.title)
                            .retroFont(size: 8, weight: .black, design: .monospaced)
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .black))
                    }
                    .foregroundStyle(.pixelInk.opacity(0.78))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Visual effect, \(selectedMode.title)")

                modeIndicator

                Spacer()

                Text("SWIPE")
                    .retroFont(size: 7, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk.opacity(0.44))
            }

            visualEffectPager
                .compositingGroup()
                .mask {
                    if isASCIIFilterEnabled {
                        ASCIIVideoWaveformMask(
                            levels: levels,
                            frequencyLevels: frequencyLevels,
                            waveform: shadertoyWaveform,
                            isActive: isActive
                        )
                    } else {
                        Rectangle()
                            .fill(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: visualHeight)
                .accessibilityLabel("Realtime audio input waveform")
                .accessibilityValue(isASCIIFilterEnabled ? "ASCII filter on" : "ASCII filter off")
        }
        .padding(5)
        .background(Color.pixelPanel.opacity(0.28))
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }

    private var visualEffectPager: some View {
        TabView(selection: $selectedMode) {
                SeeWavRealtimeBars(levels: levels, isActive: isModeAnimating(.seeWav))
                    .tag(RealtimeWaveformMode.seeWav)

                DSWaveformRealtimeCanvas(samples: liveSamples, isActive: isModeAnimating(.dsWaveform))
                    .tag(RealtimeWaveformMode.dsWaveform)

                FrequencyHistogramRealtimeCanvas(levels: frequencyLevels, isActive: isModeAnimating(.audioVisualizer))
                    .tag(RealtimeWaveformMode.audioVisualizer)

                MitsuhaRealtimeCanvas(levels: frequencyLevels, isActive: isModeAnimating(.mitsuha))
                    .tag(RealtimeWaveformMode.mitsuha)

                YellowRedEQRealtimeCanvas(levels: frequencyLevels, isActive: isModeAnimating(.yellowRedEQ))
                    .tag(RealtimeWaveformMode.yellowRedEQ)

                ShadertoyMetalEffectView(
                    effect: .circleReactive,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.circleReactive)
                )
                    .tag(RealtimeWaveformMode.circleReactive)

                ShadertoyMetalEffectView(
                    effect: .waveLeneer,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.waveLeneer)
                )
                    .tag(RealtimeWaveformMode.waveLeneer)

                ShadertoyMetalEffectView(
                    effect: .colorFFT,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.colorFFT)
                )
                    .tag(RealtimeWaveformMode.colorFFT)

                ShadertoyMetalEffectView(
                    effect: .triangleGalaxy,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.triangleGalaxy)
                )
                    .tag(RealtimeWaveformMode.triangleGalaxy)

                ShadertoyMetalEffectView(
                    effect: .microphoneGradient,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.microphoneGradient)
                )
                    .tag(RealtimeWaveformMode.microphoneGradient)

                ShadertoyMetalEffectView(
                    effect: .movingFrequencySpectrum,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.movingFrequencySpectrum)
                )
                .tag(RealtimeWaveformMode.movingFrequencySpectrum)

                ShadertoyMetalEffectView(
                    effect: .micRipples,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.micRipples)
                )
                .tag(RealtimeWaveformMode.micRipples)

                ShadertoyMetalEffectView(
                    effect: .plasticSurface,
                    spectrum: shadertoySpectrum,
                    waveform: shadertoyWaveform,
                    isActive: isModeAnimating(.plasticSurface)
                )
                .tag(RealtimeWaveformMode.plasticSurface)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var modeIndicator: some View {
        HStack(spacing: 4) {
            ForEach(RealtimeWaveformMode.allCases) { mode in
                Rectangle()
                    .fill(mode == selectedMode ? Color.pixelInk : Color.pixelInk.opacity(0.24))
                    .frame(width: mode == selectedMode ? 12 : 5, height: 4)
                    .animation(.easeOut(duration: 0.18), value: selectedMode)
            }
        }
        .accessibilityHidden(true)
    }

    private func isModeAnimating(_ mode: RealtimeWaveformMode) -> Bool {
        isActive && selectedMode == mode
    }
}

private struct ASCIIVideoWaveformMask: View {
    private static let densityCharacters = Array(".:-=+*#%@")

    let levels: [Double]
    let frequencyLevels: [Double]
    let waveform: [Double]
    let isActive: Bool

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            guard size.width > 0, size.height > 0 else {
                return
            }

            let fontSize = min(10, max(7, size.width / 52))
            let cellWidth = fontSize * 0.62
            let lineHeight = fontSize * 1.16
            let columnCount = max(1, Int(ceil(size.width / cellWidth)) + 1)
            let rowCount = max(1, Int(ceil(size.height / lineHeight)) + 1)
            let grid = asciiGrid(columns: columnCount, rows: rowCount)
            let text = Text(grid)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            context.draw(context.resolve(text), at: .zero, anchor: .topLeading)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    // Inspired by ASCII-Video's cell sampling and ordered character-density mapping.
    private func asciiGrid(columns: Int, rows: Int) -> String {
        var output = String()
        output.reserveCapacity((columns + 1) * rows)

        for row in 0..<rows {
            let rowProgress = Double(row) / Double(max(1, rows - 1))

            for column in 0..<columns {
                let progress = Double(column) / Double(max(1, columns - 1))
                let envelope = sample(levels, at: progress)
                let spectrum = sample(frequencyLevels, at: progress)
                let wave = sample(waveform, at: progress)
                let waveCenter = 0.5 - wave * 0.32
                let waveDistance = abs(rowProgress - waveCenter)
                let waveProfile = exp(-waveDistance * 13)
                let barReach = 0.06 + pow(max(envelope, spectrum), 0.58) * 0.44
                let barProfile = max(0, 1 - abs(rowProgress - 0.5) / barReach)
                let checker = Double((row * 17 + column * 31) % 11) / 10
                let activityScale = isActive ? 1.0 : 0.32
                let density = min(
                    1,
                    max(
                        0,
                        0.08
                            + activityScale * (
                                spectrum * 0.36
                                    + envelope * 0.22
                                    + waveProfile * (0.18 + abs(wave) * 0.28)
                                    + barProfile * 0.22
                            )
                            + checker * 0.06
                    )
                )
                let index = min(
                    Self.densityCharacters.count - 1,
                    Int((density * Double(Self.densityCharacters.count - 1)).rounded())
                )
                output.append(Self.densityCharacters[index])
            }

            if row < rows - 1 {
                output.append("\n")
            }
        }

        return output
    }

    private func sample(_ values: [Double], at progress: Double) -> Double {
        guard values.isEmpty == false else {
            return 0
        }

        guard values.count > 1 else {
            return values[0]
        }

        let position = min(1, max(0, progress)) * Double(values.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = min(lowerIndex + 1, values.count - 1)
        let fraction = position - Double(lowerIndex)
        return values[lowerIndex] + (values[upperIndex] - values[lowerIndex]) * fraction
    }
}

private enum RealtimeWaveformMode: String, CaseIterable, Identifiable {
    static let storageKey = "selectedRealtimeWaveformMode"

    case seeWav
    case dsWaveform
    case audioVisualizer
    case mitsuha
    case yellowRedEQ
    case circleReactive
    case waveLeneer
    case colorFFT
    case triangleGalaxy
    case microphoneGradient
    case movingFrequencySpectrum
    case micRipples
    case plasticSurface

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seeWav:
            return "INPUT WAVE"
        case .dsWaveform:
            return "LIVE SHAPE"
        case .audioVisualizer:
            return "FREQ HISTO"
        case .mitsuha:
            return "MITSUHA"
        case .yellowRedEQ:
            return "YELLOW RED EQ"
        case .circleReactive:
            return "CIRCLE REACTIVE"
        case .waveLeneer:
            return "WAVE LENEER"
        case .colorFFT:
            return "COLOR FFT"
        case .triangleGalaxy:
            return "TRIANGLE GALAXY"
        case .microphoneGradient:
            return "MIC GRADIENT"
        case .plasticSurface:
            return "PLASTIC SURFACE"
        case .movingFrequencySpectrum:
            return "MOVING SPECTRUM"
        case .micRipples:
            return "MIC RIPPLES"
        }
    }
}

private struct YellowRedEQRealtimeCanvas: View {
    private static let fallbackLevelCount = 48

    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: Self.fallbackLevelCount) : levels
    }

    var body: some View {
        Canvas { context, size in
            drawCenterGuide(in: size, context: context)
            drawEqualizer(in: size, context: context)
        }
        .animation(.easeOut(duration: 0.075), value: levels)
        .accessibilityLabel("Yellow red pixel equalizer")
    }

    private func drawCenterGuide(in size: CGSize, context: GraphicsContext) {
        let rect = CGRect(x: 0, y: floor(size.height * 0.5), width: size.width, height: 1)
        context.fill(Path(rect), with: .color(Color(red: 1, green: 0.58, blue: 0.05).opacity(0.16)))
    }

    private func drawEqualizer(in size: CGSize, context: GraphicsContext) {
        let values = displayLevels
        guard values.isEmpty == false, size.width > 0, size.height > 0 else {
            return
        }

        let columnGap: CGFloat = 1
        let rowGap: CGFloat = 1
        let columnCount = min(90, max(30, Int(size.width / 5)))
        let rowCount = max(14, Int(size.height / 5))
        let halfRowCount = max(2, rowCount / 2)
        let columnWidth = size.width / CGFloat(columnCount)
        let rowHeight = size.height / CGFloat(rowCount)
        let cellWidth = max(1, columnWidth - columnGap)
        let cellHeight = max(1, rowHeight - rowGap)
        let centerY = size.height * 0.5

        for column in 0..<columnCount {
            let progress = Double(column) / Double(max(1, columnCount - 1))
            let levelIndex = min(values.count - 1, Int(progress * Double(values.count - 1)))
            let level = min(1, max(0, values[levelIndex]))
            let shapedLevel = pow(level, 0.58)
            let litRows = isActive ? Int((shapedLevel * Double(halfRowCount - 1)).rounded(.up)) : 0

            guard litRows > 0 else {
                continue
            }

            let x = CGFloat(column) * columnWidth + columnGap * 0.5
            for row in 0..<litRows {
                let rowProgress = Double(row) / Double(max(1, halfRowCount - 1))
                let color = equalizerColor(rowProgress: rowProgress, level: level)
                let offset = CGFloat(row) * rowHeight + rowHeight * 0.5
                let upperRect = CGRect(
                    x: x,
                    y: centerY - offset - cellHeight * 0.5,
                    width: cellWidth,
                    height: cellHeight
                )
                let lowerRect = CGRect(
                    x: x,
                    y: centerY + offset - cellHeight * 0.5,
                    width: cellWidth,
                    height: cellHeight
                )

                context.fill(Path(upperRect), with: .color(color))
                context.fill(Path(lowerRect), with: .color(color.opacity(0.9)))
            }
        }
    }

    private func equalizerColor(rowProgress: Double, level: Double) -> Color {
        let tipMix = min(1, max(0, rowProgress * 1.18))
        let green = 0.82 - tipMix * 0.64
        let blue = 0.08 - tipMix * 0.05
        let opacity = 0.58 + min(1, level) * 0.42
        return Color(red: 1, green: green, blue: blue).opacity(opacity)
    }
}

#if false
private struct CircleMusicReactiveCanvas: View {
    private static let fallbackLevelCount = 64

    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: Self.fallbackLevelCount) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawCircularSpectrum(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
        .accessibilityLabel("Circular music reactive spectrum")
    }

    private func drawCircularSpectrum(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displayLevels
        guard values.isEmpty == false, size.width > 0, size.height > 0 else {
            return
        }

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let minDimension = min(size.width, size.height)
        let bassCount = max(1, min(8, values.count))
        let bassEnergy = values.prefix(bassCount).reduce(0, +) / Double(bassCount)
        let baseRadius = minDimension * (0.16 + CGFloat(pow(max(0, bassEnergy), 0.65)) * 0.035)
        let maximumLength = minDimension * 0.25
        let segmentCount = min(112, max(64, Int(minDimension / 3.8)))
        let time = date.timeIntervalSinceReferenceDate
        let rotation = isActive ? time * 0.045 : 0

        drawCoreRings(
            center: center,
            radius: baseRadius,
            bassEnergy: bassEnergy,
            context: context
        )

        for index in 0..<segmentCount {
            let progress = Double(index) / Double(segmentCount)
            let foldedProgress = progress <= 0.5 ? progress * 2 : (1 - progress) * 2
            let levelIndex = min(values.count - 1, Int(foldedProgress * Double(values.count - 1)))
            let level = min(1, max(0, values[levelIndex]))
            let shapedLevel = isActive ? pow(level, 0.54) : 0.015
            let flutter = isActive ? 0.92 + 0.08 * sin(time * 4.2 + Double(index) * 0.43) : 1
            let barLength = CGFloat(shapedLevel * flutter) * maximumLength + 2
            let angle = CGFloat(-Double.pi * 0.5 + progress * Double.pi * 2 + rotation)
            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            let start = CGPoint(
                x: center.x + direction.dx * baseRadius,
                y: center.y + direction.dy * baseRadius
            )
            let end = CGPoint(
                x: center.x + direction.dx * (baseRadius + barLength),
                y: center.y + direction.dy * (baseRadius + barLength)
            )
            var bar = Path()
            bar.move(to: start)
            bar.addLine(to: end)

            context.stroke(
                bar,
                with: .color(segmentColor(progress: progress, level: level)),
                style: StrokeStyle(
                    lineWidth: isActive ? 1.6 + CGFloat(level) * 1.4 : 1,
                    lineCap: .round
                )
            )

            if isActive, level > 0.22, index.isMultiple(of: 2) {
                let tipSize = CGFloat(1.8 + level * 2.4)
                let tip = CGRect(
                    x: end.x - tipSize * 0.5,
                    y: end.y - tipSize * 0.5,
                    width: tipSize,
                    height: tipSize
                )
                context.fill(Path(tip), with: .color(segmentColor(progress: progress, level: 1)))
            }
        }
    }

    private func drawCoreRings(
        center: CGPoint,
        radius: CGFloat,
        bassEnergy: Double,
        context: GraphicsContext
    ) {
        let innerRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let pulseRadius = radius + CGFloat(isActive ? pow(max(0, bassEnergy), 0.6) * 12 : 3)
        let pulseRect = CGRect(
            x: center.x - pulseRadius,
            y: center.y - pulseRadius,
            width: pulseRadius * 2,
            height: pulseRadius * 2
        )

        context.fill(Path(ellipseIn: innerRect), with: .color(.pixelInk.opacity(0.045)))
        context.stroke(
            Path(ellipseIn: innerRect),
            with: .color(.pixelInk.opacity(isActive ? 0.46 : 0.18)),
            lineWidth: 1.4
        )
        context.stroke(
            Path(ellipseIn: pulseRect),
            with: .color(Color.mintGlow.opacity(isActive ? 0.28 + bassEnergy * 0.42 : 0.1)),
            lineWidth: 1
        )
    }

    private func segmentColor(progress: Double, level: Double) -> Color {
        Color(
            hue: progress,
            saturation: 0.78,
            brightness: 0.78 + min(1, level) * 0.22
        )
        .opacity(isActive ? 0.42 + min(1, level) * 0.58 : 0.16)
    }
}

private struct WaveLeneerRealtimeCanvas: View {
    private static let fallbackSampleCount = 180

    let samples: [Double]
    let isActive: Bool

    private var displaySamples: [Double] {
        samples.isEmpty ? Array(repeating: 0, count: Self.fallbackSampleCount) : samples
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawBaseline(in: size, context: context)
                drawLayeredWave(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.08), value: samples)
        .accessibilityLabel("Layered linear audio wave")
    }

    private func drawBaseline(in size: CGSize, context: GraphicsContext) {
        let y = size.height * 0.5
        var path = Path()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: size.width, y: y))
        context.stroke(path, with: .color(.pixelInk.opacity(0.12)), lineWidth: 1)
    }

    private func drawLayeredWave(in size: CGSize, context: GraphicsContext, date: Date) {
        let samples = displaySamples
        guard samples.count > 1, size.width > 0, size.height > 0 else {
            return
        }

        let colors: [Color] = [.mintGlow, .amber, .pixelRed]
        let phaseOffsets = [0.0, 2.15, 4.3]
        let amplitudeScales = [1.0, 0.66, 0.42]
        let pointCount = min(180, max(72, Int(size.width / 2)))
        let middleY = size.height * 0.5
        let maximumAmplitude = size.height * 0.4
        let time = date.timeIntervalSinceReferenceDate

        for layer in colors.indices.reversed() {
            var path = Path()

            for index in 0..<pointCount {
                let progress = Double(index) / Double(max(1, pointCount - 1))
                let sampleIndex = min(samples.count - 1, Int(progress * Double(samples.count - 1)))
                let level = min(1, max(0, samples[sampleIndex]))
                let envelope = isActive ? pow(level, 0.48) : 0
                let phase = phaseOffsets[layer]
                let carrier = sin(
                    progress * Double.pi * (6.0 + Double(layer) * 2.4)
                        + time * (2.15 + Double(layer) * 0.38)
                        + phase
                )
                let harmonic = sin(progress * Double.pi * 22 - time * 1.35 + phase) * 0.24
                let amplitude = (carrier + harmonic) * envelope * amplitudeScales[layer]
                let point = CGPoint(
                    x: CGFloat(progress) * size.width,
                    y: middleY + CGFloat(amplitude) * maximumAmplitude
                )

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            let activeOpacity = isActive ? 1.0 : 0.16
            context.stroke(
                path,
                with: .color(colors[layer].opacity(0.1 * activeOpacity)),
                style: StrokeStyle(lineWidth: CGFloat(10 - layer * 2), lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                path,
                with: .color(colors[layer].opacity((0.9 - Double(layer) * 0.14) * activeOpacity)),
                style: StrokeStyle(lineWidth: CGFloat(2.4 - Double(layer) * 0.35), lineCap: .round, lineJoin: .round)
            )
        }
    }
}

private struct ColorFFTRealtimeCanvas: View {
    private static let fallbackLevelCount = 48

    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: Self.fallbackLevelCount) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawColorSpectrum(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.075), value: levels)
        .accessibilityLabel("Color FFT spectrum")
    }

    private func drawColorSpectrum(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displayLevels
        guard values.count > 1, size.width > 0, size.height > 0 else {
            return
        }

        let centerY = size.height * 0.5
        let maximumHalfHeight = size.height * 0.43
        let slotWidth = size.width / CGFloat(values.count)
        let time = date.timeIntervalSinceReferenceDate
        var upperPath = Path()
        var lowerPath = Path()

        for index in values.indices {
            let progress = Double(index) / Double(max(1, values.count - 1))
            let level = min(1, max(0, values[index]))
            let shimmer = isActive ? 0.94 + 0.06 * sin(time * 5.4 + Double(index) * 0.37) : 1
            let shapedLevel = isActive ? pow(level, 0.56) * shimmer : 0.006
            let halfHeight = max(1, CGFloat(shapedLevel) * maximumHalfHeight)
            let x = CGFloat(index) * slotWidth
            let color = fftColor(progress: progress, level: level)
            let rect = CGRect(
                x: x,
                y: centerY - halfHeight,
                width: slotWidth + 0.5,
                height: halfHeight * 2
            )

            context.fill(
                Path(rect),
                with: .linearGradient(
                    Gradient(colors: [
                        color.opacity(0.14),
                        color.opacity(isActive ? 0.92 : 0.2),
                        color.opacity(0.14)
                    ]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY),
                    endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                )
            )

            let pointX = x + slotWidth * 0.5
            let upperPoint = CGPoint(x: pointX, y: centerY - halfHeight)
            let lowerPoint = CGPoint(x: pointX, y: centerY + halfHeight)

            if index == values.startIndex {
                upperPath.move(to: upperPoint)
                lowerPath.move(to: lowerPoint)
            } else {
                upperPath.addLine(to: upperPoint)
                lowerPath.addLine(to: lowerPoint)
            }
        }

        let outlineGradient = Gradient(colors: [
            Color(red: 1, green: 0.18, blue: 0.18),
            Color(red: 1, green: 0.82, blue: 0.16),
            Color(red: 0.18, green: 1, blue: 0.42),
            Color(red: 0.12, green: 0.88, blue: 1),
            Color(red: 0.28, green: 0.34, blue: 1),
            Color(red: 0.86, green: 0.2, blue: 1)
        ])
        let outlineOpacity = isActive ? 0.88 : 0.2

        context.stroke(
            upperPath,
            with: .linearGradient(
                outlineGradient,
                startPoint: CGPoint(x: 0, y: centerY),
                endPoint: CGPoint(x: size.width, y: centerY)
            ),
            style: StrokeStyle(lineWidth: 1.8, lineJoin: .round)
        )
        context.stroke(
            lowerPath,
            with: .linearGradient(
                Gradient(colors: outlineGradient.stops.map { $0.color.opacity(outlineOpacity) }),
                startPoint: CGPoint(x: 0, y: centerY),
                endPoint: CGPoint(x: size.width, y: centerY)
            ),
            style: StrokeStyle(lineWidth: 1.2, lineJoin: .round)
        )
    }

    private func fftColor(progress: Double, level: Double) -> Color {
        Color(
            hue: min(0.82, max(0, progress * 0.82)),
            saturation: 0.86,
            brightness: 0.76 + min(1, level) * 0.24
        )
        .opacity(isActive ? 0.46 + min(1, level) * 0.54 : 0.16)
    }
}

private struct TriangleGalaxyRealtimeCanvas: View {
    private static let fallbackLevelCount = 48

    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: Self.fallbackLevelCount) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawBackdrop(in: size, context: context)
                drawGalaxy(in: size, context: context, date: timeline.date)
                drawTriangleTunnel(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
        .accessibilityLabel("Audio reactive red triangle galaxy")
    }

    private func drawBackdrop(in size: CGSize, context: GraphicsContext) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(
            Path(bounds),
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 0.18, green: 0.01, blue: 0.025),
                    Color(red: 0.035, green: 0.004, blue: 0.012),
                    .black
                ]),
                center: CGPoint(x: size.width * 0.5, y: size.height * 0.52),
                startRadius: 2,
                endRadius: max(size.width, size.height) * 0.72
            )
        )
    }

    private func drawGalaxy(in size: CGSize, context: GraphicsContext, date: Date) {
        let time = date.timeIntervalSinceReferenceDate
        let energy = displayLevels.reduce(0, +) / Double(max(1, displayLevels.count))
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
        let orbit = min(size.width, size.height) * 0.46

        for index in 0..<52 {
            let seed = Double(index)
            let angle = seed * 2.39996 + (isActive ? time * (0.028 + seed.truncatingRemainder(dividingBy: 5) * 0.003) : 0)
            let radiusProgress = (sin(seed * 78.233) * 0.5 + 0.5)
            let radius = orbit * CGFloat(0.16 + radiusProgress * 0.84)
            let spiral = angle + radiusProgress * 2.6
            let point = CGPoint(
                x: center.x + CGFloat(cos(spiral)) * radius,
                y: center.y + CGFloat(sin(spiral)) * radius * 0.56
            )
            let pulse = isActive ? 0.64 + 0.36 * sin(time * 3.1 + seed * 1.7) : 0.38
            let diameter = CGFloat(0.8 + radiusProgress * 1.8 + energy * 2.6)
            let star = CGRect(
                x: point.x - diameter * 0.5,
                y: point.y - diameter * 0.5,
                width: diameter,
                height: diameter
            )
            context.fill(
                Path(ellipseIn: star),
                with: .color(Color(red: 1, green: 0.2 + radiusProgress * 0.2, blue: 0.16).opacity(0.28 + pulse * 0.58))
            )
        }
    }

    private func drawTriangleTunnel(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displayLevels
        guard values.isEmpty == false else {
            return
        }

        let time = date.timeIntervalSinceReferenceDate
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.54)
        let minDimension = min(size.width, size.height)
        let ringCount = 10

        for ring in 0..<ringCount {
            let progress = Double(ring) / Double(max(1, ringCount - 1))
            let levelIndex = min(values.count - 1, ring * values.count / ringCount)
            let level = min(1, max(0, values[levelIndex]))
            let pulse = isActive ? pow(level, 0.58) : 0.025
            let radius = minDimension * CGFloat(0.09 + progress * 0.42 + pulse * 0.035)
            let rotation = -Double.pi * 0.5
                + (isActive ? sin(time * 0.32 + progress * 2.4) * 0.16 : 0)
                + progress * 0.1
            var triangle = Path()

            for vertex in 0..<3 {
                let angle = rotation + Double(vertex) * Double.pi * 2 / 3
                let vertexLevelIndex = min(values.count - 1, (levelIndex + vertex * 5) % values.count)
                let vertexLevel = isActive ? pow(min(1, max(0, values[vertexLevelIndex])), 0.62) : 0
                let vertexRadius = radius + minDimension * CGFloat(vertexLevel * 0.035)
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * vertexRadius,
                    y: center.y + CGFloat(sin(angle)) * vertexRadius
                )

                if vertex == 0 {
                    triangle.move(to: point)
                } else {
                    triangle.addLine(to: point)
                }
            }
            triangle.closeSubpath()

            let opacity = 0.24 + progress * 0.5 + pulse * 0.26
            context.stroke(
                triangle,
                with: .color(Color.red.opacity(opacity * 0.16)),
                style: StrokeStyle(lineWidth: 8 + CGFloat(pulse) * 6, lineJoin: .round)
            )
            context.stroke(
                triangle,
                with: .color(Color(red: 1, green: 0.08 + progress * 0.17, blue: 0.12).opacity(opacity)),
                style: StrokeStyle(lineWidth: 0.9 + CGFloat(level) * 1.8, lineJoin: .round)
            )
        }
    }
}

private struct MicrophoneGradientRealtimeCanvas: View {
    private static let fallbackSampleCount = 180

    let samples: [Double]
    let isActive: Bool

    private var displaySamples: [Double] {
        samples.isEmpty ? Array(repeating: 0, count: Self.fallbackSampleCount) : samples
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawBackdrop(in: size, context: context)
                drawWigglyLine(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.075), value: samples)
        .accessibilityLabel("Microphone gradient wiggly line")
    }

    private func drawBackdrop(in size: CGSize, context: GraphicsContext) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(
            Path(bounds),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.018, green: 0.035, blue: 0.07),
                    Color(red: 0.05, green: 0.018, blue: 0.085),
                    Color(red: 0.018, green: 0.04, blue: 0.065)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )
    }

    private func drawWigglyLine(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displaySamples
        guard values.count > 1 else {
            return
        }

        let pointCount = min(180, max(80, Int(size.width / 1.8)))
        let time = date.timeIntervalSinceReferenceDate
        let midY = size.height * 0.5
        let maximumAmplitude = size.height * 0.36
        var primaryPoints: [CGPoint] = []
        var echoPoints: [CGPoint] = []
        primaryPoints.reserveCapacity(pointCount)
        echoPoints.reserveCapacity(pointCount)

        for index in 0..<pointCount {
            let progress = Double(index) / Double(max(1, pointCount - 1))
            let sampleIndex = min(values.count - 1, Int(progress * Double(values.count - 1)))
            let level = min(1, max(0, values[sampleIndex]))
            let envelope = isActive ? pow(level, 0.48) : 0.012
            let edgeTaper = pow(sin(progress * Double.pi), 0.38)
            let carrier = sin(progress * Double.pi * 9.4 - time * 4.1)
            let detail = sin(progress * Double.pi * 25.0 + time * 2.7) * 0.22
            let drift = sin(progress * Double.pi * 2.0 + time * 0.82) * 0.12
            let amplitude = (carrier + detail + drift) * envelope * edgeTaper
            let x = CGFloat(progress) * size.width
            let y = midY + CGFloat(amplitude) * maximumAmplitude
            primaryPoints.append(CGPoint(x: x, y: y))
            echoPoints.append(CGPoint(x: x, y: midY - CGFloat(amplitude) * maximumAmplitude * 0.42))
        }

        let primaryPath = smoothPath(primaryPoints)
        let echoPath = smoothPath(echoPoints)
        let gradient = Gradient(colors: [
            Color(red: 0.16, green: 0.92, blue: 1),
            Color(red: 0.36, green: 0.48, blue: 1),
            Color(red: 1, green: 0.18, blue: 0.72),
            Color(red: 1, green: 0.72, blue: 0.2)
        ])
        let activeOpacity = isActive ? 1.0 : 0.22

        context.stroke(
            primaryPath,
            with: .linearGradient(
                Gradient(colors: gradient.stops.map { $0.color.opacity(0.12 * activeOpacity) }),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ),
            style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            echoPath,
            with: .linearGradient(
                Gradient(colors: gradient.stops.reversed().map { $0.color.opacity(0.34 * activeOpacity) }),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            primaryPath,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ),
            style: StrokeStyle(lineWidth: isActive ? 2.8 : 1.4, lineCap: .round, lineJoin: .round)
        )
    }

    private func smoothPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else {
            return path
        }
        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(
                x: (previous.x + current.x) * 0.5,
                y: (previous.y + current.y) * 0.5
            )
            path.addQuadCurve(to: midpoint, control: previous)
        }

        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }
}

private struct PlasticSurfaceRealtimeCanvas: View {
    private static let fallbackLevelCount = 48

    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: Self.fallbackLevelCount) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawBackdrop(in: size, context: context)
                drawSurface(in: size, context: context, date: timeline.date)
                drawSpecularHighlight(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
        .accessibilityLabel("Audio reactive plastic surface")
    }

    private func drawBackdrop(in size: CGSize, context: GraphicsContext) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(
            Path(bounds),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.015, green: 0.025, blue: 0.065),
                    Color(red: 0.07, green: 0.025, blue: 0.12),
                    Color(red: 0.015, green: 0.045, blue: 0.08)
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )
    }

    private func drawSurface(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displayLevels
        guard values.count > 1 else {
            return
        }

        let time = date.timeIntervalSinceReferenceDate
        let rowCount = 17
        let pointCount = 48
        let horizon = size.height * 0.14
        let surfaceHeight = size.height * 0.82

        for row in 0..<rowCount {
            let rowProgress = Double(row) / Double(max(1, rowCount - 1))
            let perspective = pow(rowProgress, 1.42)
            var path = Path()

            for point in 0..<pointCount {
                let xProgress = Double(point) / Double(max(1, pointCount - 1))
                let levelIndex = min(values.count - 1, Int(xProgress * Double(values.count - 1)))
                let level = min(1, max(0, values[levelIndex]))
                let audioLift = isActive ? pow(level, 0.62) : 0.025
                let broadWave = sin(xProgress * Double.pi * 3.2 + time * 0.74 + rowProgress * 2.8)
                let detailWave = sin(xProgress * Double.pi * 10.5 - time * 1.3 + rowProgress * 4.1) * 0.28
                let depthFade = 1 - perspective * 0.48
                let displacement = (broadWave + detailWave) * (0.18 + audioLift * 0.82) * depthFade
                let xDrift = sin(rowProgress * 5.2 + time * 0.45) * (1 - perspective) * 7
                let pointPosition = CGPoint(
                    x: CGFloat(xProgress) * size.width + CGFloat(xDrift),
                    y: horizon + CGFloat(perspective) * surfaceHeight + CGFloat(displacement) * size.height * 0.16
                )

                if point == 0 {
                    path.move(to: pointPosition)
                } else {
                    path.addLine(to: pointPosition)
                }
            }

            let hue = 0.52 + rowProgress * 0.34
            let color = Color(
                hue: hue,
                saturation: 0.78,
                brightness: 0.92
            )
            let opacity = (isActive ? 0.26 : 0.1) + perspective * (isActive ? 0.58 : 0.18)
            context.stroke(
                path,
                with: .color(color.opacity(opacity * 0.12)),
                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        color.opacity(opacity * 0.42),
                        Color.white.opacity(opacity),
                        Color(red: 1, green: 0.16, blue: 0.68).opacity(opacity * 0.72),
                        color.opacity(opacity * 0.38)
                    ]),
                    startPoint: CGPoint(x: 0, y: size.height * CGFloat(rowProgress)),
                    endPoint: CGPoint(x: size.width, y: size.height * CGFloat(rowProgress))
                ),
                style: StrokeStyle(lineWidth: 0.8 + CGFloat(perspective) * 1.4, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawSpecularHighlight(in size: CGSize, context: GraphicsContext, date: Date) {
        let values = displayLevels
        let energy = values.reduce(0, +) / Double(max(1, values.count))
        let time = date.timeIntervalSinceReferenceDate
        let progress = isActive ? (time * 0.065).truncatingRemainder(dividingBy: 1) : 0.48
        let x = size.width * CGFloat(progress)
        let width = size.width * CGFloat(0.12 + min(1, energy) * 0.12)
        let highlight = CGRect(x: x - width * 0.5, y: 0, width: width, height: size.height)
        context.fill(
            Path(highlight),
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    Color.white.opacity(isActive ? 0.075 + energy * 0.16 : 0.035),
                    .clear
                ]),
                startPoint: CGPoint(x: highlight.minX, y: 0),
                endPoint: CGPoint(x: highlight.maxX, y: size.height)
            )
        )
    }
}

#endif


private struct SeeWavRealtimeBars: View {
    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: 56) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawBars(in: size, context: context)

                if isActive {
                    drawScanLine(in: size, context: context, date: timeline.date)
                }
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
    }

    private func drawBars(in size: CGSize, context: GraphicsContext) {
        let levels = displayLevels
        guard levels.isEmpty == false else {
            return
        }

        let cell: CGFloat = 4
        let gap: CGFloat = 2
        let step = cell + gap
        let columns = max(12, Int(size.width / step))
        let rows = max(8, Int(size.height / step))
        let midRow = rows / 2
        let maxHalfRows = max(2, rows / 2 - 1)

        for column in 0..<columns {
            let sampleIndex = min(levels.count - 1, column * levels.count / columns)
            let level = min(1, max(0, levels[sampleIndex]))
            let animatedFloor = isActive ? 1 : 0
            let halfRows = max(animatedFloor, Int((level * Double(maxHalfRows)).rounded(.up)))
            let x = CGFloat(column) * step + gap

            for rowOffset in -halfRows...halfRows {
                let row = midRow + rowOffset
                guard row >= 0, row < rows else {
                    continue
                }

                let y = CGFloat(row) * step + gap
                let distance = abs(rowOffset)
                let opacity = isActive
                    ? max(0.32, 0.96 - Double(distance) * 0.055)
                    : max(0.12, 0.34 - Double(distance) * 0.035)
                let rect = CGRect(x: x, y: y, width: cell, height: cell)
                context.fill(Path(rect), with: .color(Color.pixelInk.opacity(opacity)))
            }
        }
    }

    private func drawScanLine(in size: CGSize, context: GraphicsContext, date: Date) {
        let progress = (date.timeIntervalSinceReferenceDate * 0.42).truncatingRemainder(dividingBy: 1)
        let x = CGFloat(progress) * size.width
        let rect = CGRect(x: x, y: 0, width: 5, height: size.height)
        context.fill(Path(rect), with: .color(.pixelInk.opacity(0.12)))
    }
}

private struct FrequencyHistogramRealtimeCanvas: View {
    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: 48) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawSpectrumGrid(in: size, context: context)
                drawHistogram(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
    }

    private func drawSpectrumGrid(in size: CGSize, context: GraphicsContext) {
        let baseline = size.height * 0.84

        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: baseline))
        axis.addLine(to: CGPoint(x: size.width, y: baseline))
        context.stroke(axis, with: .color(.pixelInk.opacity(0.32)), lineWidth: 1)

        for row in 0...3 {
            let y = baseline - CGFloat(row) * baseline / 3
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(
                path,
                with: .color(.pixelInk.opacity(row == 0 ? 0.18 : 0.08)),
                style: StrokeStyle(lineWidth: 1, dash: row == 0 ? [] : [4, 7])
            )
        }

        let tickCount = 6
        for tick in 0...tickCount {
            let x = CGFloat(tick) * size.width / CGFloat(tickCount)
            var path = Path()
            path.move(to: CGPoint(x: x, y: baseline + 3))
            path.addLine(to: CGPoint(x: x, y: baseline + 13))
            context.stroke(path, with: .color(.pixelInk.opacity(0.18)), lineWidth: 1)
        }
    }

    private func drawHistogram(in size: CGSize, context: GraphicsContext, date: Date) {
        let levels = displayLevels
        guard levels.isEmpty == false else {
            return
        }

        let baseline = size.height * 0.84
        let maxHeight = baseline * 0.82
        let slotWidth = size.width / CGFloat(levels.count)
        let barWidth = max(2, slotWidth * 0.58)
        let pulse = isActive ? 0.92 + 0.08 * sin(date.timeIntervalSinceReferenceDate * 8) : 0.52

        for index in levels.indices {
            let level = min(1, max(0, levels[index]))
            let eased = pow(level, 0.82)
            let height = max(isActive ? 2 : 1, CGFloat(eased) * maxHeight * CGFloat(pulse))
            let x = CGFloat(index) * slotWidth + slotWidth * 0.5
            let rect = CGRect(
                x: x - barWidth * 0.5,
                y: baseline - height,
                width: barWidth,
                height: height
            )
            let highBandMix = Double(index) / Double(max(1, levels.count - 1))
            let barColor = histogramColor(level: level, highBandMix: highBandMix)

            context.fill(
                Path(roundedRect: rect, cornerRadius: min(3, barWidth * 0.34)),
                with: .color(isActive ? barColor : .pixelInk.opacity(0.17 + level * 0.16))
            )

            if isActive, level > 0.18 {
                let capY = rect.minY - 4
                var cap = Path()
                cap.move(to: CGPoint(x: rect.minX + 1, y: capY))
                cap.addLine(to: CGPoint(x: rect.maxX - 1, y: capY))
                context.stroke(cap, with: .color(Color.pixelRed.opacity(0.42 + level * 0.42)), lineWidth: 1.4)
            }
        }

        drawFrequencyLabels(in: size, context: context, baseline: baseline)
    }

    private func drawFrequencyLabels(in size: CGSize, context: GraphicsContext, baseline: CGFloat) {
        let labels = ["LOW", "MID", "HIGH"]
        for (index, label) in labels.enumerated() {
            let x = CGFloat(index) * size.width / CGFloat(labels.count - 1)
            let resolvedText = context.resolve(
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(.pixelInk.opacity(0.45))
            )

            context.draw(
                resolvedText,
                at: CGPoint(
                    x: min(max(18, x), size.width - 22),
                    y: baseline + 24
                )
            )
        }
    }

    private func histogramColor(level: Double, highBandMix: Double) -> Color {
        if highBandMix > 0.72 {
            return Color.pixelRed.opacity(0.32 + level * 0.58)
        }

        if highBandMix > 0.38 {
            return Color(red: 0.96, green: 0.72, blue: 0.28).opacity(0.28 + level * 0.58)
        }

        return Color.mintGlow.opacity(0.26 + level * 0.62)
    }
}

private struct MitsuhaRealtimeCanvas: View {
    let levels: [Double]
    let isActive: Bool

    private var displayLevels: [Double] {
        levels.isEmpty ? Array(repeating: 0, count: 48) : levels
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawReferenceLines(in: size, context: context)
                drawMitsuhaWave(in: size, context: context, date: timeline.date)
            }
        }
        .animation(.easeOut(duration: 0.09), value: levels)
    }

    private func drawReferenceLines(in size: CGSize, context: GraphicsContext) {
        let midY = size.height * 0.52

        for offset in [-0.34, 0, 0.34] {
            let y = midY + size.height * CGFloat(offset)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(
                path,
                with: .color(.pixelInk.opacity(offset == 0 ? 0.16 : 0.07)),
                style: StrokeStyle(lineWidth: 1, dash: offset == 0 ? [] : [3, 7])
            )
        }
    }

    private func drawMitsuhaWave(in size: CGSize, context: GraphicsContext, date: Date) {
        let points = frequencyPoints(in: size, date: date)
        guard points.upper.count > 2, points.lower.count > 2 else {
            return
        }

        let midY = size.height * 0.52
        let upperPath = smoothPath(points: points.upper)
        let lowerPath = smoothPath(points: points.lower)
        let bodyPath = closedWavePath(upper: points.upper, lower: points.lower)
        let activeOpacity = isActive ? 1.0 : 0.36

        context.fill(
            bodyPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color.mintGlow.opacity(0.18 * activeOpacity),
                    Color(red: 0.38, green: 0.58, blue: 1.0).opacity(0.15 * activeOpacity),
                    Color.pixelRed.opacity(0.12 * activeOpacity)
                ]),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            )
        )

        drawGlow(path: upperPath, context: context, size: size, opacity: activeOpacity)
        drawGlow(path: lowerPath, context: context, size: size, opacity: activeOpacity * 0.72)

        context.stroke(
            upperPath,
            with: .linearGradient(
                Gradient(colors: [
                    .mintGlow.opacity(0.92 * activeOpacity),
                    Color(red: 0.55, green: 0.72, blue: 1.0).opacity(0.88 * activeOpacity),
                    .pixelRed.opacity(0.82 * activeOpacity)
                ]),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ),
            style: StrokeStyle(lineWidth: isActive ? 2.4 : 1.6, lineCap: .round, lineJoin: .round)
        )

        context.stroke(
            lowerPath,
            with: .linearGradient(
                Gradient(colors: [
                    .pixelRed.opacity(0.38 * activeOpacity),
                    Color(red: 0.55, green: 0.72, blue: 1.0).opacity(0.44 * activeOpacity),
                    .mintGlow.opacity(0.42 * activeOpacity)
                ]),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ),
            style: StrokeStyle(lineWidth: isActive ? 1.6 : 1.1, lineCap: .round, lineJoin: .round)
        )

        drawFrequencyPoints(points.upper, context: context, activeOpacity: activeOpacity)
    }

    private func drawGlow(path: Path, context: GraphicsContext, size: CGSize, opacity: Double) {
        for pass in 0..<3 {
            context.stroke(
                path,
                with: .color(Color.mintGlow.opacity((0.1 - Double(pass) * 0.026) * opacity)),
                style: StrokeStyle(lineWidth: CGFloat(10 - pass * 3), lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawFrequencyPoints(_ points: [CGPoint], context: GraphicsContext, activeOpacity: Double) {
        guard isActive else {
            return
        }

        for (index, point) in points.enumerated() where index % 4 == 0 {
            let dotSize = CGFloat(2.4 + min(1, max(0, displayLevels[min(index, displayLevels.count - 1)])) * 3.0)
            let rect = CGRect(
                x: point.x - dotSize * 0.5,
                y: point.y - dotSize * 0.5,
                width: dotSize,
                height: dotSize
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(Color.pixelPaper.opacity(0.28 * activeOpacity))
            )
        }
    }

    private func frequencyPoints(in size: CGSize, date: Date) -> (upper: [CGPoint], lower: [CGPoint]) {
        let levels = displayLevels
        let pointCount = max(28, levels.count)
        let midY = size.height * 0.52
        let maxHeight = size.height * 0.38
        let time = date.timeIntervalSinceReferenceDate
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []

        upper.reserveCapacity(pointCount)
        lower.reserveCapacity(pointCount)

        for index in 0..<pointCount {
            let levelIndex = min(levels.count - 1, index * levels.count / pointCount)
            let level = min(1, max(0, levels[levelIndex]))
            let progress = Double(index) / Double(max(1, pointCount - 1))
            let frequencySwell = 0.54 + 0.46 * sin(progress * Double.pi)
            let shimmer = isActive ? 0.88 + 0.12 * sin(time * 4.8 + Double(index) * 0.7) : 0.42
            let phaseRipple = isActive ? sin(time * 2.4 + progress * Double.pi * 5.4) * 0.08 : 0
            let shaped = pow(level, 0.54) * frequencySwell * shimmer
            let height = max(isActive ? 2.6 : 1.2, CGFloat(shaped + phaseRipple) * maxHeight)
            let x = CGFloat(progress) * size.width
            let lowerHeight = height * CGFloat(0.46 + 0.18 * sin(progress * Double.pi * 2 + time))

            upper.append(CGPoint(x: x, y: midY - height))
            lower.append(CGPoint(x: x, y: midY + lowerHeight))
        }

        return (upper, lower)
    }

    private func smoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else {
            return path
        }

        path.move(to: first)

        guard points.count > 2 else {
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            return path
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(
                x: (previous.x + current.x) * 0.5,
                y: (previous.y + current.y) * 0.5
            )
            path.addQuadCurve(to: mid, control: previous)
        }

        if let last = points.last {
            path.addLine(to: last)
        }

        return path
    }

    private func closedWavePath(upper: [CGPoint], lower: [CGPoint]) -> Path {
        var path = smoothPath(points: upper)

        for point in lower.reversed() {
            path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

private struct DSWaveformRealtimeCanvas: View {
    let samples: [Double]
    let isActive: Bool

    private var displaySamples: [Double] {
        samples.isEmpty ? Array(repeating: 0, count: 180) : samples
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                drawSilenceLine(in: size, context: context)
                drawWaveform(in: size, context: context)

                if isActive {
                    drawLiveCursor(in: size, context: context, date: timeline.date)
                }
            }
        }
        .animation(.easeOut(duration: 0.1), value: samples)
    }

    private func drawSilenceLine(in size: CGSize, context: GraphicsContext) {
        let midY = size.height * 0.52
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: size.width, y: midY))
        context.stroke(path, with: .color(.pixelInk.opacity(0.16)), style: StrokeStyle(lineWidth: 1, dash: [5, 6]))
    }

    private func drawWaveform(in size: CGSize, context: GraphicsContext) {
        let samples = displaySamples
        guard samples.count > 1 else {
            return
        }

        let midY = size.height * 0.52
        let maxHalfHeight = size.height * 0.42
        let xStep = size.width / CGFloat(samples.count - 1)
        let dampCount = max(1, Int(Double(samples.count) * 0.125))

        var upper: [CGPoint] = []
        var lower: [CGPoint] = []
        upper.reserveCapacity(samples.count)
        lower.reserveCapacity(samples.count)

        for index in samples.indices {
            let level = min(1, max(0, samples[index]))
            let damping = dampingFactor(index: index, count: samples.count, dampCount: dampCount)
            let eased = sqrt(level) * damping
            let x = CGFloat(index) * xStep
            let halfHeight = max(isActive ? 2.2 : 1, CGFloat(eased) * maxHalfHeight)
            upper.append(CGPoint(x: x, y: midY - halfHeight))
            lower.append(CGPoint(x: x, y: midY + halfHeight))
        }

        var fillPath = Path()
        fillPath.move(to: upper[0])
        addSmoothLine(to: &fillPath, points: upper)
        addSmoothLine(to: &fillPath, points: Array(lower.reversed()))
        fillPath.closeSubpath()

        let gradient = Gradient(colors: [
            Color.mintGlow.opacity(isActive ? 0.72 : 0.18),
            Color.amber.opacity(isActive ? 0.78 : 0.16),
            Color.pixelRed.opacity(isActive ? 0.54 : 0.12)
        ])
        context.fill(
            fillPath,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )
        context.stroke(fillPath, with: .color(.pixelInk.opacity(isActive ? 0.26 : 0.12)), lineWidth: 1)
    }

    private func addSmoothLine(to path: inout Path, points: [CGPoint]) {
        guard points.count > 1 else {
            return
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) * 0.5, y: (previous.y + current.y) * 0.5)
            path.addQuadCurve(to: midpoint, control: previous)
        }

        if let lastPoint = points.last {
            path.addLine(to: lastPoint)
        }
    }

    private func dampingFactor(index: Int, count: Int, dampCount: Int) -> Double {
        let leading = min(1, Double(index + 1) / Double(dampCount))
        let trailing = min(1, Double(count - index) / Double(dampCount))
        return min(leading, trailing)
    }

    private func drawLiveCursor(in size: CGSize, context: GraphicsContext, date: Date) {
        let pulse = 0.42 + 0.28 * sin(date.timeIntervalSinceReferenceDate * 7)
        let x = size.width - 4
        var path = Path()
        path.move(to: CGPoint(x: x, y: 8))
        path.addLine(to: CGPoint(x: x, y: size.height - 8))
        context.stroke(path, with: .color(.pixelRed.opacity(pulse)), lineWidth: 2)
    }
}

struct RetroDeckView: View {
    @Environment(\.appLanguage) private var appLanguage

    let style: CassetteDeckStyle
    let isRecording: Bool
    let isPaused: Bool
    let elapsed: TimeInterval
    let powerLevel: Double
    let leftLevel: Double
    let rightLevel: Double
    let liveText: String
    let isLiveTextActive: Bool
    var canAddTag = false
    var currentTagTimeText = "00:00"
    var hasCurrentTag = false
    var onAddTag: () -> RecordingTagAddResult? = { nil }

    private var isMoving: Bool {
        isRecording && !isPaused
    }

    var body: some View {
        let theme = style.theme

        VStack(spacing: 10) {
            CassetteBodyView(style: style, isMoving: isMoving, powerLevel: powerLevel, compact: false)
                .frame(maxWidth: .infinity)
                .frame(height: 214)

            StereoLevelPanel(leftLevel: leftLevel, rightLevel: rightLevel, isActive: isMoving)

            VStack(spacing: 6) {
                Text(isRecording ? RecordingItem.format(elapsed) : " ")
                    .retroFont(size: 36, weight: .black, design: .monospaced)
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                DeckLiveTextLine(
                    label: appLanguage.text(.liveText).uppercased(),
                    text: liveText,
                    isActive: isLiveTextActive,
                    canAddTag: canAddTag,
                    currentTagTimeText: currentTagTimeText,
                    hasCurrentTag: hasCurrentTag,
                    onAddTag: onAddTag
                )
            }
        }
        .padding(14)
        .background(theme.panel, in: PixelCornerShape(cornerRadius: 6))
        .overlay {
            PixelCornerShape(cornerRadius: 6)
                .stroke(theme.border.opacity(0.78), lineWidth: 2)
        }
    }
}

private struct DeckLiveTextLine: View {
    @Environment(\.appLanguage) private var appLanguage
    @State private var showingFullText = false
    @State private var contentHeight: CGFloat = 0

    let label: String
    let text: String
    let isActive: Bool
    var canAddTag = false
    var currentTagTimeText = "00:00"
    var hasCurrentTag = false
    var onAddTag: () -> RecordingTagAddResult? = { nil }

    private var displayText: String {
        text.isEmpty ? " " : text
    }

    private var visibleTextHeight: CGFloat {
        let oneLine: CGFloat = 17
        let twoLines: CGFloat = 38
        return min(max(oneLine, contentHeight), twoLines)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .retroFont(size: 10, weight: .black, design: .monospaced)
                .foregroundStyle(.cream.opacity(0.54))
                .lineLimit(1)

            if isActive {
                DeckLiveDot()
            }

            liveTextWindow

            Button {
                showingFullText = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(text.isEmpty ? .cream.opacity(0.24) : .cream)
                    .frame(width: 25, height: 25)
                    .background(.cream.opacity(0.08), in: PixelCornerShape(cornerRadius: 3))
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
            .accessibilityLabel(appLanguage.text(.liveText))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.28), in: PixelCornerShape(cornerRadius: 4))
        .overlay {
            PixelCornerShape(cornerRadius: 4)
                .stroke(.cream.opacity(0.14), lineWidth: 1)
        }
        .sheet(isPresented: $showingFullText) {
            LiveTextDetailSheet(
                title: appLanguage.text(.liveText),
                text: text,
                canAddTag: canAddTag,
                currentTagTimeText: currentTagTimeText,
                hasCurrentTag: hasCurrentTag,
                onAddTag: onAddTag
            )
        }
    }

    private var liveTextWindow: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: contentHeight > visibleTextHeight + 1) {
                Text(displayText)
                    .retroFont(size: 13, weight: .bold, design: .monospaced)
                    .lineSpacing(2)
                    .foregroundStyle(.cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: LiveTextContentHeightKey.self, value: geometry.size.height)
                        }
                    }
                    .id("live-text-bottom")
            }
            .scrollDisabled(contentHeight <= visibleTextHeight + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: visibleTextHeight)
            .clipped()
            .onPreferenceChange(LiveTextContentHeightKey.self) { height in
                contentHeight = height
                scrollToBottom(proxy)
            }
            .onChange(of: text) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo("live-text-bottom", anchor: .bottom)
            }
        }
    }
}

private struct LiveTextContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct LiveTextDetailSheet: View {
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
                    .foregroundStyle(.cream)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }
            .background(Color.deckPanel.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if canAddTag {
                    bottomTagButton
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

    private var bottomTagButton: some View {
        Button {
            addCurrentTag()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: hasCurrentTag ? "tag.fill" : "tag")
                    .font(.system(size: 15, weight: .black))

                Text("TAG \(currentTagTimeText)")
                    .retroFont(size: 15, weight: .black, design: .monospaced)
            }
            .foregroundStyle(hasCurrentTag ? .pixelPaper : .cream)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                hasCurrentTag ? Color.pixelRed.opacity(0.92) : Color.pixelInk.opacity(0.84),
                in: PixelCornerShape(cornerRadius: 5)
            )
            .overlay {
                PixelCornerShape(cornerRadius: 5)
                    .stroke(.cream.opacity(hasCurrentTag ? 0.28 : 0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.deckPanel.opacity(0.96))
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

private struct DeckLiveDot: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let isOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0

            Rectangle()
                .fill(isOn ? Color.pixelRed : Color.cream.opacity(0.18))
                .frame(width: 7, height: 7)
        }
    }
}

private struct PixelDottedGrille: View {
    var body: some View {
        GeometryReader { proxy in
            let columns = max(1, Int(proxy.size.width / 10))
            let rows = max(1, Int(proxy.size.height / 8))

            Grid(horizontalSpacing: 7, verticalSpacing: 5) {
                ForEach(0..<rows, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<columns, id: \.self) { index in
                            Rectangle()
                                .fill(Color.pixelInk.opacity(index % 5 == 0 ? 0.36 : 0.76))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct PixelCassetteBody: View {
    let isMoving: Bool
    let powerLevel: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let leftRotation = isMoving ? Angle.degrees(time * (145 + powerLevel * 130)) : .degrees(0)
            let rightRotation = isMoving ? Angle.degrees(time * -(128 + powerLevel * 110)) : .degrees(0)

            ZStack {
                PixelCornerShape(cornerRadius: 12)
                    .fill(Color.pixelInk)

                PixelCornerShape(cornerRadius: 8)
                    .fill(Color.pixelPaper)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)

                HStack {
                    PixelReel(rotation: leftRotation)
                    Spacer()
                    PixelReel(rotation: rightRotation)
                }
                .padding(.horizontal, 48)

                VStack(spacing: 8) {
                    HStack(spacing: 9) {
                        Rectangle()
                            .fill(isMoving ? Color.pixelRed : Color.pixelInk.opacity(0.22))
                            .frame(width: 12, height: 12)

                        Text(isMoving ? "REC" : "REC")
                            .retroFont(size: 18, weight: .black, design: .monospaced)
                            .foregroundStyle(isMoving ? .pixelRed : .pixelInk.opacity(0.38))
                    }

                    PixelCenterTicks()
                        .frame(width: 44, height: 52)
                }
            }
        }
    }
}

private struct PixelReel: View {
    let rotation: Angle

    var body: some View {
        ZStack {
            PixelCornerShape(cornerRadius: 4)
                .fill(Color.pixelInk)
                .frame(width: 82, height: 76)

            Circle()
                .fill(Color.pixelPaper)
                .frame(width: 58, height: 58)

            Circle()
                .fill(Color.pixelInk)
                .frame(width: 24, height: 24)

            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(Color.pixelInk)
                    .frame(width: 7, height: 18)
                    .offset(y: -22)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Rectangle()
                .fill(Color.pixelPaper)
                .frame(width: 6, height: 6)
        }
        .rotationEffect(rotation)
    }
}

private struct PixelCenterTicks: View {
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(0..<3, id: \.self) { column in
                VStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { row in
                        Rectangle()
                            .fill(Color.pixelInk.opacity(column == 1 || row % 2 == 0 ? 0.8 : 0.38))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}

private struct PixelVerticalMeter: View {
    let label: String
    let level: Double
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .retroFont(size: 18, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk)

            VStack(spacing: 5) {
                ForEach((0..<8).reversed(), id: \.self) { index in
                    Rectangle()
                        .fill(color(for: index))
                        .frame(width: 24, height: 6)
                }
            }
        }
        .frame(width: 44)
    }

    private func color(for index: Int) -> Color {
        guard isActive, index < Int((min(1, max(0, level)) * 8).rounded(.up)) else {
            return Color.pixelInk.opacity(0.2)
        }

        return index > 5 ? .pixelRed : .mintGlow
    }
}

private struct SourceStatusButton: View {
    @Environment(\.appLanguage) private var appLanguage

    let title: String
    let systemName: String
    let tint: Color
    let isSelectable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .black))
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 1) {
                    Text(appLanguage.text(.currentSource))
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.cream.opacity(0.46))
                        .lineLimit(1)

                    Text(title)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(isSelectable ? tint : .cream.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                if isSelectable {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(tint.opacity(0.88))
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .frame(maxWidth: 184, minHeight: 42, alignment: .leading)
            .background(.black.opacity(0.22), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelectable ? tint.opacity(0.38) : .cream.opacity(0.08), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isSelectable)
        .accessibilityLabel(appLanguage.text(.source))
    }
}

private struct NoiseReductionStatusMenu: View {
    @Environment(\.appLanguage) private var appLanguage

    let selectedMode: NoiseReductionMode
    let tint: Color
    let isSelectable: Bool
    let onSelect: (NoiseReductionMode) -> Void

    var body: some View {
        Menu {
            ForEach(NoiseReductionMode.allCases) { mode in
                Button {
                    guard mode.isAvailable else {
                        return
                    }

                    onSelect(mode)
                } label: {
                    Label(menuTitle(for: mode), systemImage: selectedMode == mode ? "checkmark" : mode.iconName)
                }
                .disabled(!mode.isAvailable)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: selectedMode.iconName)
                    .font(.system(size: 12, weight: .black))
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 1) {
                    Text(appLanguage.text(.noiseReduction))
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.cream.opacity(0.46))
                        .lineLimit(1)

                    Text(selectedMode.title(language: appLanguage))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(isSelectable ? tint : .cream.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                if isSelectable {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(tint.opacity(0.88))
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .frame(maxWidth: 156, minHeight: 42, alignment: .leading)
            .background(.black.opacity(0.22), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelectable ? tint.opacity(0.38) : .cream.opacity(0.08), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isSelectable)
        .accessibilityLabel(appLanguage.text(.noiseReduction))
    }

    private func menuTitle(for mode: NoiseReductionMode) -> String {
        let title = mode.title(language: appLanguage)
        let suffix = mode.isAvailable ? mode.subtitle(language: appLanguage) : appLanguage.text(.requiresRuntime)
        return selectedMode == mode ? "✓ \(title) · \(suffix)" : "\(title) · \(suffix)"
    }
}

struct CassetteStyleThumbnail: View {
    let style: CassetteDeckStyle

    var body: some View {
        CassetteBodyView(style: style, isMoving: false, powerLevel: 0.38, compact: true)
            .padding(8)
            .background(style.theme.panel, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.cream.opacity(0.12), lineWidth: 1)
            }
    }
}

private struct CassetteTheme {
    let panel: Color
    let shellTop: Color
    let shellBottom: Color
    let border: Color
    let label: Color
    let labelLine: Color
    let primaryText: Color
    let secondaryText: Color
    let window: Color
    let reelFace: Color
    let reelRing: Color
    let tape: Color
    let lower: Color
    let accent: Color
    let stripeColors: [Color]
    let brand: String
    let side: String
    let length: String
    let note: String
    let isTransparent: Bool
}

private struct CassetteBodyView: View {
    let style: CassetteDeckStyle
    let isMoving: Bool
    let powerLevel: Double
    let compact: Bool

    var body: some View {
        if style == .lineSketch {
            LineTapeMachineView(isMoving: isMoving, powerLevel: powerLevel)
        } else {
            CassetteShellView(
                theme: style.theme,
                isMoving: isMoving,
                powerLevel: powerLevel,
                compact: compact
            )
        }
    }
}

private struct CassetteShellView: View {
    let theme: CassetteTheme
    let isMoving: Bool
    let powerLevel: Double
    let compact: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rotation = isMoving ? Angle.degrees(time * (160 + powerLevel * 170)) : .degrees(0)
                let counterRotation = isMoving ? Angle.degrees(time * -(138 + powerLevel * 150)) : .degrees(0)
                let reelSize = min(size.width * 0.22, size.height * 0.42)
                let windowHeight = size.height * (compact ? 0.28 : 0.31)
                let shellRadius: CGFloat = compact ? 5 : 8

                ZStack {
                    RoundedRectangle(cornerRadius: shellRadius)
                        .fill(
                            LinearGradient(
                                colors: [theme.shellTop, theme.shellBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            if theme.isTransparent {
                                TransparentRidges()
                                    .stroke(theme.border.opacity(0.45), lineWidth: 1)
                                    .padding(size.width * 0.04)
                            }
                        }

                    RoundedRectangle(cornerRadius: shellRadius)
                        .stroke(theme.border, lineWidth: compact ? 1 : 1.4)

                    VStack(spacing: 0) {
                        topLabel
                            .frame(height: size.height * 0.28)
                            .padding(.horizontal, size.width * 0.06)
                            .padding(.top, size.height * 0.055)

                        Spacer()
                    }

                    stripeStack
                        .frame(width: size.width * 0.72, height: max(12, size.height * 0.15))
                        .position(x: size.width * 0.5, y: size.height * 0.47)

                    tapeWindow
                        .frame(width: size.width * 0.46, height: windowHeight)
                        .position(x: size.width * 0.5, y: size.height * 0.5)

                    TapeSpoolView(theme: theme, side: .left, powerLevel: powerLevel)
                        .frame(width: reelSize * 1.34, height: reelSize * 1.34)
                        .position(x: size.width * 0.29, y: size.height * 0.5)
                        .opacity(theme.isTransparent ? 0.68 : 0.36)

                    TapeSpoolView(theme: theme, side: .right, powerLevel: powerLevel)
                        .frame(width: reelSize * 1.22, height: reelSize * 1.22)
                        .position(x: size.width * 0.71, y: size.height * 0.5)
                        .opacity(theme.isTransparent ? 0.68 : 0.36)

                    CassetteReelView(rotation: rotation, theme: theme)
                        .frame(width: reelSize, height: reelSize)
                        .position(x: size.width * 0.29, y: size.height * 0.5)

                    CassetteReelView(rotation: counterRotation, theme: theme)
                        .frame(width: reelSize, height: reelSize)
                        .position(x: size.width * 0.71, y: size.height * 0.5)

                    centerTapeMarks
                        .frame(width: size.width * 0.18, height: max(20, size.height * 0.16))
                        .position(x: size.width * 0.5, y: size.height * 0.5)

                    lowerPanel
                        .frame(height: size.height * 0.28)
                        .position(x: size.width * 0.5, y: size.height * 0.82)

                    screwField
                }
                .clipShape(RoundedRectangle(cornerRadius: shellRadius))
                .shadow(color: theme.accent.opacity(isMoving ? 0.2 : 0.08), radius: isMoving ? 18 : 8)
            }
        }
        .aspectRatio(1.72, contentMode: .fit)
    }

    private var topLabel: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(theme.side)
                    .font(.system(size: compact ? 8 : 15, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 8)

                Text(theme.note)
                    .font(.system(size: compact ? 6 : 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.primaryText.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }

            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(theme.labelLine)
                    .frame(height: compact ? 0.7 : 1)
            }
        }
        .padding(.horizontal, compact ? 7 : 12)
        .padding(.vertical, compact ? 5 : 9)
        .background(theme.label, in: RoundedRectangle(cornerRadius: compact ? 3 : 5))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 3 : 5)
                .stroke(theme.labelLine.opacity(0.5), lineWidth: 1)
        }
    }

    private var stripeStack: some View {
        VStack(spacing: 0) {
            ForEach(Array(theme.stripeColors.enumerated()), id: \.offset) { _, color in
                Rectangle()
                    .fill(color)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: compact ? 2 : 4))
    }

    private var tapeWindow: some View {
        RoundedRectangle(cornerRadius: compact ? 5 : 8)
            .fill(theme.window.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 5 : 8)
                    .stroke(theme.border.opacity(0.75), lineWidth: compact ? 1 : 1.5)
            }
            .shadow(color: .black.opacity(0.34), radius: 8, y: 4)
    }

    private var centerTapeMarks: some View {
        HStack(alignment: .center, spacing: compact ? 3 : 6) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(theme.labelLine.opacity(index == 3 ? 0.8 : 0.45))
                    .frame(width: compact ? 1.5 : 2.5, height: index == 3 ? (compact ? 22 : 38) : (compact ? 11 : 22))
            }
        }
    }

    private var lowerPanel: some View {
        VStack(spacing: compact ? 4 : 8) {
            HStack {
                Text(theme.brand)
                    .font(.system(size: compact ? 10 : 23, weight: .black, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer()

                Text(theme.length)
                    .font(.system(size: compact ? 12 : 25, weight: .black, design: .monospaced))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            HStack(spacing: compact ? 7 : 13) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: compact ? 2 : 4)
                        .fill(index == 1 ? theme.border.opacity(0.5) : Color.black.opacity(0.35))
                        .frame(width: compact ? 12 : 28, height: compact ? 5 : 12)
                }
            }
        }
        .padding(.horizontal, compact ? 10 : 18)
        .padding(.vertical, compact ? 7 : 13)
        .background(theme.lower.opacity(0.92), in: UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 4))
    }

    private var screwField: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let inset = compact ? size.width * 0.035 : size.width * 0.04
            let points = [
                CGPoint(x: inset, y: inset),
                CGPoint(x: size.width - inset, y: inset),
                CGPoint(x: inset, y: size.height - inset),
                CGPoint(x: size.width - inset, y: size.height - inset),
                CGPoint(x: size.width * 0.5, y: size.height * 0.72)
            ]

            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                CassetteScrewView(color: theme.border)
                    .frame(width: compact ? 10 : 17, height: compact ? 10 : 17)
                    .position(point)
            }
        }
    }
}

private struct TapeSpoolView: View {
    enum Side {
        case left
        case right
    }

    let theme: CassetteTheme
    let side: Side
    let powerLevel: Double

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let scale = side == .left ? 0.86 + powerLevel * 0.1 : 0.7 + powerLevel * 0.08

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.tape.opacity(0.18),
                            theme.tape.opacity(0.68),
                            theme.tape.opacity(0.92)
                        ],
                        center: .center,
                        startRadius: diameter * 0.12,
                        endRadius: diameter * 0.5
                    )
                )
                .scaleEffect(scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CassetteReelView: View {
    let rotation: Angle
    let theme: CassetteTheme

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let slotWidth = max(4, side * 0.085)
            let slotHeight = max(12, side * 0.28)

            ZStack {
                Circle()
                    .fill(theme.reelFace)
                    .overlay {
                        Circle()
                            .stroke(theme.reelRing, lineWidth: max(2, side * 0.045))
                    }

                Circle()
                    .stroke(theme.reelRing.opacity(0.32), lineWidth: max(1, side * 0.025))
                    .padding(side * 0.16)

                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(theme.window.opacity(0.72))
                        .frame(width: slotWidth, height: slotHeight)
                        .offset(y: -side * 0.24)
                        .rotationEffect(.degrees(Double(index) * 60))
                }

                Circle()
                    .fill(theme.window.opacity(0.92))
                    .frame(width: side * 0.32, height: side * 0.32)

                Circle()
                    .stroke(theme.secondaryText.opacity(0.65), lineWidth: max(1, side * 0.025))
                    .frame(width: side * 0.22, height: side * 0.22)
            }
            .rotationEffect(rotation)
            .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
        }
    }
}

private struct CassetteScrewView: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.28))

                Circle()
                    .stroke(color.opacity(0.7), lineWidth: max(1, side * 0.09))

                Rectangle()
                    .fill(color.opacity(0.62))
                    .frame(width: side * 0.62, height: max(1, side * 0.1))
                    .rotationEffect(.degrees(-28))
            }
        }
    }
}

private struct TransparentRidges: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stride = max(14, rect.width / 10)
        var x = rect.minX

        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x + stride * 0.42, y: rect.maxY))
            x += stride
        }

        return path
    }
}

private struct LineTapeMachineView: View {
    let isMoving: Bool
    let powerLevel: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rotation = isMoving ? time * (2.2 + powerLevel * 1.6) : 0
                let ink = Color.cream.opacity(0.92)
                let softInk = Color.cream.opacity(0.62)
                let line = StrokeStyle(lineWidth: max(1.8, size.width * 0.005), lineCap: .round, lineJoin: .round)
                let thinLine = StrokeStyle(lineWidth: max(1.1, size.width * 0.003), lineCap: .round, lineJoin: .round)
                let w = size.width
                let h = size.height

                var bodyPath = Path()
                bodyPath.move(to: CGPoint(x: w * 0.07, y: h * 0.25))
                bodyPath.addLine(to: CGPoint(x: w * 0.24, y: h * 0.18))
                bodyPath.addQuadCurve(
                    to: CGPoint(x: w * 0.5, y: h * 0.20),
                    control: CGPoint(x: w * 0.38, y: h * 0.15)
                )
                bodyPath.addQuadCurve(
                    to: CGPoint(x: w * 0.76, y: h * 0.18),
                    control: CGPoint(x: w * 0.62, y: h * 0.25)
                )
                bodyPath.addLine(to: CGPoint(x: w * 0.93, y: h * 0.25))
                bodyPath.addLine(to: CGPoint(x: w * 0.93, y: h * 0.72))
                bodyPath.addLine(to: CGPoint(x: w * 0.07, y: h * 0.72))
                bodyPath.closeSubpath()
                context.stroke(bodyPath, with: .color(ink), style: line)

                var handle = Path()
                handle.move(to: CGPoint(x: w * 0.45, y: h * 0.02))
                handle.addLine(to: CGPoint(x: w * 0.45, y: h * 0.19))
                handle.move(to: CGPoint(x: w * 0.55, y: h * 0.02))
                handle.addLine(to: CGPoint(x: w * 0.55, y: h * 0.19))
                context.stroke(handle, with: .color(ink), style: line)

                drawReel(
                    context: context,
                    center: CGPoint(x: w * 0.21, y: h * 0.58),
                    radius: min(w * 0.14, h * 0.28),
                    rotation: rotation,
                    ink: ink,
                    softInk: softInk,
                    line: line,
                    thinLine: thinLine
                )

                drawReel(
                    context: context,
                    center: CGPoint(x: w * 0.79, y: h * 0.58),
                    radius: min(w * 0.14, h * 0.28),
                    rotation: -rotation * 0.92,
                    ink: ink,
                    softInk: softInk,
                    line: line,
                    thinLine: thinLine
                )

                drawScrews(context: context, size: size, ink: ink, line: thinLine)
                drawTapeRun(context: context, size: size, ink: softInk, line: thinLine)
                drawScale(context: context, size: size, ink: ink)
            }
        }
    }

    private func drawReel(
        context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        rotation: Double,
        ink: Color,
        softInk: Color,
        line: StrokeStyle,
        thinLine: StrokeStyle
    ) {
        var outer = Path()
        outer.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.stroke(outer, with: .color(ink), style: line)

        var inner = Path()
        inner.addEllipse(in: CGRect(
            x: center.x - radius * 0.88,
            y: center.y - radius * 0.88,
            width: radius * 1.76,
            height: radius * 1.76
        ))
        context.stroke(inner, with: .color(softInk), style: thinLine)

        var hub = Path()
        hub.addEllipse(in: CGRect(
            x: center.x - radius * 0.12,
            y: center.y - radius * 0.12,
            width: radius * 0.24,
            height: radius * 0.24
        ))
        context.stroke(hub, with: .color(ink), style: line)

        for index in 0..<4 {
            let angle = rotation + Double(index) * .pi / 2
            let start = point(center: center, radius: radius * 0.72, angle: angle)
            let end = point(center: center, radius: radius * 0.92, angle: angle + 0.1)
            var mark = Path()
            mark.move(to: start)
            mark.addLine(to: end)
            context.stroke(mark, with: .color(ink), style: line)
        }
    }

    private func drawScrews(context: GraphicsContext, size: CGSize, ink: Color, line: StrokeStyle) {
        let points = [
            CGPoint(x: size.width * 0.09, y: size.height * 0.27),
            CGPoint(x: size.width * 0.28, y: size.height * 0.08),
            CGPoint(x: size.width * 0.72, y: size.height * 0.08),
            CGPoint(x: size.width * 0.91, y: size.height * 0.27),
            CGPoint(x: size.width * 0.38, y: size.height * 0.24),
            CGPoint(x: size.width * 0.62, y: size.height * 0.24)
        ]

        for point in points {
            var screw = Path()
            screw.addEllipse(in: CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14))
            context.stroke(screw, with: .color(ink), style: line)
        }
    }

    private func drawTapeRun(context: GraphicsContext, size: CGSize, ink: Color, line: StrokeStyle) {
        var tape = Path()
        tape.move(to: CGPoint(x: size.width * 0.27, y: size.height * 0.18))
        tape.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.2))
        tape.addLine(to: CGPoint(x: size.width * 0.73, y: size.height * 0.18))
        context.stroke(tape, with: .color(ink), style: line)
    }

    private func drawScale(context: GraphicsContext, size: CGSize, ink: Color) {
        let centerX = size.width * 0.5
        let baseY = size.height * 0.64
        let width = size.width * 0.26
        let tickCount = 17

        for index in 0..<tickCount {
            let progress = CGFloat(index) / CGFloat(tickCount - 1)
            let x = centerX - width / 2 + width * progress
            let height: CGFloat = index == tickCount / 2 ? 42 : (index % 2 == 0 ? 16 : 10)
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: baseY))
            tick.addLine(to: CGPoint(x: x, y: baseY - height))
            context.stroke(tick, with: .color(ink.opacity(index == tickCount / 2 ? 0.9 : 0.68)), lineWidth: 1.2)
        }
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

private struct StereoLevelPanel: View {
    let leftLevel: Double
    let rightLevel: Double
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            LevelWindow(label: "L", level: leftLevel, isActive: isActive)
            LevelWindow(label: "R", level: rightLevel, isActive: isActive)
        }
    }
}

private struct LevelWindow: View {
    let label: String
    let level: Double
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(.cream.opacity(0.8))
                .frame(width: 18)

            GeometryReader { proxy in
                let barCount = 18
                let spacing: CGFloat = 3
                let width = max(1, (proxy.size.width - CGFloat(barCount - 1) * spacing) / CGFloat(barCount))
                let activeBars = Int((min(1, max(0, level)) * Double(barCount)).rounded(.up))

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let heightScale = 0.32 + CGFloat(index % 6) * 0.115

                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(color(for: index, activeBars: activeBars))
                            .frame(width: width, height: proxy.size.height * heightScale)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(height: 48)
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.cream.opacity(isActive ? 0.26 : 0.12), lineWidth: 1)
        }
    }

    private func color(for index: Int, activeBars: Int) -> Color {
        guard index < activeBars else {
            return Color.cream.opacity(0.16)
        }

        if index > 14 {
            return .pixelInk.opacity(0.92)
        }

        if index > 10 {
            return .amber.opacity(0.95)
        }

        return .mintGlow.opacity(0.9)
    }
}

struct InterfaceThemePalette {
    let deckPanel: UIColor
    let reelOuter: UIColor
    let meterFace: UIColor
    let cream: UIColor
    let amber: UIColor
    let mintGlow: UIColor
    let needle: UIColor
    let pixelPaper: UIColor
    let pixelPanel: UIColor
    let pixelInk: UIColor
    let pixelRed: UIColor
    let appBackgroundTop: UIColor
    let appBackgroundMiddle: UIColor
    let appBackgroundBottom: UIColor
}

enum InterfaceColorTheme: String, CaseIterable, Identifiable {
    case pocketOlive
    case lcdGray
    case amberCRT
    case phosphorGreen
    case cobaltTerminal
    case dracula
    case solarized
    case nord
    case gruvbox
    case catppuccin
    case monokai

    static let storageKey = "interfaceColorTheme"

    var id: String { rawValue }

    static func value(for rawValue: String) -> InterfaceColorTheme {
        InterfaceColorTheme(rawValue: rawValue) ?? .pocketOlive
    }

    static var current: InterfaceColorTheme {
        value(for: UserDefaults.standard.string(forKey: storageKey) ?? InterfaceColorTheme.pocketOlive.rawValue)
    }

    var title: String {
        switch self {
        case .pocketOlive:
            return "Pocket Olive"
        case .lcdGray:
            return "LCD Gray"
        case .amberCRT:
            return "Amber CRT"
        case .phosphorGreen:
            return "Phosphor Green"
        case .cobaltTerminal:
            return "Cobalt Terminal"
        case .dracula:
            return "Dracula"
        case .solarized:
            return "Solarized"
        case .nord:
            return "Nord"
        case .gruvbox:
            return "Gruvbox"
        case .catppuccin:
            return "Catppuccin"
        case .monokai:
            return "Monokai"
        }
    }

    func subtitle(language: AppLanguage) -> String {
        if language.resolvedLanguage == .english {
            switch self {
            case .pocketOlive:
                return "Icon-matched olive handheld"
            case .lcdGray:
                return "Classic grayscale LCD"
            case .amberCRT:
                return "Warm amber monitor"
            case .phosphorGreen:
                return "Green phosphor display"
            case .cobaltTerminal:
                return "Cobalt and cyan console"
            case .dracula:
                return "Purple terminal contrast"
            case .solarized:
                return "Balanced cyan console"
            case .nord:
                return "Arctic blue-gray"
            case .gruvbox:
                return "Warm retro terminal"
            case .catppuccin:
                return "Soft mocha console"
            case .monokai:
                return "High-contrast coding"
            }
        }

        switch self {
        case .pocketOlive:
            return "图标同款橄榄掌机色"
        case .lcdGray:
            return "经典灰阶 LCD"
        case .amberCRT:
            return "暖色琥珀显示器"
        case .phosphorGreen:
            return "绿色磷光屏"
        case .cobaltTerminal:
            return "钴蓝青色终端"
        case .dracula:
            return "紫色终端对比"
        case .solarized:
            return "青蓝平衡终端"
        case .nord:
            return "冷调蓝灰"
        case .gruvbox:
            return "暖色复古终端"
        case .catppuccin:
            return "柔和摩卡终端"
        case .monokai:
            return "高对比代码风"
        }
    }

    var previewSwatches: [Color] {
        let colors = darkPalette
        return [
            Color(colors.appBackgroundMiddle),
            Color(colors.pixelPanel),
            Color(colors.pixelPaper),
            Color(colors.pixelInk),
            Color(colors.mintGlow),
            Color(colors.pixelRed)
        ]
    }

    func palette(for traits: UITraitCollection) -> InterfaceThemePalette {
        traits.userInterfaceStyle == .dark ? darkPalette : lightPalette
    }

    private var darkPalette: InterfaceThemePalette {
        switch self {
        case .pocketOlive:
            return InterfaceThemePalette(
                deckPanel: uiColor(0x2B2C22),
                reelOuter: uiColor(0x171812),
                meterFace: uiColor(0x979966),
                cream: uiColor(0xE8E2CF),
                amber: uiColor(0xA94232),
                mintGlow: uiColor(0xB4B77D),
                needle: uiColor(0xA94232),
                pixelPaper: uiColor(0x3C3F2E),
                pixelPanel: uiColor(0x565943),
                pixelInk: uiColor(0xF0EAD7),
                pixelRed: uiColor(0xB44836),
                appBackgroundTop: uiColor(0x14150F),
                appBackgroundMiddle: uiColor(0x202219),
                appBackgroundBottom: uiColor(0x181A13)
            )
        case .lcdGray:
            return InterfaceThemePalette(
                deckPanel: UIColor(red: 0.04, green: 0.04, blue: 0.045, alpha: 1),
                reelOuter: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
                meterFace: UIColor(red: 0.78, green: 0.78, blue: 0.74, alpha: 1),
                cream: UIColor(red: 0.86, green: 0.86, blue: 0.83, alpha: 1),
                amber: UIColor(red: 0.72, green: 0.72, blue: 0.68, alpha: 1),
                mintGlow: UIColor(red: 0.94, green: 0.94, blue: 0.90, alpha: 1),
                needle: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1),
                pixelPaper: UIColor(red: 0.09, green: 0.09, blue: 0.095, alpha: 1),
                pixelPanel: UIColor(red: 0.17, green: 0.17, blue: 0.175, alpha: 1),
                pixelInk: UIColor(red: 0.91, green: 0.91, blue: 0.88, alpha: 1),
                pixelRed: UIColor(red: 0.78, green: 0.78, blue: 0.74, alpha: 1),
                appBackgroundTop: UIColor(red: 0.02, green: 0.02, blue: 0.022, alpha: 1),
                appBackgroundMiddle: UIColor(red: 0.07, green: 0.07, blue: 0.074, alpha: 1),
                appBackgroundBottom: UIColor(red: 0.03, green: 0.03, blue: 0.034, alpha: 1)
            )
        case .amberCRT:
            return terminalPalette(background: 0x120E08, panel: 0x2B2112, paper: 0x3A2C15, ink: 0xFFE9B5, accent: 0xFFB000, secondary: 0xFFD36A, alert: 0xE65C3A)
        case .phosphorGreen:
            return terminalPalette(background: 0x06110B, panel: 0x0C2819, paper: 0x123A23, ink: 0xD5FFE1, accent: 0x46F58A, secondary: 0xA2FFC0, alert: 0xFF6B5F)
        case .cobaltTerminal:
            return terminalPalette(background: 0x0B1020, panel: 0x172442, paper: 0x203257, ink: 0xF1F6FF, accent: 0x63D7FF, secondary: 0xF3D96B, alert: 0xFF6B7A)
        case .dracula:
            return terminalPalette(background: 0x282A36, panel: 0x44475A, paper: 0x343746, ink: 0xF8F8F2, accent: 0xBD93F9, secondary: 0x50FA7B, alert: 0xFF5555)
        case .solarized:
            return terminalPalette(background: 0x002B36, panel: 0x073642, paper: 0x0B3A46, ink: 0xEEE8D5, accent: 0x2AA198, secondary: 0xB58900, alert: 0xDC322F)
        case .nord:
            return terminalPalette(background: 0x2E3440, panel: 0x3B4252, paper: 0x434C5E, ink: 0xECEFF4, accent: 0x88C0D0, secondary: 0xA3BE8C, alert: 0xBF616A)
        case .gruvbox:
            return terminalPalette(background: 0x282828, panel: 0x3C3836, paper: 0x504945, ink: 0xEBDBB2, accent: 0xFABD2F, secondary: 0xB8BB26, alert: 0xFB4934)
        case .catppuccin:
            return terminalPalette(background: 0x1E1E2E, panel: 0x313244, paper: 0x45475A, ink: 0xCDD6F4, accent: 0x89B4FA, secondary: 0xA6E3A1, alert: 0xF38BA8)
        case .monokai:
            return terminalPalette(background: 0x2D2A2E, panel: 0x403E41, paper: 0x5B595C, ink: 0xFCFCFA, accent: 0xFFD866, secondary: 0xA9DC76, alert: 0xFF6188)
        }
    }

    private var lightPalette: InterfaceThemePalette {
        switch self {
        case .pocketOlive:
            return InterfaceThemePalette(
                deckPanel: uiColor(0xB4AA96),
                reelOuter: uiColor(0x292A22),
                meterFace: uiColor(0x999B68),
                cream: uiColor(0x25261F),
                amber: uiColor(0x963628),
                mintGlow: uiColor(0x6F724C),
                needle: uiColor(0x963628),
                pixelPaper: uiColor(0xD4CBB8),
                pixelPanel: uiColor(0xB9AF9B),
                pixelInk: uiColor(0x22231C),
                pixelRed: uiColor(0x9D382A),
                appBackgroundTop: uiColor(0xC8BFAC),
                appBackgroundMiddle: uiColor(0xBDB39F),
                appBackgroundBottom: uiColor(0xAAA18F)
            )
        case .lcdGray:
            return InterfaceThemePalette(
                deckPanel: UIColor(red: 0.72, green: 0.72, blue: 0.70, alpha: 1),
                reelOuter: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
                meterFace: UIColor(red: 0.78, green: 0.78, blue: 0.74, alpha: 1),
                cream: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1),
                amber: UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1),
                mintGlow: UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1),
                needle: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1),
                pixelPaper: UIColor(red: 0.82, green: 0.82, blue: 0.79, alpha: 1),
                pixelPanel: UIColor(red: 0.68, green: 0.68, blue: 0.66, alpha: 1),
                pixelInk: UIColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1),
                pixelRed: UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1),
                appBackgroundTop: UIColor(red: 0.62, green: 0.62, blue: 0.60, alpha: 1),
                appBackgroundMiddle: UIColor(red: 0.70, green: 0.70, blue: 0.68, alpha: 1),
                appBackgroundBottom: UIColor(red: 0.58, green: 0.58, blue: 0.56, alpha: 1)
            )
        case .amberCRT:
            return terminalPalette(background: 0xF4E6C9, panel: 0xDCC79D, paper: 0xEAD8B5, ink: 0x33240D, accent: 0xA96600, secondary: 0x7B5B1A, alert: 0xA43E23)
        case .phosphorGreen:
            return terminalPalette(background: 0xE3F1E5, panel: 0xBED8C2, paper: 0xD3E7D5, ink: 0x092516, accent: 0x167A42, secondary: 0x356D47, alert: 0xA43A32)
        case .cobaltTerminal:
            return terminalPalette(background: 0xE8EEF8, panel: 0xC5D2E8, paper: 0xDCE5F3, ink: 0x101A32, accent: 0x087CA5, secondary: 0x806A08, alert: 0xB13047)
        case .dracula:
            return terminalPalette(background: 0xF1EEF8, panel: 0xD8D2E8, paper: 0xE9E4F2, ink: 0x282A36, accent: 0x7B4CC2, secondary: 0x2F7D4E, alert: 0xA93535)
        case .solarized:
            return terminalPalette(background: 0xFDF6E3, panel: 0xEEE8D5, paper: 0xF5EED8, ink: 0x073642, accent: 0x2AA198, secondary: 0xB58900, alert: 0xCB4B16)
        case .nord:
            return terminalPalette(background: 0xECEFF4, panel: 0xD8DEE9, paper: 0xE5E9F0, ink: 0x2E3440, accent: 0x5E81AC, secondary: 0x4C7F5E, alert: 0xBF616A)
        case .gruvbox:
            return terminalPalette(background: 0xFBF1C7, panel: 0xEBDBB2, paper: 0xF2E5BC, ink: 0x3C3836, accent: 0xB57614, secondary: 0x79740E, alert: 0xAF3A03)
        case .catppuccin:
            return terminalPalette(background: 0xEFF1F5, panel: 0xDCE0E8, paper: 0xE6E9EF, ink: 0x4C4F69, accent: 0x1E66F5, secondary: 0x40A02B, alert: 0xD20F39)
        case .monokai:
            return terminalPalette(background: 0xF5F3EF, panel: 0xDDD8D0, paper: 0xEEEAE3, ink: 0x2D2A2E, accent: 0xA77A00, secondary: 0x5B7F15, alert: 0xA93457)
        }
    }

    private func terminalPalette(
        background: Int,
        panel: Int,
        paper: Int,
        ink: Int,
        accent: Int,
        secondary: Int,
        alert: Int
    ) -> InterfaceThemePalette {
        InterfaceThemePalette(
            deckPanel: uiColor(panel),
            reelOuter: uiColor(background),
            meterFace: uiColor(paper),
            cream: uiColor(ink),
            amber: uiColor(accent),
            mintGlow: uiColor(secondary),
            needle: uiColor(alert),
            pixelPaper: uiColor(paper),
            pixelPanel: uiColor(panel),
            pixelInk: uiColor(ink),
            pixelRed: uiColor(alert),
            appBackgroundTop: uiColor(background),
            appBackgroundMiddle: uiColor(background),
            appBackgroundBottom: uiColor(panel)
        )
    }

    private func uiColor(_ hex: Int) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    private static func themed(_ keyPath: KeyPath<InterfaceThemePalette, UIColor>) -> Color {
        Color(UIColor { traits in
            InterfaceColorTheme.current.palette(for: traits)[keyPath: keyPath]
        })
    }

    static var deckPanel: Color {
        themed(\.deckPanel)
    }
    static var reelOuter: Color { themed(\.reelOuter) }
    static var meterFace: Color { themed(\.meterFace) }
    static var cream: Color {
        themed(\.cream)
    }
    static var amber: Color {
        themed(\.amber)
    }
    static var mintGlow: Color {
        themed(\.mintGlow)
    }
    static var needle: Color { themed(\.needle) }
    static var pixelPaper: Color {
        themed(\.pixelPaper)
    }
    static var pixelPanel: Color {
        themed(\.pixelPanel)
    }
    static var pixelInk: Color {
        themed(\.pixelInk)
    }
    static var pixelRed: Color {
        themed(\.pixelRed)
    }
    static var appBackgroundTop: Color {
        themed(\.appBackgroundTop)
    }
    static var appBackgroundMiddle: Color {
        themed(\.appBackgroundMiddle)
    }
    static var appBackgroundBottom: Color {
        themed(\.appBackgroundBottom)
    }
}

extension ShapeStyle where Self == Color {
    static var deckPanel: Color { Color.deckPanel }
    static var reelOuter: Color { Color.reelOuter }
    static var meterFace: Color { Color.meterFace }
    static var cream: Color { Color.cream }
    static var amber: Color { Color.amber }
    static var mintGlow: Color { Color.mintGlow }
    static var needle: Color { Color.needle }
    static var pixelPaper: Color { Color.pixelPaper }
    static var pixelPanel: Color { Color.pixelPanel }
    static var pixelInk: Color { Color.pixelInk }
    static var pixelRed: Color { Color.pixelRed }
    static var appBackgroundTop: Color { Color.appBackgroundTop }
    static var appBackgroundMiddle: Color { Color.appBackgroundMiddle }
    static var appBackgroundBottom: Color { Color.appBackgroundBottom }
}
