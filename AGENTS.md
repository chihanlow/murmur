# Murmur: agent guide
On-device dictation for macOS: Option-Space toggles listening, then the text is cleaned up and pasted into the focused app. Why it exists: a local, free Wispr Flow for Jason.

## Layout
Sources/Murmur/: AppController (menu, state) · Transcriber (mic → SpeechTranscriber) · Cleaner (rules file, Foundation Models) · Paster (clipboard + ⌘V) · HotKey (Carbon) · HUD · scripts/ (build, icon)

## Commands
Build and install: `./scripts/build.sh` · Test the pipeline: `.build/release/Murmur --transcribe <audio file>`

## Conventions
- Every behaviour change: a CHANGELOG line under "Unreleased".
- Check cleanup prompt changes on several dictated samples with `--transcribe`; the small on-device model is sensitive to wording (see the comment in Cleaner.swift).

## Never
- Send audio or text off the Mac; local-only is the point.
- Activate the app or its HUD when dictating; that steals focus from the field the text is pasted into.
