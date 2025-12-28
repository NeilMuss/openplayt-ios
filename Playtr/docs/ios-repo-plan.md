# iOS App Repository Plan

This repository currently hosts the Python player. To build the iPhone app in its own repository (as intended), create a new Git project outside this tree and keep the two codebases isolated.

## Why a separate repository?
- Avoid accidental coupling between Python and iOS code and keep histories clean.
- Simplify CI and dependency management (Swift tooling stays separate from Python).
- Keep binary artifacts and platform-specific assets out of the Python repo.

## How to create the new iOS repository
1. **Create a sibling directory** (outside this repo):
   ```bash
   cd ..
   mkdir openplayt-ios
   cd openplayt-ios
   git init -b main
   ```
2. **Add a remote** once you create the new Git hosting project:
   ```bash
   git remote add origin <your-ios-repo-url>
   ```
3. **Seed the project skeleton** (Swift Package Manager or Xcode):
   - `swift package init --type executable` (for a SwiftPM app target), or create an Xcode app project.
   - Recommended top-level folders: `App/` (entry point), `CorePlayback/`, `Queue/`, `UI/`, `Tests/`, `Docs/`.
4. **Copy over notes (not code) from this repo** as needed (e.g., design principles), but keep the Python source out of the new repo to avoid relicensing or dependency confusion.
5. **Create a `.gitignore`** tailored for Swift/Xcode to avoid committing derived data and builds.
6. **Make the first commit** with the empty skeleton, README, and the initial notes. Push to the new remote when ready.

## Suggested initial README content for the new repo
- Purpose: parity with the Python player, same design philosophy.
- MVP goals: play/pause, seek, next/previous, queue add/remove, metadata display, simple settings, clear error handling.
- Architecture sketch: small modules (state machine + queue), thin AVPlayer adapter, SwiftUI UI layer, XCTest.
- How to build and test: `make build`, `make test` (or `swift test`/`xcodebuild test`).

## Early task checklist
- [ ] Document Python player behaviors that must be mirrored (playback states, queue rules, error handling).
- [ ] Stand up the iOS project skeleton and CI scaffolding in the new repo.
- [ ] Implement the playback state machine with unit tests.
- [ ] Port queue management with tests.
- [ ] Add AVPlayer adapter behind a protocol; mock it in tests.
- [ ] Build minimal SwiftUI UI with accessibility labels; add view-model/snapshot tests when stable.
- [ ] Add logging/error flows mirroring Python’s user experience.

## Tips to avoid rework/token burn
- Work in small branches and run tests after each change.
- Keep early layers pure (state machine, queue) so they are cheap to test.
- Gate simulator-dependent tests to avoid CI flakiness.
- Maintain a living `Docs/ios-mvp-notes.md` in the new repo to track decisions and non-goals.
