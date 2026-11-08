# Progress Notes (internal use only — not for the user)

## Goal
Material 3 Flutter app talking to HF server `https://thed1-aiagent.hf.space` (FastAPI).
Bottom nav: home, task, history, upload (empty placeholder), settings.
Build APKs via GitHub Actions: arm64-v8a, armeabi-v7a, universal + GitHub release.

## Server facts (verified from app.py chunks 0-3)
- Base: https://thed1-aiagent.hf.space
- POST /start_download {url} -> { task_id }
- GET /status/{task_id} -> task { task_id,url,status,total_size,downloaded,speed,file_path,original_filename,resumable,timestamp,error,eta_seconds,verified }
- GET /download/{task_id} -> file download
- GET /stream/{task_id} -> Range/206 streaming (application/octet-stream)
- GET /history -> { history: [tasks] }
- GET /server_status -> ram/storage/online/active_tasks/uptime
- GET /storage -> disk budget
- NO /rename endpoint. NO single-file /delete endpoint (only /delete_all).
- NO media metadata (resolution/bitrate) endpoint.

## Constraints honored
- Server URL NOT hardcoded — stored in SharedPreferences, editable in Settings (default = HF server).
- No fake delete/rename. Buttons present; server calls attempted; honest "not supported" dialog if unsupported.
- Animations via flutter_animate (pub.dev), NOT hand-built.
- Material 3 design.

## Environment blocker (sandbox)
- apt repos unreachable; storage.googleapis.com & pub.dev BLOCKED here.
- Flutter SDK cloned to ~/flutter (git from github.com works).
- Cannot run `flutter`/`flutter pub get` locally (Dart SDK comes from storage.googleapis.com).
- => Code NOT `flutter analyze`-verified locally. GitHub Actions runners have full internet and will build + release.

## Files created
- pubspec.yaml (http, shared_preferences, url_launcher, flutter_animate)
- lib/main.dart (AppServices InheritedWidget, MaterialApp, NavigationBar bottom nav)
- lib/models/task_model.dart (TaskModel + ServerStatus, honest parsing, progress 0-1 guard)
- lib/services/api_service.dart (startDownload/getStatus/getHistory/getServerStatus, downloadUrl/streamUrl)
- lib/services/settings_service.dart (SharedPreferences server URL, default HF)
- lib/screens/home_screen.dart (Material 3 URL box + download button)
- lib/screens/task_screen.dart (active tasks, polling /history every 3s, pull-to-refresh)
- lib/screens/history_screen.dart (completed/failed tasks, pull-to-refresh)
- lib/screens/upload_screen.dart (empty placeholder)
- lib/screens/settings_screen.dart (server URL save/reset, honest info panel)
- lib/widgets/task_card.dart (progress, size, speed, ETA)
- lib/widgets/history_card.dart (info/copy-link/stream/delete/rename, all honest)
- android/{settings.gradle,build.gradle,app/build.gradle w/ ABI splits armeabi-v7a+arm64-v8a}
- android/app/src/main/{AndroidManifest.xml, MainActivity.kt, strings.xml, proguard-rules.pro}
- android/app/src/main/res/{values/themes.xml,colors.xml,drawable/launch_background.xml,mipmap-*/ic_launcher.png}
- .github/workflows/android-apk.yml (Java17 + Flutter stable + gradle wrapper + signing keystore + split+universal APKs + gh-release)
- .gitignore, README.md, progress.md

## Status
- [x] Explore repo & HF server
- [x] Clone Flutter SDK (~/flutter)
- [x] Create Flutter project (all source files)
- [x] Implement models + api_service + settings_service
- [x] Home, Task, History, Upload(placeholder), Settings screens
- [x] Bottom nav + Material 3 + animations
- [x] Android config + launcher icons/themes
- [x] GitHub Actions workflow (3 APKs + release)
- [ ] Commit & push to arena/14c2d171-ai
- [ ] Verify GitHub Actions builds + releases APKs
