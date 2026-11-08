# AI Agent Downloader

Material 3 Flutter app that downloads files from **your own server** (default: the Hugging Face Space
`THED1/AIAGENT` → `https://thed1-aiagent.hf.space`). The server URL is fully configurable in Settings —
**nothing is hardcoded**.

## Screens (bottom navigation)

| Tab | Purpose |
|-----|---------|
| **Home** | Paste a file URL → send it to the server for download via `POST /start_download` |
| **Task** | Current/running downloads with live progress, size, speed, ETA (polls `GET /status/{id}`) |
| **History** | Completed & failed downloads as cards with info / copy-link / stream / delete / rename |
| **Upload** | Intentionally empty (placeholder) |
| **Settings** | Change & save the server URL (SharedPreferences, not hardcoded) |

## Server contract (verified against `THED1/AIAGENT/app.py`)

- `POST /start_download {url}` → `{ task_id }`
- `GET /status/{task_id}` → `{ task_id, url, status, total_size, downloaded, speed, original_filename, error, ... }`
- `GET /download/{task_id}` → file download
- `GET /stream/{task_id}` → Range / 206 streaming (opens in the device's video player)
- `GET /history` → `{ history: [ ... ] }`
- `GET /server_status` → RAM / storage / online / active tasks

**Honest limitations (not faked):** this server exposes no single-file **delete** or **rename** endpoint
(only `/delete_all`), and no media-metadata endpoint (resolution / bitrate). Those actions show an honest
"not supported by server" message, and resolution/bitrate are shown as "not available" rather than invented.

## Build

APKs are built by GitHub Actions (`.github/workflows/android-apk.yml`) on every push to
`arena/14c2d171-ai` (and via `workflow_dispatch`):

- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM / arm7rb)
- `universal` (fat APK, all ABIs)

A GitHub Release is created automatically with the three APKs attached.

## Notes

- Animations use the `flutter_animate` package (not hand-built).
- Design is Material 3.
- `progress.md` is an internal scratch file (not shipped to users).
