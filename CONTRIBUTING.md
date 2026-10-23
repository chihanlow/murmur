# Contributing

Murmur is a small personal tool, so open an issue before a large change to check it fits.

## Making a change

1. Branch from `main` and keep each pull request to one change.
2. Run `swift test` and `swift format lint -r --strict Package.swift Sources Tests scripts`; CI runs both.
3. Add a test for any change to `Sources/MurmurCore`, and a line under "Unreleased" in `CHANGELOG.md`.
4. If you change the cleanup prompt in `Cleaner.swift`, check it on several dictated samples with `.build/release/Murmur --transcribe <audio file>`, because the on-device model is sensitive to wording.

Murmur must never send audio or text off the Mac; changes that do will not be merged.
