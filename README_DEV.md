# MacSquak Developer Guide

## Architecture overview
MacSquak is a SwiftUI menu bar app with a local Python worker for transcription.

### Swift components
- `MacSquakApp.swift` — app entry + menu bar UI
- `AppViewModel.swift` — state machine and orchestration
- `SettingsView.swift` — settings UI
- `Services/AudioRecorderService.swift` — WAV recording via AVFoundation
- `Services/TranscriptionService.swift` — worker execution + retries + JSON decoding
- `Services/PythonRuntimeManager.swift` — self-contained runtime bootstrap using `uv`
- `Services/ClipboardService.swift` — clipboard writes
- `Services/LLMPostProcessor.swift` — optional post-processing
- `Services/KeychainService.swift` — API key storage in macOS Keychain
- `Models/AppSettings.swift` — persisted settings model

### Python worker
- Bundled resource: `Sources/Resources/transcribe_parakeet.py`
- Runtime copy target: `~/Library/Application Support/MacSquak/runtime/bin/transcribe_parakeet.py`
- JSON contract:
  - `ok: bool`
  - `text: string|null`
  - `model: string|null`
  - `elapsed_seconds: number|null`
  - `error: string|null`

## Runtime bootstrap flow
On first transcription:
1. Ensure `~/Library/Application Support/MacSquak/runtime/` exists
2. Create venv with `uv venv`
3. Install `parakeet-mlx` via `uv pip install --python <venv>/bin/python parakeet-mlx`
4. Copy bundled worker script to runtime `/bin` and make executable
5. Execute worker using runtime python

## Local development
```bash
swift build
swift test
swift run
```

## Release checklist
- [ ] `swift build` passes
- [ ] `swift test` passes
- [ ] Verify hotkey modes (toggle + hold)
- [ ] Verify bootstrap from clean runtime directory
- [ ] Verify clipboard output
- [ ] Verify failure mode keeps audio file
- [ ] Verify settings persistence + keychain save

## Future improvements
- Runtime prewarm button in Settings
- Explicit bootstrap progress UI
- Retry button for failed transcripts in menu
- Signed/notarized app packaging


## App bundle packaging (for stable bundle id + Accessibility)
Use the packaging script to run MacSquak as a real `.app` with a bundle identifier:

```bash
./scripts/package_app.sh
open dist/MacSquak.app
```

Optional overrides:
```bash
BUNDLE_ID=com.sglyon.macsquak CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/package_app.sh
```

This avoids the missing bundle identifier issues seen when running from `swift run`/package-only mode.
