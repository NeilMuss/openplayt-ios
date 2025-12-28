# iOS MVP notes

## Playback and queue behavior
- `PlayerService` owns a simple list-based queue. Loading an album or custom queue resets the index, clears the current song, and notifies observers before playback begins.【F:software/python-player/playt_player/application/player_service.py†L32-L55】
- `play()` starts playback from the first queued track if none is active, delegates file playback to the audio backend, and emits `track_started`; `pause()` only fires when audio is playing and emits `track_paused` to observers.【F:software/python-player/playt_player/application/player_service.py†L56-L71】
- `next()`/`previous()` move the queue index forward or backward and restart playback of the selected track; reaching the end triggers `queue_ended` after stopping, while `previous()` restarts the current track when already at the beginning.【F:software/python-player/playt_player/application/player_service.py†L81-L110】
- `seek()` passes the target position to the audio backend and notifies observers with the new position; `check_playback_status()` should be polled to auto-advance when the backend reports `idle` after a track ends.【F:software/python-player/playt_player/application/player_service.py†L111-L181】
- The FFmpeg backend shells out to `ffplay`, tracks elapsed time to report positions, supports resume via POSIX signals, clamps volume, and restarts playback to apply volume or seek changes; it raises runtime errors when `ffplay` is missing or file paths are invalid.【F:software/python-player/playt_player/infrastructure/audio/ffmpeg_audio_player.py†L1-L190】

## UI hooks and decisions
- The WebView UI exposes a JavaScript bridge for play/pause/toggle, next/prev, seek, volume, and file-picking; all UI actions log through the shared logger before delegating to `PlayerService`. Basic album metadata (title, artist, album, duration, cover art, slideshow images) is pushed to JS on track or album change to drive display.【F:software/python-player/playt_player/interface/gui/webview_ui.py†L18-L120】【F:software/python-player/playt_player/interface/gui/webview_ui.py†L237-L319】
- The UI polls playback progress every 0.5s, calling `check_playback_status()` to auto-advance on natural track end and emitting progress events to JS only when playing, keeping state transitions explicit and event-driven.【F:software/python-player/playt_player/interface/gui/webview_ui.py†L320-L335】
- CLI mode provides the same core transport controls plus cartridge loading, status display, and help. It attaches logging observers to echo events and reports errors when cartridge discovery or parsing fails.【F:software/python-player/playt_player/interface/cli/player_cli.py†L25-L175】

## Must-ship MVP feature set
- Transport: play, pause, stop, next, previous, and seek mapped to `PlayerService` methods and exposed through both the JS bridge and CLI commands.【F:software/python-player/playt_player/application/player_service.py†L56-L181】【F:software/python-player/playt_player/interface/gui/webview_ui.py†L29-L68】【F:software/python-player/playt_player/interface/cli/player_cli.py†L69-L92】
- Queue handling: load album/custom queues, start from the first track, advance linearly, and signal end-of-queue; restart current track on “previous” at index 0.【F:software/python-player/playt_player/application/player_service.py†L32-L110】
- Metadata display: propagate track title, artist, album, duration, cover art, and slideshow images to the UI on album/track changes.【F:software/python-player/playt_player/interface/gui/webview_ui.py†L237-L319】
- Basic settings: volume control mapped to 0.0–1.0 slider, with ffplay restarts to apply live changes; status command surfaces state and position for CLI debugging.【F:software/python-player/playt_player/infrastructure/audio/ffmpeg_audio_player.py†L35-L190】【F:software/python-player/playt_player/interface/gui/webview_ui.py†L69-L72】【F:software/python-player/playt_player/interface/cli/player_cli.py†L151-L162】

## Error handling, retries, and logging
- FFmpeg backend raises clear runtime errors when `ffplay` is unavailable or file paths are invalid; seek/volume operations are ignored when no file is active, preventing crashes from bad states.【F:software/python-player/playt_player/infrastructure/audio/ffmpeg_audio_player.py†L20-L190】
- CLI cartridge loading validates file/dir existence, distinguishes .playt archives vs. JSON folders, and reports failures to find, read, or parse cartridges before attempting playback.【F:software/python-player/playt_player/interface/cli/player_cli.py†L100-L150】【F:software/python-player/playt_player/interface/cli/player_cli.py†L220-L239】
- Logging uses an observer-driven `CLILogger`, allowing stdout/stderr observers to be attached once and filtering messages by log level; UI commands and playback events feed into the same logger for consistent diagnostics.【F:software/python-player/playt_player/infrastructure/logging/cli_logger.py†L1-L130】【F:software/python-player/playt_player/interface/gui/webview_ui.py†L25-L72】
- Observer pattern across `PlayerService`, UI, and loggers keeps state transitions explicit and makes it easy to broadcast events (track start/pause/stop, queue end, seek, volume changes) to multiple outputs.【F:software/python-player/playt_player/domain/interfaces/observer.py†L7-L68】【F:software/python-player/playt_player/application/player_service.py†L56-L181】

## Non-goals for the MVP
- No playlist editing beyond loading a full album/custom list; there is no per-track add/remove or reordering in the current service.
- No shuffle, repeat, or crossfade behaviors; queue advances linearly and stops at the end.
- No lyrics, EQ, or visualization pipelines beyond the stub callbacks already present; focus stays on core transport and metadata surfaces.
- No background download/streaming or retry logic—playback assumes local files provided by cartridges.
- No authentication, social features, or recommendation logic; scope is limited to offline playback and basic controls.
