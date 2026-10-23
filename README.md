# Murmur

On-device dictation for macOS, in the style of Wispr Flow. Press Option-Space, speak, press it again, and the text is pasted wherever the cursor is, in browsers and native apps alike. Nothing leaves the Mac: speech-to-text is Apple's SpeechTranscriber and the optional cleanup is Apple Intelligence (Foundation Models).

Requires macOS 26 or later on Apple silicon; cleanup also needs Apple Intelligence turned on.

## Install

```sh
./scripts/build.sh
```

This builds the app, draws its icon and installs it at `/Applications/Murmur.app`. On first use, allow Microphone and Accessibility (Accessibility lets it paste for you; without it the text is left on the clipboard).

## Use

- **Option-Space** starts listening; a pill at the bottom of the screen shows your voice level. Option-Space again stops and pastes.
- **Menu bar:** Clean Up with Apple Intelligence (on or off), Edit Cleanup Rules…, Open at Login.
- **Rules file** (`~/Library/Application Support/Murmur/rules.md`): plain-English rules for the cleanup, then a `## Replacements` list of `heard → written` swaps. The swaps run as find-and-replace, even with cleanup off, because the on-device model applied a word list unreliably.

## Test

`swift test` covers the pure text handling (rules parsing, word swaps, reply tidying) and runs on CI with lint and a release build. Speech recognition and Apple Intelligence cleanup can't run on CI, so check them by hand:

```sh
swift build -c release
.build/release/Murmur --transcribe sample.aiff   # prints the raw and cleaned transcript
say -o sample.aiff "um so I I think we should meet at three, no, at four"   # makes a sample
```

The build is ad-hoc signed, so macOS forgets the Accessibility grant after each rebuild: tick Murmur again in System Settings › Privacy & Security › Accessibility.
