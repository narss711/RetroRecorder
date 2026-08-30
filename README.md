# RetroRecorder

RetroRecorder is a SwiftUI iOS recording app with a retro tape-recorder interface, selectable audio inputs, local recording playback, sharing, and optional speech-to-text transcription.

## Features

- Selects the currently available iOS input route, including built-in microphone, headset microphone, USB audio input, Bluetooth HFP, and other system-reported input ports.
- Records AAC `.m4a` files into the app's Documents/Recordings directory.
- Shows a retro deck interface with animated reels, a VU meter, transport controls, and elapsed time.
- Plays recordings back in-app and shares the audio file through the iOS share sheet.
- Converts completed recordings to text with Apple's Speech framework and saves the transcript beside the recording.
- Adds a Home Screen Widget that shows a GIF, still image, or short video selected manually from Photos.

## Media Widget

Open the app once, use the "桌面 Widget" panel to choose a GIF or short video from Photos, then add the "动态媒体" widget from the iOS Home Screen widget gallery.

The app converts the selected media into up to 24 JPEG frames and saves them in the shared App Group container. The widget reads those frames and renders them with rotating sector masks driven by `ClockHandRotationKit`, while still keeping a manual next-frame button for true frame advancement. This follows the common `clockHandRotationEffect` widget-animation trick: each frame has a large rotating mask, so fixed pixels cycle through the imported frames without relying on WidgetKit timeline refreshes. This depends on undocumented clock-hand rotation behavior, so treat it as a device-side experiment rather than App Store-safe WidgetKit animation.

Before running on a physical device, enable this App Group for both the app target and widget extension in your Apple Developer account:

`group.com.lutan.RetroRecorder.mediawidget`

## Running

Open `RetroRecorder.xcodeproj` in Xcode, select the `RetroRecorder` scheme, choose an iPhone device, and run.

For real microphone routing tests, use a physical iPhone. iOS only exposes headset and USB microphones after they are connected and accepted by the system audio route.

The app includes `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` in `Info.plist`; iOS will ask for both permissions when needed.
