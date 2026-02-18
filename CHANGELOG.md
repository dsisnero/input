# Changelog

## Unreleased

- Added CI workflow to run Crystal specs on `ubuntu-latest` and `windows-latest`.
- Ported Windows console parity paths:
  - Windows `cancelreader` behavior with console mode setup/reset.
  - Reader Windows console event loop (`peek/read` record flow).
  - Windows parser coverage for key, mouse, focus, and window size events.
- Completed full Go `TestParseSequence` matrix parity in Crystal specs.
- Added Kitty Graphics APC parsing and `KittyGraphicsEvent`.
- Added Crystal fuzz-equivalent parser specs for non-zero width and randomized interleaved input progress checks.
