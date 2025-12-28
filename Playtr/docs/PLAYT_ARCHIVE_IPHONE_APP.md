# PlaytArchive Layout (Local Library)

This document defines the **canonical on-disk layout** for storing Playt cartridges long-term and for enabling **local-first playback** during development (including iPhone testing).

The key design goal is simple:

> A Playt is identified by its `cartridge_id`. Filenames are never authoritative.

---

## Canonical folder structure

A Playt archive is a folder containing a `cartridges/` directory. Each cartridge lives in a subfolder named **exactly** its `cartridge_id`.

```
PlaytArchive/
├── index.json                 # optional accelerator; safe to delete and rebuild
└── cartridges/
    ├── LN1998-001/
    │   ├── playt.json         # required; authoritative identity + metadata
    │   ├── audio/             # recommended
    │   ├── images/            # optional
    │   ├── video/             # optional (future)
    │   ├── docs/              # optional (liner notes, PDFs, etc.)
    │   └── package.playt      # optional original downloaded ZIP
    ├── ECM2023-014/
    │   ├── playt.json
    │   └── audio/
    └── ...
```

### Rules

1. **Folder name == `cartridge_id`**
2. `playt.json` inside that folder is required and is the source of truth.
3. Media paths referenced by `playt.json` should be **relative** to the cartridge folder.
4. A `.playt` file is a ZIP package. Keeping the original `.playt` (`package.playt`) is optional once extracted.

---

## Minimal requirements for a cartridge

A cartridge is playable if it contains:

- `playt.json`
- the referenced media files (usually audio)

At minimum, `playt.json` must include a stable identifier:

```json
{
  "cartridge_id": "LN1998-001",
  "title": "Example Album",
  "artist": "Example Artist"
}
```

> The player/app should always trust `cartridge_id` inside `playt.json` over any filename.

---

## Local-first resolution (how NFC / deep links should work)

The NFC flow (bootstrap URL → deep link) delivers a `cartridge_id` to the app.

When the app receives `cartridge_id=LN1998-001`, it should:

1. Look for a matching local cartridge folder:
   - `PlaytArchive/cartridges/LN1998-001/playt.json`
2. If present, load and play immediately (offline).
3. If missing, fall back to download/network bootstrap.

This enables the “found a box in the attic” scenario and makes early iPhone testing easy.

---

## Recommended download naming (nice-to-have)

When a user downloads a Playt package, servers should suggest a filename matching the cartridge id:

- `LN1998-001.playt`

This improves human clarity, but the app must still handle renamed downloads like:

- `LN1998-001 (1).playt`
- `Giants_of_Jazz.playt`

because identity is derived from `playt.json`.

---

## Import behavior (strong recommendation)

When importing a `.playt` ZIP:

1. Extract to a temp folder
2. Read `cartridge_id` from the extracted `playt.json`
3. Move/merge into:

```
PlaytArchive/cartridges/<cartridge_id>/
```

4. Rebuild/update `index.json` (optional)

---

## index.json (optional)

`index.json` is an optional accelerator mapping `cartridge_id → path` for fast startup.

It is safe to delete; it can always be rebuilt by scanning for `playt.json`.

Example:

```json
{
  "LN1998-001": "cartridges/LN1998-001",
  "ECM2023-014": "cartridges/ECM2023-014"
}
```

---

## iPhone testing notes

For early iOS development, you can treat the app’s sandboxed “Documents” directory as a PlaytArchive root:

```
<App Documents>/PlaytArchive/cartridges/<cartridge_id>/
```

This lets you test:

- importing `.playt` packages
- local-first playback from `cartridge_id`
- re-indexing on launch

without requiring any backend or network availability.

