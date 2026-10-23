# Murmur: agent guide
On-device dictation for macOS: Option-Space toggles listening, then the text is cleaned up and pasted into the focused app. Why it exists: a local, free Wispr Flow for Jason.

## Layout
Sources/MurmurCore/: TextRules (rules parsing, word swaps, reply tidying; pure, tested) · Sources/Murmur/: AppController (menu, state) · Transcriber (mic → SpeechTranscriber) · Cleaner (rules file, Foundation Models) · Paster (clipboard + ⌘V) · HotKey (Carbon) · HUD · Tests/MurmurCoreTests/ · docs/decisions/ · scripts/ (build, icon)

## Commands
Build and install: `./scripts/build.sh` · Test: `swift test` · Lint: `swift format lint -r --strict Package.swift Sources Tests scripts` · Test the pipeline by hand: `.build/release/Murmur --transcribe <audio file>`

## Conventions
- Every behaviour change: a test (where it is in MurmurCore) and a CHANGELOG line under "Unreleased".
- Keep logic that needs no Apple frameworks beyond Foundation in MurmurCore so CI can test it; speech and Foundation Models stay in the app target (docs/decisions/0001).
- Check cleanup prompt changes on several dictated samples with `--transcribe`; the small on-device model is sensitive to wording (see the comment in Cleaner.swift).

## Never
- Send audio or text off the Mac; local-only is the point.
- Activate the app or its HUD when dictating; that steals focus from the field the text is pasted into.
