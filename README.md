# MacSquak

Local-first macOS speech-to-text menu bar app using Parakeet (MLX) on Apple Silicon.

## Features
- Global hotkey recording with selectable mode: toggle or hold-to-record (default Cmd+Shift+R)
- Records microphone audio to local WAV files
- Self-contained local runtime bootstrapped with **uv** (venv + `parakeet-mlx`)
- Transcribes locally via a JSON-contract worker with retry support
- Copies transcript to clipboard automatically
- Keeps audio if transcription fails
- Optional LLM post-processing with user prompt template + Keychain API key

## Setup
1. Install dependencies:
   - Xcode 15+
   - Python 3.10+
   - `uv` installed and available on PATH
2. Build app:
   - `swift build`
3. Run:
   - `swift run`

On first transcription, MacSquak will automatically:
- create a local venv under Application Support
- install `parakeet-mlx` using uv
- copy bundled worker script into runtime/bin

## Permissions
On first run, grant Microphone access in macOS privacy settings.

## Storage
- `~/Library/Application Support/MacSquak/recordings/*.wav`
- `~/Library/Application Support/MacSquak/settings.json`
- `~/Library/Application Support/MacSquak/runtime/` (uv venv + worker)
- `~/Library/Application Support/MacSquak/macsquak.log`

## Notes
- In hold mode, press and hold the hotkey to record; release to auto-transcribe.
- Worker contract fields: `ok`, `text`, `model`, `elapsed_seconds`, `error`.
- If post-processing is enabled, transcript text is sent to your configured endpoint.
