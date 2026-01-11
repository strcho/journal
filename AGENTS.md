# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds Dart source; the entry point is `lib/main.dart`.
- `test/` contains Flutter tests (currently `test/widget_test.dart`).
- Platform targets live in `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`.
- Project configuration is in `pubspec.yaml` and lint rules in `analysis_options.yaml`.
- Web assets and icons are under `web/` and its `icons/` subfolder.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies from `pubspec.yaml`.
- `flutter run` launches the app on the connected device or simulator.
- `flutter test` runs all tests under `test/`.
- `flutter analyze` runs static analysis using `analysis_options.yaml`.
- `flutter build <target>` produces release builds, e.g. `flutter build apk`, `flutter build ios`, or `flutter build web`.

## Coding Style & Naming Conventions
- Use Dart formatting with 2-space indentation; run `dart format .` before committing.
- File names use `snake_case.dart`; classes use `UpperCamelCase`; variables and methods use `lowerCamelCase`.
- Follow `flutter_lints` defaults (see `analysis_options.yaml`). Prefer `const` widgets where possible.

## Testing Guidelines
- Use the `flutter_test` framework; name tests `*_test.dart` under `test/`.
- For widget tests, use `testWidgets(...)` and keep tests focused on a single behavior.
- Run `flutter test` before submitting changes that affect UI or logic.

## Commit & Pull Request Guidelines
- This repository does not include Git history, so no established commit convention is available. Use concise, imperative subjects (e.g., "Add onboarding screen") or Conventional Commits (e.g., `feat: add onboarding screen`).
- Pull requests should include a short summary, test results, and screenshots or screen recordings for UI changes.
- Link related issues or tickets when applicable.

## Security & Configuration Tips
- Avoid committing secrets; prefer `--dart-define` or platform-specific secret storage.
- `android/local.properties` is machine-specific; adjust locally as needed without relying on it for shared config.

## Agent Response Rules
- 使用中文总结修改和计划。
