#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "TestAssets", "TestPlaytArchive"))
DEFAULT_BESSIE_SRC = os.path.normpath(
    "/Users/neilmussett/Library/Mobile Documents/com~apple~CloudDocs/Documents/OpenPlayt/software/playt-authoring-app/samples/smith-bessie-1926-28-giants-of-jazz-disc-1"
)
DEFAULT_SPELLS_SRC = os.path.normpath(
    "/Users/neilmussett/Library/Mobile Documents/com~apple~CloudDocs/Documents/The Spells - The Night Has Eyes"
)


def has_ffmpeg() -> bool:
    return shutil.which("ffmpeg") is not None


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def sanitize_filename(name: str) -> str:
    normalized = unicodedata.normalize("NFKD", name)
    ascii_name = normalized.encode("ascii", "ignore").decode("ascii")
    ascii_name = ascii_name.replace("/", "-").replace(":", " - ")
    ascii_name = re.sub(r"[^\w\s\-\.,'()]", "", ascii_name)
    ascii_name = re.sub(r"\s+", " ", ascii_name).strip()
    return ascii_name or "Track"


def convert_to_m4a(src: str, dest: str) -> None:
    ensure_dir(os.path.dirname(dest))
    command = [
        "ffmpeg",
        "-y",
        "-i",
        src,
        "-vn",
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-movflags",
        "+faststart",
        dest,
    ]
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def copy_audio(src: str, dest: str) -> None:
    ensure_dir(os.path.dirname(dest))
    shutil.copy2(src, dest)


def write_playt_json(path: str, payload: dict) -> None:
    ensure_dir(os.path.dirname(path))
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True)
        handle.write("\n")


def build_bessie_album(src_root: str, out_root: str, track_limit: int) -> bool:
    playt_path = os.path.join(src_root, "playt.json")
    with open(playt_path, "r", encoding="utf-8") as handle:
        playt_data = json.load(handle)

    tracks = playt_data.get("tracks", [])[:track_limit]
    if not tracks:
        print("No tracks found in Bessie sample playt.json.", file=sys.stderr)
        return False

    cartridge_id = "BS1926-001"
    cartridge_root = os.path.join(out_root, "cartridges", cartridge_id)
    if os.path.isdir(cartridge_root):
        shutil.rmtree(cartridge_root)
    audio_root = os.path.join(cartridge_root, "audio")
    ensure_dir(audio_root)

    output_tracks = []
    for index, track in enumerate(tracks, start=1):
        title = track.get("title", f"Track {index}")
        src_audio = os.path.join(src_root, track.get("audio", ""))
        ext = os.path.splitext(src_audio)[1].lower()
        file_title = sanitize_filename(title)
        dest_name = f"{index:02d} - {file_title}.m4a"
        dest_path = os.path.join(audio_root, dest_name)

        if ext in {".m4a", ".mp3"}:
            copy_audio(src_audio, dest_path if ext == ".m4a" else dest_path.replace(".m4a", ext))
            dest_rel = f"audio/{os.path.basename(dest_path if ext == '.m4a' else dest_path.replace('.m4a', ext))}"
        else:
            if not has_ffmpeg():
                print("ffmpeg not found; cannot convert Bessie FLAC files.", file=sys.stderr)
                return False
            convert_to_m4a(src_audio, dest_path)
            dest_rel = f"audio/{os.path.basename(dest_path)}"

        output_tracks.append(
            {
                "number": index,
                "title": title,
                "path": dest_rel,
            }
        )

    album = playt_data.get("album", {})
    payload = {
        "cartridge_id": cartridge_id,
        "title": album.get("title", "Giants of Jazz: Bessie Smith"),
        "artist": album.get("artist", "Smith, Bessie"),
        "year": album.get("year", 1923),
        "tracks": output_tracks,
    }
    write_playt_json(os.path.join(cartridge_root, "playt.json"), payload)
    return True


def parse_spells_album_info(folder_name: str) -> dict:
    artist = "The Spells"
    title = "The Night Has Eyes"
    year = None

    if " - " in folder_name:
        parts = folder_name.split(" - ", 1)
        if parts[0].strip():
            artist = parts[0].strip()
        if parts[1].strip():
            title = parts[1].strip()

    year_match = re.search(r"(19|20)\d{2}", folder_name)
    if year_match:
        year = int(year_match.group(0))

    return {"artist": artist, "title": title, "year": year}


def build_spells_album(src_root: str, out_root: str, track_limit: int) -> bool:
    if not os.path.isdir(src_root):
        print(f"Spells source folder missing: {src_root}", file=sys.stderr)
        return False

    entries = []
    for entry in os.listdir(src_root):
        path = os.path.join(src_root, entry)
        if os.path.isfile(path) and os.path.splitext(entry)[1].lower() in {".flac", ".mp3", ".m4a", ".wav"}:
            entries.append(entry)

    entries.sort()
    if not entries:
        print("No audio files found in Spells folder.", file=sys.stderr)
        return False

    selected = entries[:track_limit]
    info = parse_spells_album_info(os.path.basename(src_root))

    cartridge_id = "SPELLS201x-001"
    cartridge_root = os.path.join(out_root, "cartridges", cartridge_id)
    if os.path.isdir(cartridge_root):
        shutil.rmtree(cartridge_root)
    audio_root = os.path.join(cartridge_root, "audio")
    ensure_dir(audio_root)

    output_tracks = []
    for index, filename in enumerate(selected, start=1):
        src_audio = os.path.join(src_root, filename)
        ext = os.path.splitext(filename)[1].lower()
        base_title = os.path.splitext(filename)[0]
        base_title = re.sub(r"^\d+\s*[-._ ]\s*", "", base_title)
        prefix = f"{info['artist']} - {info['title']} - "
        if base_title.startswith(prefix):
            base_title = base_title[len(prefix) :]
        base_title = re.sub(r"^\d+\s*[-._ ]\s*", "", base_title)
        title = sanitize_filename(base_title)
        dest_ext = ".m4a" if ext == ".flac" or ext == ".wav" else ext
        dest_name = f"{index:02d} - {title}{dest_ext}"
        dest_path = os.path.join(audio_root, dest_name)

        if ext in {".m4a", ".mp3"}:
            copy_audio(src_audio, dest_path)
        else:
            if not has_ffmpeg():
                print("ffmpeg not found; skipping Spells album conversion.", file=sys.stderr)
                return False
            convert_to_m4a(src_audio, dest_path)

        output_tracks.append(
            {
                "number": index,
                "title": title,
                "path": f"audio/{os.path.basename(dest_path)}",
            }
        )

    payload = {
        "cartridge_id": cartridge_id,
        "title": info["title"],
        "artist": info["artist"],
        "tracks": output_tracks,
    }
    if info["year"]:
        payload["year"] = info["year"]

    write_playt_json(os.path.join(cartridge_root, "playt.json"), payload)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a minimal PlaytArchive for iPhone testing.")
    parser.add_argument("--out-root", default=DEFAULT_OUT_ROOT, help="Output TestPlaytArchive root.")
    parser.add_argument("--bessie-src", default=DEFAULT_BESSIE_SRC, help="Source folder for Bessie sample.")
    parser.add_argument("--spells-src", default=DEFAULT_SPELLS_SRC, help="Source folder for Spells album.")
    parser.add_argument("--tracks-per-album", type=int, default=3, help="Number of tracks per album.")
    args = parser.parse_args()

    ensure_dir(args.out_root)

    ok_bessie = build_bessie_album(args.bessie_src, args.out_root, args.tracks_per_album)
    ok_spells = build_spells_album(args.spells_src, args.out_root, args.tracks_per_album)

    if not ok_bessie or not ok_spells:
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
