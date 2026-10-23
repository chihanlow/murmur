# 1. Test the pure text logic; check speech and cleanup by hand

Date: 2026-10-23

## Context

Murmur's pipeline is microphone → SpeechTranscriber → Foundation Models cleanup → paste. Speech recognition and Apple Intelligence need on-device models and permissions that a GitHub runner doesn't have, and the cleanup model's output depends on prompt wording.

## Decision

The pure text handling (parsing the rules file, word swaps, tidying the model's reply) lives in the `MurmurCore` library target, and `swift test` covers it on CI. The speech and cleanup steps stay in the `Murmur` app target and are checked by hand with `.build/release/Murmur --transcribe <audio file>`, as the README describes.

## Consequences

CI catches regressions in rules parsing and post-processing, not in recognition quality or cleanup wording. Any change to the cleanup prompt still needs the manual `--transcribe` check on several samples.
