# Contributing and local verification

1. Install the stable Flutter SDK and platform tools.
2. Run `flutter pub get`.
3. Run `dart format lib test`, `flutter analyze`, and `flutter test`.
4. Check the `Flutter checks` workflow on your branch.
5. For camera testing, use a physical device or a simulator with camera support.

This repository is an early prototype; do not use it as the sole recordkeeping
system for a real business until database migrations, backup/restore, receipts,
returns, and device-specific testing are complete.
