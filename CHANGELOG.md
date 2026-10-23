# Changelog

## Unreleased

- Rules file: only `-` or `*` list lines under `## Replacements` count as word swaps, so the default file's explanatory line is no longer read as a junk swap. Added SECURITY.md and CONTRIBUTING.md.
- Tests for rules parsing, word swaps and reply tidying (new `MurmurCore` library), plus CI (lint, build, test on macOS 26), swift-format config, pre-commit hook, PR template and Dependabot.
- First version: Option-Space dictation, Apple Intelligence cleanup from a rules file, find-and-replace word swaps, paste into the focused app, menu bar controls and app icon.
