# EIGHT illustrated artist handoff

Open **[index.html](index.html)** in a desktop browser. Keep this whole folder together: the document uses only relative local files and needs no web server, internet access, external fonts or JavaScript libraries.

## Contents

- `index.html` — illustrated handoff with 376 pictures and links to native files.
- `originals/` — byte-identical copies of `Sprite-0001.png`, `eight_logo_pixel.png` and `icon.svg`.
- `frames/` — 234 PNG tag-frame views covering all 136 unique source frames from all 23 Aseprite sheets. Stored overlapping tag ranges are preserved and source-frame IDs are shown.
- `runtime/` — 139 actual Godot 4.7.2 screenshots: shared/tinted enemies, code-drawn weapons/VFX, damage stages, boss tells/releases, eight realms, UI and transitions.
- `sheet_manifest.json` — original source paths and SHA-256 hashes, canvases, source-frame IDs, tag ranges and durations.
- `runtime_manifest.json` — capture dimensions/methods and source-code hashes at capture time.
- `VERIFICATION.md` and `verification.json` — human-readable and machine-readable verification reports.
- `.gdignore` — keeps this documentary material out of Godot imports; these are not new game assets.

Click a picture or **Native PNG** to open the actual file. Source-sheet thumbnails are enlarged with nearest-neighbor display only; their PNG files retain the original canvas size. Original `.aseprite` files are linked to their unchanged workspace copies rather than duplicated in the package.

## Status and rights

All `placeholder_*` sheets are temporary code-generated placeholders to be replaced by human-made art. Code-drawn screenshots expose additional placeholder visuals; they are not new concept or production art. `Sprite-0001.png` remains owner-supplied with its role unresolved. The logo retains its separately documented, owner-approved adaptation exception. See `../CREDITS.md` and `../placeholder/CREDITS.md` for provenance; this package asserts no new license.

The runtime images use real game scenes, materials, tints, shaders and draw calls. Individually staged subjects are labelled **Staged live Godot render**; hub, realm, UI and transition images are full-scene captures. Random permutations and continuous shader motion are not exhaustively covered; the coverage chapter lists those limits explicitly.
