# RetroRecorder

RetroRecorder is a SwiftUI iOS recording app with a retro tape-recorder interface, selectable audio inputs, local recording playback, sharing, and optional speech-to-text transcription.

## Features

- Selects the currently available iOS input route, including built-in microphone, headset microphone, USB audio input, Bluetooth HFP, and other system-reported input ports.
- Records AAC `.m4a` files into the app's Documents/Recordings directory.
- Shows a retro deck interface with animated reels, a VU meter, transport controls, and elapsed time.
- Plays recordings back in-app and shares the audio file through the iOS share sheet.
- Converts completed recordings to text with Apple's Speech framework and saves the transcript beside the recording.
- Adds a Home Screen Widget that shows a GIF, still image, or short video selected manually from Photos.

## 录音
- 录制、暂停、继续、停止；支持后台和锁屏持续录音。
- 自动检测并切换可用输入设备：手机麦克风、耳机麦克风、USB/外接麦克风等。
- 可选录音格式：CAF、WAV、M4A（ALAC）、AIFF。
- 可选采样率：16 / 22.05 / 32 / 44.1 / 48 / 96 kHz；位深：16-bit、24-bit、32-bit Float。
- 降噪模式：关闭、RNNoise、DeepFilterNet V3、DTLN。
- 回声消除：关闭或系统 Voice Processing。
- 实时音频可视化，多种波形/频谱/Metal 效果可切换，记忆上次选择。
- 录制时可添加时间标签 Tag，并显示操作提示。
- 录音文件默认按“地点 + 日期时间”命名；未获取定位时仅使用日期时间。
  
## 实时文字与转写
- Live Text 实时语音识别，内容可滚动、展开查看、复制及编辑。
- 识别语言可手动选择，并记住上次选择；默认跟随系统语言。
- 支持简中、繁中、英语、西语、阿语、葡语、俄语、日语、德语、法语等识别语言。
- 支持对已有录音重新识别；会显示新旧文本差异，用户确认后才覆盖。
- 转写模型菜单包含 Apple Speech、OpenAI Whisper、Mozilla DeepSpeech；当前实际可用的是 Apple Speech，本地 Whisper / DeepSpeech 仍为预留选项。

## 历史与文件管理
- 历史录音默认折叠，展示名称、时长、录制日期时间。
- 展开后可播放、查看文字、语言、字数、Tag、录音参数、定位与设备信息。
- 支持单个删除、批量多选删除、单个分享及多文件分享。
- 支持重命名、编辑文字、复制文本。
- 支持“删除空白”处理：生成另存文件，并提示缩短时长与空白段数量。
- 录音详情保存精确坐标、地址、时间、输入设备、格式、采样率、位深、编码、降噪与回声消除参数。

## 回放
- 录音结束自动进入全屏回放。
- 波形与文字两种回放视图；波形横向拖动、文字纵向阅读。
- 播放进度、剩余时间、Tag 时间点标记。
- 0.25 / 0.5 / 1 / 1.5 / 2 倍速，前后跳转 15 秒。
- 可在回放中新增或删除 Tag。
- 输出设备可切换手机外放、听筒、蓝牙耳机；连接蓝牙时优先蓝牙。
- 锁屏与系统媒体控制支持播放/暂停与进度同步。

## 系统与个性化
- 首次启动的权限向导：麦克风、语音识别、定位，按用户点击再请求系统授权。
- 支持 App Shortcuts / Action Button 触发快速开始录音。
- 录音中的 Live Activities 显示时长与录音参数。
- 界面支持深色/浅色适配、多套终端风格主题色。
- 支持多语言界面：简中、繁中、英文、西语、阿语、葡语、俄语、日语、德语、法语。
- 每种界面语言提供匹配字形的开源复古字体选择，避免缺字。
- 支持 CloudKit Private Database 同步录音记录与关联信息；个人签名安装版本会关闭 CloudKit 能力，正式签名版本可启用同步。


## Running

Open `RetroRecorder.xcodeproj` in Xcode, select the `RetroRecorder` scheme, choose an iPhone device, and run.

For real microphone routing tests, use a physical iPhone. iOS only exposes headset and USB microphones after they are connected and accepted by the system audio route.

The app includes `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` in `Info.plist`; iOS will ask for both permissions when needed.
