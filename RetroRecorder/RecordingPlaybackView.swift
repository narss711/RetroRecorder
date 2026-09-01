import AVFoundation
import SwiftUI

struct RecordingPlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage
    @ObservedObject private var recorder: AudioRecorderViewModel
    @StateObject private var playback: RecordingPlaybackController

    private let recording: RecordingItem
    @State private var displayMode: PlaybackDisplayMode = .transcript
    @State private var titleText: String
    @State private var waveZoomScale = 1.0
    @State private var textScale = 1.0
    @State private var tagTimes: [TimeInterval]
    @State private var selectedTagSecond: Int?
    @State private var showingLanguagePicker = false
    @State private var isEditingTranscript = false
    @State private var transcriptDraftText: String
    @State private var pendingTranscriptReview: TranscriptDiffReview?
    @State private var pendingSilenceRemoval: SilenceRemovalResult?
    @State private var isRemovingSilence = false
    @State private var tagToast: RecordingTagToast?
    @State private var retranscriptionProgress = 0.0
    @State private var retranscriptionProgressTask: Task<Void, Never>?
    @State private var hasPlaybackSessionLease = false
    @FocusState private var isTitleFocused: Bool

    private let speedOptions = [0.25, 0.5, 1.0, 1.5, 2.0]

    init(recording: RecordingItem, recorder: AudioRecorderViewModel) {
        self.recording = recording
        _recorder = ObservedObject(wrappedValue: recorder)
        _playback = StateObject(wrappedValue: RecordingPlaybackController(recording: recording))
        _titleText = State(initialValue: recording.title)
        _tagTimes = State(initialValue: recording.tagTimes)
        _transcriptDraftText = State(initialValue: recording.transcript ?? "")
    }

    private var sortedTagSeconds: [Int] {
        Array(Set(tagTimes.map { Int(max(0, $0).rounded()) })).sorted()
    }

    private var currentSecond: Int {
        Int(playback.currentTime.rounded())
    }

    private var hasCurrentTag: Bool {
        sortedTagSeconds.contains(currentSecond)
    }

    private var currentRecording: RecordingItem {
        let recordingPath = recording.url.standardizedFileURL.path
        return recorder.recordings.first { item in
            item.url.standardizedFileURL.path == recordingPath
        } ?? recording
    }

    private var isRetranscribingCurrentRecording: Bool {
        recorder.transcribingRecordingID?.standardizedFileURL.path == currentRecording.url.standardizedFileURL.path
    }

    private var isPlaybackInteractionLocked: Bool {
        isRetranscribingCurrentRecording || isRemovingSilence
    }

    var body: some View {
        GeometryReader { proxy in
            let controlHeight = min(210, max(174, proxy.size.height * 0.25))

            ZStack {
                Color.appBackgroundMiddle
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    titleArea

                    playbackDisplay
                        .frame(maxHeight: .infinity)

                    PlaybackControlArea(
                        currentTime: playback.currentTime,
                        duration: playback.duration,
                        rate: playback.rate,
                        isPlaying: playback.isPlaying,
                        tagSeconds: sortedTagSeconds,
                        selectedTagSecond: selectedTagSecond,
                        hasCurrentTag: hasCurrentTag,
                        outputMode: playback.outputMode,
                        outputOptions: playback.outputOptions,
                        speedOptions: speedOptions,
                        onSeek: playback.seek,
                        onSelectRate: playback.setRate,
                        onSelectOutput: playback.setOutputMode,
                        onJumpBackward: { playback.jump(by: -15) },
                        onTogglePlay: playback.togglePlayback,
                        onJumpForward: { playback.jump(by: 15) },
                        onAddTag: addTagAtCurrentTime
                    )
                    .frame(height: controlHeight)
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
                .allowsHitTesting(!isPlaybackInteractionLocked)
                .opacity(isPlaybackInteractionLocked ? 0.54 : 1)

                if isPlaybackInteractionLocked {
                    PlaybackProcessingOverlay(
                        title: isRetranscribingCurrentRecording ? "正在重新识别文字" : "正在删除空白",
                        detail: isRetranscribingCurrentRecording ? "处理完成后会显示差异确认" : "正在分析并拼接有效音频",
                        progress: isRetranscribingCurrentRecording ? max(0.06, retranscriptionProgress) : nil
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            if !hasPlaybackSessionLease {
                hasPlaybackSessionLease = true
                recorder.beginPlaybackSession()
            }
            playback.prepare()
        }
        .onDisappear {
            commitTitle()
            persistTags()
            retranscriptionProgressTask?.cancel()
            playback.stop()
            if hasPlaybackSessionLease {
                hasPlaybackSessionLease = false
                recorder.endPlaybackSession()
            }
        }
        .alert(appLanguage.text(.alertTitle), isPresented: Binding(
            get: { playback.errorMessage != nil },
            set: { if !$0 { playback.errorMessage = nil } }
        )) {
            Button(appLanguage.text(.ok), role: .cancel) {
                playback.errorMessage = nil
            }
        } message: {
            Text(playback.errorMessage ?? "")
        }
        .onChange(of: currentRecording.transcript ?? "") { _, newValue in
            if !isEditingTranscript {
                transcriptDraftText = newValue
            }
        }
        .sheet(item: $pendingTranscriptReview) { review in
            TranscriptDiffReviewSheet(
                review: review,
                onConfirm: {
                    confirmTranscriptReview(review)
                },
                onDiscard: {
                    pendingTranscriptReview = nil
                }
            )
        }
        .sheet(item: $pendingSilenceRemoval) { result in
            SilenceRemovalReviewSheet(
                result: result,
                onSave: { title in
                    saveSilenceRemovedRecording(result, title: title)
                },
                onDiscard: {
                    discardSilenceRemoval(result)
                }
            )
        }
        .recordingTagToast($tagToast)
    }

    private var titleArea: some View {
        VStack(spacing: 7) {
            HStack {
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.pixelInk)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 8) {
                    modeButton(.waveform)
                    modeButton(.transcript)
                }
            }

            HStack(alignment: .center, spacing: 8) {
                TextField(recording.title, text: $titleText)
                    .retroFont(size: 15, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        commitTitle()
                    }

                Button {
                    isTitleFocused = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.pixelInk)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            Text("\(recording.subtitle) · \(recording.durationText)")
                .retroFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundStyle(.pixelInk.opacity(0.46))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(appLanguage.text(.done)) {
                    commitTitle()
                    isTitleFocused = false
                }
            }
        }
    }

    private var playbackDisplay: some View {
        VStack(spacing: 8) {
            displayToolbar

            Group {
                switch displayMode {
                case .waveform:
                    WaveformPlaybackDisplay(
                        samples: playback.waveformSamples,
                        currentTime: playback.currentTime,
                        duration: playback.duration,
                        zoomScale: waveZoomScale,
                        tagSeconds: sortedTagSeconds,
                        selectedTagSecond: selectedTagSecond,
                        onSeek: playback.seek,
                        onSelectTag: selectTag
                    )
                case .transcript:
                    TranscriptPlaybackDisplay(
                        transcript: currentRecording.transcript,
                        languageTitle: recorder.languageTitle(for: currentRecording),
                        isTranscribing: recorder.transcribingRecordingID == recording.id,
                        transcriptDraftText: $transcriptDraftText,
                        isEditingTranscript: $isEditingTranscript,
                        currentTime: playback.currentTime,
                        duration: playback.duration,
                        textScale: textScale,
                        tagSeconds: sortedTagSeconds,
                        selectedTagSecond: selectedTagSecond,
                        onSeek: playback.seek,
                        onSelectTag: selectTag,
                        onSelectLanguage: {
                            showingLanguagePicker = true
                        },
                        onSaveTranscript: saveTranscriptDraft,
                        onRetranscribe: retranscribeCurrentRecording
                    )
                    .equatable()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(8)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 3)
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(recorder: recorder, recording: currentRecording)
        }
    }

    private var displayToolbar: some View {
        HStack(spacing: 10) {
            Button {
                adjustZoom(by: 1)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Button {
                adjustZoom(by: -1)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                removeSilenceFromCurrentRecording()
            } label: {
                HStack(spacing: 6) {
                    if isRemovingSilence {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.pixelInk)
                    } else {
                        Image(systemName: "scissors")
                            .font(.system(size: 13, weight: .black))
                    }

                    Text("删除空白")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                }
                .frame(height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isRemovingSilence)

            if let selectedTagSecond {
                Button {
                    removeTag(second: selectedTagSecond)
                } label: {
                    Label(RecordingItem.format(TimeInterval(selectedTagSecond)), systemImage: "tag.slash.fill")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(Color.pixelInk.opacity(0.12), in: PixelCornerShape(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.pixelInk)
    }

    private func modeButton(_ mode: PlaybackDisplayMode) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.16)) {
                displayMode = mode
            }
        } label: {
            Image(systemName: mode.iconName)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(mode == displayMode ? .pixelPaper : .pixelInk)
                .frame(width: 36, height: 32)
                .background(mode == displayMode ? Color.pixelInk : Color.clear)
                .overlay {
                    Rectangle()
                        .stroke(.pixelInk.opacity(mode == displayMode ? 0 : 0.42), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func adjustZoom(by step: Int) {
        switch displayMode {
        case .waveform:
            waveZoomScale = min(6, max(1, waveZoomScale + Double(step) * 0.5))
        case .transcript:
            textScale = min(1.8, max(0.75, textScale + Double(step) * 0.12))
        }
    }

    private func addTagAtCurrentTime() {
        let second = min(Int(max(0, playback.duration).rounded()), max(0, currentSecond))
        guard !sortedTagSeconds.contains(second) else {
            selectedTagSecond = second
            showTagToast(.alreadyExists(second: second))
            return
        }

        tagTimes.append(TimeInterval(second))
        selectedTagSecond = second
        persistTags()
        showTagToast(.added(second: second))
    }

    private func showTagToast(_ result: RecordingTagAddResult) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            tagToast = RecordingTagToast(result: result)
        }
    }

    private func selectTag(_ second: Int) {
        selectedTagSecond = second
        playback.seek(to: TimeInterval(second))
    }

    private func removeTag(second: Int) {
        tagTimes.removeAll { Int($0.rounded()) == second }
        selectedTagSecond = nil
        persistTags()
    }

    private func persistTags() {
        recorder.saveTagTimes(tagTimes, for: recording)
    }

    private func retranscribeCurrentRecording() {
        guard !isPlaybackInteractionLocked else {
            return
        }

        isEditingTranscript = false
        isTitleFocused = false
        transcriptDraftText = currentRecording.transcript ?? ""
        playback.stop()
        startRetranscriptionProgress()

        Task {
            defer {
                finishRetranscriptionProgress()
            }

            guard let newTranscript = await recorder.recognizeTranscriptPreview(currentRecording) else {
                return
            }

            withAnimation(.easeOut(duration: 0.16)) {
                retranscriptionProgress = 1
            }

            pendingTranscriptReview = TranscriptDiffReview(
                oldText: currentRecording.transcript ?? "",
                newText: newTranscript
            )
        }
    }

    private func saveTranscriptDraft(_ text: String) {
        recorder.saveTranscript(text, for: currentRecording)
        transcriptDraftText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func confirmTranscriptReview(_ review: TranscriptDiffReview) {
        recorder.saveTranscript(review.newText, for: currentRecording)
        transcriptDraftText = review.newText.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingTranscriptReview = nil
    }

    private func startRetranscriptionProgress() {
        retranscriptionProgressTask?.cancel()
        retranscriptionProgress = 0.06

        retranscriptionProgressTask = Task {
            var progress = 0.06

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 320_000_000)
                progress = min(0.92, progress + max(0.018, (0.94 - progress) * 0.12))

                await MainActor.run {
                    withAnimation(.linear(duration: 0.26)) {
                        retranscriptionProgress = progress
                    }
                }
            }
        }
    }

    private func finishRetranscriptionProgress() {
        retranscriptionProgressTask?.cancel()
        retranscriptionProgressTask = nil

        withAnimation(.easeOut(duration: 0.14)) {
            retranscriptionProgress = 1
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)
            if !isRetranscribingCurrentRecording {
                retranscriptionProgress = 0
            }
        }
    }

    private func removeSilenceFromCurrentRecording() {
        guard !isRemovingSilence else {
            return
        }

        isRemovingSilence = true
        playback.stop()

        Task {
            do {
                let result = try await SilenceRemovalProcessor.process(recording: currentRecording)
                pendingSilenceRemoval = result
            } catch {
                playback.errorMessage = error.localizedDescription
            }

            isRemovingSilence = false
        }
    }

    private func saveSilenceRemovedRecording(_ result: SilenceRemovalResult, title: String) {
        recorder.saveProcessedRecording(from: result.tempURL, title: title, sourceRecording: currentRecording)
        pendingSilenceRemoval = nil
    }

    private func discardSilenceRemoval(_ result: SilenceRemovalResult) {
        try? FileManager.default.removeItem(at: result.tempURL)
        pendingSilenceRemoval = nil
    }

    private func commitTitle() {
        let cleanTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTitle = currentRecording.customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentRecording.title
        guard cleanTitle != currentTitle else {
            return
        }

        recorder.renameRecording(recording, to: cleanTitle)
    }

    private func close() {
        commitTitle()
        persistTags()
        recorder.reviewRecording = nil
        dismiss()
    }
}

private struct PlaybackProcessingOverlay: View {
    let title: String
    let detail: String
    let progress: Double?

    var body: some View {
        ZStack {
            Color.pixelPaper.opacity(0.76)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.pixelInk)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.pixelInk)

                    Text(detail)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.pixelInk.opacity(0.58))
                }

                if let progress {
                    ProgressView(value: min(1, max(0, progress)), total: 1)
                        .progressViewStyle(.linear)
                        .tint(.pixelInk)
                        .frame(width: 210)

                    Text("\(Int(min(1, max(0, progress)) * 100))%")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(.pixelInk.opacity(0.62))
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(Color.pixelPanel.opacity(0.96), in: PixelCornerShape(cornerRadius: 6))
            .overlay {
                PixelCornerShape(cornerRadius: 6)
                    .stroke(.pixelInk, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .transition(.opacity)
    }
}

private enum PlaybackDisplayMode {
    case waveform
    case transcript

    var iconName: String {
        switch self {
        case .waveform:
            return "waveform"
        case .transcript:
            return "captions.bubble.fill"
        }
    }
}

private struct TranscriptDiffReview: Identifiable {
    let id = UUID()
    let oldText: String
    let newText: String
    let oldAttributedText: AttributedString
    let newAttributedText: AttributedString

    init(oldText: String, newText: String) {
        self.oldText = oldText
        self.newText = newText

        let attributedText = TranscriptDiffBuilder.makeAttributedDiff(oldText: oldText, newText: newText)
        oldAttributedText = attributedText.old
        newAttributedText = attributedText.new
    }
}

private enum TranscriptDiffBuilder {
    static let removedColor = Color(red: 0.96, green: 0.08, blue: 0.08)
    static let insertedColor = Color(red: 0.0, green: 0.34, blue: 1.0)

    static func makeAttributedDiff(oldText: String, newText: String) -> (old: AttributedString, new: AttributedString) {
        let oldCharacters = Array(oldText)
        let newCharacters = Array(newText)
        let difference = newCharacters.difference(from: oldCharacters)

        var removedOffsets = Set<Int>()
        var insertedOffsets = Set<Int>()

        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                removedOffsets.insert(offset)
            case .insert(let offset, _, _):
                insertedOffsets.insert(offset)
            }
        }

        return (
            old: attributedText(for: oldCharacters, highlightedOffsets: removedOffsets, tint: removedColor, emptyText: "识别前为空"),
            new: attributedText(for: newCharacters, highlightedOffsets: insertedOffsets, tint: insertedColor, emptyText: "识别后为空")
        )
    }

    private static func attributedText(
        for characters: [Character],
        highlightedOffsets: Set<Int>,
        tint: Color,
        emptyText: String
    ) -> AttributedString {
        guard characters.isEmpty == false else {
            var empty = AttributedString(emptyText)
            empty.foregroundColor = .pixelInk.opacity(0.46)
            return empty
        }

        var output = AttributedString()

        for (offset, character) in characters.enumerated() {
            var segment = AttributedString(String(character))
            segment.foregroundColor = highlightedOffsets.contains(offset) ? tint : .pixelInk
            output += segment
        }

        return output
    }
}

private struct TranscriptDiffReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let review: TranscriptDiffReview
    let onConfirm: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        LegendItem(color: TranscriptDiffBuilder.removedColor, title: "旧文本差异")
                        LegendItem(color: TranscriptDiffBuilder.insertedColor, title: "新文本差异")
                    }

                    diffBlock(title: "识别前", text: review.oldAttributedText)
                    diffBlock(title: "识别后", text: review.newAttributedText)
                }
                .padding(18)
            }
            .background(Color.pixelPaper.ignoresSafeArea())
            .navigationTitle("确认覆盖文本")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        onDiscard()
                        dismiss()
                    } label: {
                        Text("放弃")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.pixelInk)
                    .background(Color.pixelPanel, in: PixelCornerShape(cornerRadius: 6))

                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("确认覆盖")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.pixelPaper)
                    .background(Color.pixelInk, in: PixelCornerShape(cornerRadius: 6))
                }
                .padding(16)
                .background(Color.pixelPaper.opacity(0.96))
            }
        }
    }

    private func diffBlock(title: String, text: AttributedString) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.pixelInk.opacity(0.62))

            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .lineSpacing(5)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.pixelPanel.opacity(0.34), in: PixelCornerShape(cornerRadius: 6))
                .overlay {
                    PixelCornerShape(cornerRadius: 6)
                        .stroke(.pixelInk.opacity(0.12), lineWidth: 1)
                }
        }
    }
}

private struct SilenceRemovalReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var titleText: String
    @State private var didFinish = false

    let result: SilenceRemovalResult
    let onSave: (String) -> Void
    let onDiscard: () -> Void

    init(result: SilenceRemovalResult, onSave: @escaping (String) -> Void, onDiscard: @escaping () -> Void) {
        self.result = result
        self.onSave = onSave
        self.onDiscard = onDiscard
        _titleText = State(initialValue: result.suggestedTitle)
    }

    private var cleanTitle: String {
        titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    statisticRow(title: "缩减空白时长", value: RecordingItem.format(result.removedDuration))
                    statisticRow(title: "检测到空白段", value: "\(result.removedSegmentCount) 个")
                    statisticRow(title: "处理后时长", value: RecordingItem.format(result.outputDuration))
                }
                .padding(16)
                .background(Color.pixelPanel.opacity(0.62), in: PixelCornerShape(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 8) {
                    Text("另存为文件名")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.pixelInk.opacity(0.62))

                    TextField(result.suggestedTitle, text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.pixelInk)
                        .padding(12)
                        .background(Color.pixelPanel.opacity(0.34), in: PixelCornerShape(cornerRadius: 6))
                        .overlay {
                            PixelCornerShape(cornerRadius: 6)
                                .stroke(.pixelInk.opacity(0.14), lineWidth: 1)
                        }
                }

                Spacer()
            }
            .padding(18)
            .background(Color.pixelPaper.ignoresSafeArea())
            .navigationTitle("删除空白")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        didFinish = true
                        onDiscard()
                        dismiss()
                    } label: {
                        Text("放弃")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.pixelInk)
                    .background(Color.pixelPanel, in: PixelCornerShape(cornerRadius: 6))

                    Button {
                        didFinish = true
                        onSave(cleanTitle)
                        dismiss()
                    } label: {
                        Text("确认另存")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.pixelPaper)
                    .background(Color.pixelInk, in: PixelCornerShape(cornerRadius: 6))
                    .disabled(cleanTitle.isEmpty)
                    .opacity(cleanTitle.isEmpty ? 0.42 : 1)
                }
                .padding(16)
                .background(Color.pixelPaper.opacity(0.96))
            }
            .onDisappear {
                if !didFinish {
                    onDiscard()
                }
            }
        }
    }

    private func statisticRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.pixelInk.opacity(0.64))

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(.pixelInk)
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.pixelInk.opacity(0.62))
        }
    }
}

@MainActor
private final class RecordingPlaybackController: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval
    @Published var rate = 1.0
    @Published var outputMode: PlaybackOutputMode = .speaker
    @Published var outputOptions: [PlaybackOutputMode] = [.speaker, .receiver]
    @Published var waveformSamples: [Double] = Array(repeating: 0, count: 720)
    @Published var errorMessage: String?

    private let recording: RecordingItem
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var timer: Timer?
    private var didLoadWaveform = false
    private var hasBluetoothOutput = false

    init(recording: RecordingItem) {
        self.recording = recording
        self.duration = recording.duration
        super.init()
    }

    deinit {
        timer?.invalidate()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
        player?.pause()
    }

    func prepare() {
        guard player == nil else {
            return
        }

        let session = AVAudioSession.sharedInstance()

        // Let iOS resolve a connected Bluetooth output first. Routing is a
        // best-effort concern and must not prevent the AVPlayer from loading.
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
            try session.setActive(true)
            hasBluetoothOutput = containsBluetoothOutput(session.currentRoute.outputs)
            outputOptions = hasBluetoothOutput
                ? [.speaker, .receiver, .bluetooth]
                : [.speaker, .receiver]
            outputMode = hasBluetoothOutput ? .bluetooth : .speaker
            if hasBluetoothOutput == false {
                try configureAudioSession(for: .speaker)
            }
        } catch {
            // Some active audio routes reject a category change temporarily.
            // Keep playback usable and let the user change output afterwards.
            outputMode = .speaker
            outputOptions = [.speaker, .receiver]
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
        }

        installRouteObserver()

        let playerItem = AVPlayerItem(url: recording.url)
        playerItem.audioTimePitchAlgorithm = .timeDomain

        let nextPlayer = AVPlayer(playerItem: playerItem)
        nextPlayer.automaticallyWaitsToMinimizeStalling = false
        player = nextPlayer
        duration = recording.duration
        installEndObserver(for: playerItem)
        loadWaveformIfNeeded()
    }

    func setOutputMode(_ mode: PlaybackOutputMode) {
        guard outputOptions.contains(mode) else {
            return
        }

        do {
            try configureAudioSession(for: mode)
            outputMode = mode
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePlayback() {
        prepare()

        guard let player else {
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            if currentTime >= duration {
                seek(to: 0, resumeIfPlaying: false)
            }

            player.playImmediately(atRate: Float(rate))
            isPlaying = true
            startTimer()
        }
    }

    func jump(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func seek(to time: TimeInterval) {
        seek(to: time, resumeIfPlaying: isPlaying)
    }

    private func seek(to time: TimeInterval, resumeIfPlaying: Bool) {
        prepare()

        let nextTime = min(max(0, time), max(0, duration))
        currentTime = nextTime
        let cmTime = CMTime(seconds: nextTime, preferredTimescale: 600)

        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                guard let self, resumeIfPlaying, self.isPlaying else {
                    return
                }

                self.player?.playImmediately(atRate: Float(self.rate))
            }
        }
    }

    func setRate(_ rate: Double) {
        self.rate = rate

        guard let player, isPlaying else {
            return
        }

        player.playImmediately(atRate: Float(rate))
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isPlaying = false
        stopTimer()

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
            self.routeObserver = nil
        }
    }

    private func configureAudioSession(for mode: PlaybackOutputMode) throws {
        let session = AVAudioSession.sharedInstance()

        switch mode {
        case .bluetooth:
            try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
            try session.setActive(true)
        case .speaker, .receiver:
            let options: AVAudioSession.CategoryOptions = mode == .speaker
                ? [.defaultToSpeaker]
                : []
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: options
            )
            try session.setActive(true)
            try session.overrideOutputAudioPort(mode == .speaker ? .speaker : .none)
        }
    }

    private func installRouteObserver() {
        guard routeObserver == nil else {
            return
        }

        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleRouteChange(notification)
            }
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        let session = AVAudioSession.sharedInstance()
        let isBluetoothRoute = containsBluetoothOutput(session.currentRoute.outputs)

        if isBluetoothRoute {
            hasBluetoothOutput = true
            outputOptions = [.speaker, .receiver, .bluetooth]
            if outputMode == .speaker || outputMode == .receiver {
                return
            }
        } else if outputMode == .bluetooth {
            hasBluetoothOutput = false
            outputOptions = [.speaker, .receiver]
            outputMode = .speaker
            try? configureAudioSession(for: .speaker)
        }
    }

    private func containsBluetoothOutput(_ outputs: [AVAudioSessionPortDescription]) -> Bool {
        outputs.contains { output in
            output.portType == .bluetoothA2DP
                || output.portType == .bluetoothHFP
                || output.portType == .bluetoothLE
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let player else {
            return
        }

        let seconds = player.currentTime().seconds
        guard seconds.isFinite else {
            return
        }

        currentTime = min(max(0, seconds), max(0, duration))

        if currentTime >= max(0, duration - 0.05) {
            currentTime = duration
            isPlaying = false
            player.pause()
            stopTimer()
        }
    }

    private func installEndObserver(for playerItem: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = self?.duration ?? 0
                self?.isPlaying = false
                self?.stopTimer()
            }
        }
    }

    private func loadWaveformIfNeeded() {
        guard !didLoadWaveform else {
            return
        }

        didLoadWaveform = true
        let url = recording.url

        Task.detached(priority: .userInitiated) {
            let samples = Self.renderWaveformSamples(from: url, targetCount: 720)
            await MainActor.run { [weak self] in
                self?.waveformSamples = samples
            }
        }
    }

    private nonisolated static func renderWaveformSamples(from url: URL, targetCount: Int) -> [Double] {
        let emptySamples = Array(repeating: 0.0, count: targetCount)

        do {
            let file = try AVAudioFile(forReading: url)
            let frameCount = Int(file.length)
            let format = file.processingFormat
            let channelCount = max(1, Int(format.channelCount))

            guard frameCount > 0 else {
                return emptySamples
            }

            var bucketSquares = Array(repeating: 0.0, count: targetCount)
            var bucketCounts = Array(repeating: 0, count: targetCount)
            let chunkSize = 4_096
            var globalFrameOffset = 0

            while globalFrameOffset < frameCount {
                let framesToRead = min(chunkSize, frameCount - globalFrameOffset)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: AVAudioFrameCount(framesToRead)
                ) else {
                    break
                }

                try file.read(into: buffer, frameCount: AVAudioFrameCount(framesToRead))
                let frameLength = Int(buffer.frameLength)

                guard frameLength > 0,
                      let channelData = buffer.floatChannelData else {
                    break
                }

                for frame in 0..<frameLength {
                    var mixedSample: Float = 0

                    for channelIndex in 0..<channelCount {
                        mixedSample += channelData[channelIndex][frame]
                    }

                    let normalizedSample = Double(mixedSample / Float(channelCount))
                    let bucketIndex = min(targetCount - 1, (globalFrameOffset + frame) * targetCount / frameCount)
                    bucketSquares[bucketIndex] += normalizedSample * normalizedSample
                    bucketCounts[bucketIndex] += 1
                }

                globalFrameOffset += frameLength
            }

            var samples = bucketSquares.enumerated().map { index, sumSquares in
                guard bucketCounts[index] > 0 else {
                    return 0.0
                }

                return sqrt(sumSquares / Double(bucketCounts[index]))
            }

            let peak = samples.max() ?? 0
            guard peak > 0 else {
                return emptySamples
            }

            samples = samples.map { min(1, max(0.015, sqrt($0 / peak))) }
            return samples
        } catch {
            return emptySamples
        }
    }
}

private struct WaveformPlaybackDisplay: View {
    let samples: [Double]
    let currentTime: TimeInterval
    let duration: TimeInterval
    let zoomScale: Double
    let tagSeconds: [Int]
    let selectedTagSecond: Int?
    let onSeek: (TimeInterval) -> Void
    let onSelectTag: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width, proxy.size.width * CGFloat(zoomScale))

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    PlaybackWaveformCanvas(samples: samples)
                        .frame(width: contentWidth, height: proxy.size.height)
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    seek(at: value.location.x, width: contentWidth)
                                }
                        )

                    playbackHead(width: contentWidth, height: proxy.size.height)

                    ForEach(tagSeconds, id: \.self) { second in
                        tagMarker(second: second, width: contentWidth)
                    }
                }
                .frame(width: contentWidth, height: proxy.size.height)
            }
        }
        .background(Color.pixelPanel.opacity(0.32))
        .clipped()
    }

    private func playbackHead(width: CGFloat, height: CGFloat) -> some View {
        let progress = duration > 0 ? currentTime / duration : 0
        let x = min(max(0, progress), 1) * width

        return Rectangle()
            .fill(Color.pixelInk.opacity(0.88))
            .frame(width: 2, height: height)
            .overlay(alignment: .top) {
                Circle()
                    .fill(Color.pixelInk)
                    .frame(width: 7, height: 7)
                    .offset(y: -2)
            }
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color.pixelInk)
                    .frame(width: 7, height: 7)
                    .offset(y: 2)
            }
            .offset(x: x)
    }

    private func tagMarker(second: Int, width: CGFloat) -> some View {
        let progress = duration > 0 ? Double(second) / duration : 0
        let x = min(max(0, progress), 1) * width
        let isSelected = second == selectedTagSecond

        return Button {
            onSelectTag(second)
        } label: {
            Image(systemName: isSelected ? "tag.fill" : "tag")
                .font(.system(size: isSelected ? 18 : 16, weight: .black))
                .foregroundStyle(isSelected ? .pixelInk : .pixelInk.opacity(0.62))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .offset(x: x - 17, y: 22)
    }

    private func seek(at x: CGFloat, width: CGFloat) {
        guard duration > 0, width > 0 else {
            return
        }

        let progress = min(1, max(0, Double(x / width)))
        onSeek(duration * progress)
    }
}

private struct PlaybackWaveformCanvas: View {
    let samples: [Double]

    var body: some View {
        Canvas { context, size in
            drawTimeGrid(context: context, size: size)
            drawWaveform(context: context, size: size)
        }
    }

    private func drawTimeGrid(context: GraphicsContext, size: CGSize) {
        let midY = size.height * 0.5
        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: midY))
        axis.addLine(to: CGPoint(x: size.width, y: midY))
        context.stroke(axis, with: .color(.pixelInk.opacity(0.18)), lineWidth: 1)

        let tickCount = max(6, Int(size.width / 72))
        for index in 0...tickCount {
            let x = CGFloat(index) * size.width / CGFloat(tickCount)
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: size.height - 28))
            tick.addLine(to: CGPoint(x: x, y: size.height - (index % 2 == 0 ? 12 : 20)))
            context.stroke(tick, with: .color(.pixelInk.opacity(0.12)), lineWidth: 1)
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        guard samples.count > 1 else {
            return
        }

        let midY = size.height * 0.5
        let cell: CGFloat = 3
        let gap: CGFloat = 3
        let step = cell + gap
        let columns = max(1, Int(size.width / step))
        let maxRows = max(2, Int((size.height * 0.42) / step))

        for column in 0..<columns {
            let sampleIndex = min(samples.count - 1, column * samples.count / columns)
            let level = min(1, max(0, samples[sampleIndex]))
            let rows = max(1, Int((level * Double(maxRows)).rounded(.up)))
            let x = CGFloat(column) * step

            for row in -rows...rows {
                let distance = abs(row)
                let opacity = max(0.28, 0.92 - Double(distance) * 0.07)
                let y = midY + CGFloat(row) * step
                let rect = CGRect(x: x, y: y, width: cell, height: cell)
                context.fill(Path(rect), with: .color(.pixelInk.opacity(opacity)))
            }
        }
    }
}

private struct TranscriptPlaybackDisplay: View, Equatable {
    @Environment(\.appLanguage) private var appLanguage

    let transcript: String?
    let languageTitle: String
    let isTranscribing: Bool
    @Binding var transcriptDraftText: String
    @Binding var isEditingTranscript: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let textScale: Double
    let tagSeconds: [Int]
    let selectedTagSecond: Int?
    let onSeek: (TimeInterval) -> Void
    let onSelectTag: (Int) -> Void
    let onSelectLanguage: () -> Void
    let onSaveTranscript: (String) -> Void
    let onRetranscribe: () -> Void
    @FocusState private var isTranscriptFocused: Bool

    static func == (lhs: TranscriptPlaybackDisplay, rhs: TranscriptPlaybackDisplay) -> Bool {
        lhs.transcript == rhs.transcript
            && lhs.languageTitle == rhs.languageTitle
            && lhs.isTranscribing == rhs.isTranscribing
            && lhs.transcriptDraftText == rhs.transcriptDraftText
            && lhs.isEditingTranscript == rhs.isEditingTranscript
            && Int(lhs.currentTime) == Int(rhs.currentTime)
            && lhs.duration == rhs.duration
            && lhs.textScale == rhs.textScale
            && lhs.tagSeconds == rhs.tagSeconds
            && lhs.selectedTagSecond == rhs.selectedTagSecond
    }

    private var displayText: String {
        transcript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? transcript ?? ""
            : "暂无转写文本"
    }

    private var visibleCharacterCount: Int {
        let source = isEditingTranscript ? transcriptDraftText : (transcript ?? "")
        return source.filter { !$0.isWhitespace && !$0.isNewline }.count
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Label(appLanguage.format(.characterCountFormat, visibleCharacterCount), systemImage: "textformat.size")
                            .retroFont(size: 10, weight: .black, design: .monospaced)
                            .foregroundStyle(.pixelInk.opacity(0.66))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        transcriptEditControls

                        if let transcript, !transcript.isEmpty {
                            Button {
                                UIPasteboard.general.string = transcript
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13, weight: .black))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(appLanguage.text(.copyText))
                        }

                        Button(action: onSelectLanguage) {
                            HStack(spacing: 5) {
                                Image(systemName: "globe")
                                    .font(.system(size: 13, weight: .black))

                                Text(languageTitle)
                                    .retroFont(size: 10, weight: .black, design: .monospaced)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.55)
                            }
                            .foregroundStyle(.pixelInk)
                            .frame(maxWidth: 132, alignment: .trailing)
                        }
                        .buttonStyle(.plain)

                        Button(action: onRetranscribe) {
                            Group {
                                if isTranscribing {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(.pixelInk)
                                } else {
                                    Image(systemName: "text.viewfinder")
                                        .font(.system(size: 13, weight: .black))
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .foregroundStyle(.pixelInk)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTranscribing || isEditingTranscript)
                        .accessibilityLabel("重新识别")
                    }

                    if !tagSeconds.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tagSeconds, id: \.self) { second in
                                    transcriptTag(second)
                                }
                            }
                        }
                    }

                    if isEditingTranscript {
                        TextEditor(text: $transcriptDraftText)
                            .font(.system(size: CGFloat(17 * textScale), weight: .regular, design: .monospaced))
                            .foregroundStyle(.pixelInk)
                            .lineSpacing(CGFloat(5 * textScale))
                            .scrollContentBackground(.hidden)
                            .background(Color.pixelPaper.opacity(0.56))
                            .focused($isTranscriptFocused)
                            .frame(minHeight: max(220, proxy.size.height - 96))
                            .overlay {
                                Rectangle()
                                    .stroke(.pixelInk.opacity(0.14), lineWidth: 1)
                            }
                    } else {
                        Text(displayText)
                            .font(.system(size: CGFloat(17 * textScale), weight: .regular, design: .monospaced))
                            .foregroundStyle(.pixelInk)
                            .lineSpacing(CGFloat(5 * textScale))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(18)
                .frame(minHeight: proxy.size.height, alignment: .topLeading)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard !isEditingTranscript, duration > 0 else {
                            return
                        }

                        let delta = -Double(value.translation.height / max(1, proxy.size.height)) * duration * 0.35
                        onSeek(min(max(0, currentTime + delta), duration))
                    }
            )
        }
        .background(Color.pixelPaper.opacity(0.64))
        .overlay {
            Rectangle()
                .stroke(.pixelInk.opacity(0.18), lineWidth: 1)
        }
    }

    private var transcriptEditControls: some View {
        HStack(spacing: 8) {
            if isEditingTranscript {
                Button {
                    cancelTranscriptEdit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button {
                    commitTranscriptEdit()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    beginTranscriptEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(isTranscribing)
            }
        }
        .foregroundStyle(.pixelInk)
    }

    private func beginTranscriptEdit() {
        transcriptDraftText = transcript ?? ""
        isEditingTranscript = true

        DispatchQueue.main.async {
            isTranscriptFocused = true
        }
    }

    private func cancelTranscriptEdit() {
        transcriptDraftText = transcript ?? ""
        isEditingTranscript = false
        isTranscriptFocused = false
    }

    private func commitTranscriptEdit() {
        onSaveTranscript(transcriptDraftText)
        isEditingTranscript = false
        isTranscriptFocused = false
    }

    private func transcriptTag(_ second: Int) -> some View {
        let isSelected = second == selectedTagSecond

        return Button {
            onSelectTag(second)
        } label: {
            Label(RecordingItem.format(TimeInterval(second)), systemImage: isSelected ? "tag.fill" : "tag")
                .retroFont(size: 10, weight: .black, design: .monospaced)
                .foregroundStyle(isSelected ? .pixelInk : .pixelInk.opacity(0.62))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.pixelPaper.opacity(0.78), in: PixelCornerShape(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

private struct PlaybackControlArea: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let rate: Double
    let isPlaying: Bool
    let tagSeconds: [Int]
    let selectedTagSecond: Int?
    let hasCurrentTag: Bool
    let outputMode: PlaybackOutputMode
    let outputOptions: [PlaybackOutputMode]
    let speedOptions: [Double]
    let onSeek: (TimeInterval) -> Void
    let onSelectRate: (Double) -> Void
    let onSelectOutput: (PlaybackOutputMode) -> Void
    let onJumpBackward: () -> Void
    let onTogglePlay: () -> Void
    let onJumpForward: () -> Void
    let onAddTag: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            PlaybackTimelineView(
                currentTime: currentTime,
                duration: duration,
                tagSeconds: tagSeconds,
                selectedTagSecond: selectedTagSecond,
                onSeek: onSeek
            )
            .frame(height: 24)

            ZStack {
                HStack(alignment: .center) {
                    outputButton

                    Spacer()

                    Text("- \(RecordingItem.format(max(0, duration - currentTime)))")
                        .retroFont(size: 15, weight: .bold, design: .monospaced)
                        .foregroundStyle(.pixelInk.opacity(0.88))
                        .lineLimit(1)
                }

                Text(RecordingItem.format(currentTime))
                    .retroFont(size: 27, weight: .black, design: .monospaced)
                    .foregroundStyle(.pixelInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 18) {
                speedButton

                playbackButton(systemName: "gobackward.15", size: 40, action: onJumpBackward)
                playbackButton(systemName: isPlaying ? "pause.fill" : "play.fill", size: 52, action: onTogglePlay)
                playbackButton(systemName: "goforward.15", size: 40, action: onJumpForward)

                Button(action: onAddTag) {
                    Image(systemName: hasCurrentTag ? "tag.fill" : "tag")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(hasCurrentTag ? .pixelInk : .pixelInk.opacity(0.72))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 11)
        .background(Color.pixelPaper)
        .overlay {
            Rectangle()
                .stroke(.pixelInk, lineWidth: 2)
        }
    }

    private var speedButton: some View {
        Menu {
            ForEach(speedOptions, id: \.self) { option in
                Button("\(speedTitle(option))x") {
                    onSelectRate(option)
                }
            }
        } label: {
            Text(speedTitle(rate))
                .retroFont(size: 11, weight: .black, design: .monospaced)
                .foregroundStyle(.pixelInk)
                .frame(width: 38, height: 38)
                .overlay {
                    Rectangle()
                        .stroke(.pixelInk, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
    }

    private var outputButton: some View {
        Menu {
            ForEach(outputOptions) { option in
                Button {
                    onSelectOutput(option)
                } label: {
                    Label {
                        Text(option.title)
                    } icon: {
                        Image(systemName: option.iconName)
                    }
                }
            }
        } label: {
            Image(systemName: outputMode.iconName)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.pixelInk)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("回放声音输出")
        .accessibilityValue(outputMode.title)
    }

    private func playbackButton(systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.58, weight: .black))
                .foregroundStyle(.pixelInk)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    private func speedTitle(_ value: Double) -> String {
        value == 1 ? "1.0" : String(format: "%g", value)
    }
}

private enum PlaybackOutputMode: String, CaseIterable, Identifiable {
    case speaker
    case receiver
    case bluetooth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .speaker:
            return "手机外放"
        case .receiver:
            return "手机听筒"
        case .bluetooth:
            return "蓝牙耳机"
        }
    }

    var iconName: String {
        switch self {
        case .speaker:
            return "speaker.wave.2.fill"
        case .receiver:
            return "phone.fill"
        case .bluetooth:
            return "airpodspro"
        }
    }
}

private struct PlaybackTimelineView: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let tagSeconds: [Int]
    let selectedTagSecond: Int?
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.pixelInk.opacity(0.36))
                    .frame(height: 6)

                Rectangle()
                    .fill(Color.pixelInk)
                    .frame(width: progressWidth(proxy.size.width), height: 6)

                ForEach(tagSeconds, id: \.self) { second in
                    Rectangle()
                        .fill(second == selectedTagSecond ? Color.pixelInk : Color.pixelInk.opacity(0.52))
                        .frame(width: 2, height: 18)
                        .offset(x: tagOffset(second, width: proxy.size.width))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard duration > 0, proxy.size.width > 0 else {
                            return
                        }

                        let progress = min(1, max(0, Double(value.location.x / proxy.size.width)))
                        onSeek(duration * progress)
                    }
            )
        }
    }

    private func progressWidth(_ width: CGFloat) -> CGFloat {
        guard duration > 0 else {
            return 0
        }

        return width * CGFloat(min(1, max(0, currentTime / duration)))
    }

    private func tagOffset(_ second: Int, width: CGFloat) -> CGFloat {
        guard duration > 0 else {
            return 0
        }

        return width * CGFloat(min(1, max(0, Double(second) / duration)))
    }
}
