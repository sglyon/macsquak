# MacSquak User Guide

MacSquak is a local-first macOS menu bar app for speech-to-text using NVIDIA Parakeet (via `parakeet-mlx`).

## What it does
- Record speech with a global hotkey
- Transcribe locally on your Mac
- Copy transcript to clipboard automatically
- Optionally auto-paste/type into the active app
- Optionally post-process transcript with an LLM prompt
- Keep audio files when transcription fails

## Requirements
- macOS (Apple Silicon recommended)
- Microphone permission enabled
- `uv` installed (`brew install uv`)

## Install & run
1. Open Terminal in project folder.
2. Run:
   ```bash
   swift build
   swift run
   ```
3. On first transcription, MacSquak auto-installs the Python runtime and model dependencies locally.

## First use
1. Click the menu bar icon (waveform).
2. Open Settings and confirm hotkey (default: `Cmd+Shift+R`).
3. Choose recording mode:
   - **Toggle**: press once to start, press again to stop
   - **Hold**: hold key to record, release to transcribe
4. Speak, then stop/ release.
5. Transcript is copied to clipboard.

## Optional LLM post-processing
In Settings:
- Enable post-processing
- Set endpoint URL
- Set prompt template (`{raw_transcript}` placeholder supported)
- Save API key (stored in macOS Keychain)

If post-processing fails, raw transcript is still used.

## Where files are stored
- Audio: `~/Library/Application Support/MacSquak/recordings/`
- App settings: `~/Library/Application Support/MacSquak/settings.json`
- Runtime (uv + venv + worker): `~/Library/Application Support/MacSquak/runtime/`
- Logs: `~/Library/Application Support/MacSquak/macsquak.log`

## Troubleshooting
- **No transcription**: confirm `uv` exists in PATH and microphone permission is granted.
- **Runtime bootstrap fails**: open log file above and re-run app.
- **No clipboard output**: check status in menu bar panel and logs.
