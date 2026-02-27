# MacSquak

Local-first macOS speech-to-text menu bar app using Parakeet (MLX) on Apple Silicon.

## Features
- Global hotkey recording with selectable mode: toggle or hold-to-record (default Cmd+Shift+R)
- Records microphone audio to local WAV files
- Transcribes locally with `parakeet-mlx` via a JSON-contract worker with retry support
- Copies transcript to clipboard automatically
- Keeps audio if transcription fails
- Optional LLM post-processing with user prompt template + Keychain API key

## Setup
1. Install dependencies:
   - Xcode 15+
   - Python 3.10+
   - `pip install -U parakeet-mlx`
2. Build app:
   - `swift build`
3. Run:
   - `swift run`

## Permissions
On first run, grant Microphone access in macOS privacy settings.

## Storage
- `~/Library/Application Support/MacSquak/recordings/*.wav`
- `~/Library/Application Support/MacSquak/settings.json`

## Notes
- In hold mode, press and hold the hotkey to record; release to auto-transcribe.
- Worker contract fields: `ok`, `text`, `model`, `elapsed_seconds`, `error`.

- This project is local-first by default.
- If post-processing is enabled, transcript text is sent to your configured endpoint.
