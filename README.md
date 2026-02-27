# MacSquak

Local-first macOS speech-to-text menu bar app using Parakeet (MLX) on Apple Silicon.

## Features
- Global hotkey toggle recording (default Cmd+Shift+R)
- Records microphone audio to local WAV files
- Transcribes locally with `parakeet-mlx`
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
- This project is local-first by default.
- If post-processing is enabled, transcript text is sent to your configured endpoint.
