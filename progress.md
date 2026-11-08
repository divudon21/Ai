# Progress Notes (internal use only — not for the user)

## Goal
Material 3 Flutter app talking to HF server `https://thed1-aiagent.hf.space` (FastAPI).
Bottom nav: home, task, history, upload (empty placeholder), settings.
Build APKs via GitHub Actions: arm64-v8a, armeabi-v7a, universal + GitHub release.

## Server facts (verified from app.py chunks 0-3)
- Base: https://thed1-aiagent.hf.space
- POST /start_download {url} -> { task_id }
- GET /status/{task_id} -> task object
- GET /download/{task_id} -> file download
- GET /stream/{task_id} -> Range/206 streaming
- GET /history -> { history: [tasks] }
- GET /server_status -> ram/storage/online/active_tasks/uptime
- NO /rename endpoint. NO single-file /delete endpoint (only /delete_all).
- NO media metadata (resolution/bitrate) endpoint.

## Constraints honored
- Server URL NOT hardcoded — stored in SharedPreferences, editable in Settings (default HF).
- No fake delete/rename — honest "not supported by server" dialogs.
- Animations via flutter_animate (NOT hand-built).
- Material 3 design.

## CI status
- Workflow `.github/workflows/android-apk.yml` committed (valid YAML).
- Test workflow (`echo`) PASSED on this repo → workflows run fine.
- Run 1 got through `flutter pub get`, failed only at Gradle (gradle not preinstalled).
- Self-bootstrapping `android/gradlew` (downloads Gradle 8.5 from services.gradle.org) added.
- Subsequent runs fail fast; I CANNOT read Actions logs from this sandbox (results-receiver blocked).
- => CI build + release could NOT be fully verified here. User can trigger/monitor on GitHub.

## Files (28)
pubspec.yaml, lib/ (main, models/task_model, services/api_service+settings_service,
 screens/home+task+history+upload+settings, widgets/task_card+history_card),
 android/ (settings.gradle, build.gradle, app/build.gradle w/ ABI splits armeabi-v7a+arm64-v8a,
 gradlew [exec], gradle/wrapper/gradle-wrapper.properties, app/src/main/...),
 .github/workflows/android-apk.yml, .gitignore, README.md, progress.md

## Status
- [x] Explore repo & HF server
- [x] Clone Flutter SDK (~/flutter)
- [x] Write all Flutter source
- [x] Android config + self-bootstrapping Gradle wrapper
- [x] GitHub Actions workflow (3 APKs + release)
- [x] Commit & push to arena/14c2d171-ai
- [ ] Open PR (user requested)
- [ ] Verify CI build + release on GitHub (sandbox can't read logs)
