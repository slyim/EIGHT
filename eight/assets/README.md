# Assets

## Human-created production assets

All production art, animation, textures, VFX assets, music, sound effects, voices, and other creative assets must be human-created. AI-assisted game code is allowed; this does not permit AI-generated production assets.

## Temporary placeholders

Temporary placeholders, including audio, are allowed for prototyping only when their temporary status is unmistakable:

- For imported placeholder files, use `placeholder_` filenames or explicit placeholder node names and mark them `PLACEHOLDER` in the nearby credit record. Mark code-drawn debug geometry in its scripts.
- Show an explicit in-game notice while placeholder visuals or audio are in use; placeholder audio must be called out as `PLACEHOLDER AUDIO`, not merely recognizable by its sound.
- Record their source, creator/tool where applicable, license, and what needs replacing. Do not use a sound of unknown provenance or assume familiar audio is free to redistribute.
- Never promote a placeholder to production without checking that it meets the human-created asset policy.

The current prototype uses code-drawn debug geometry, marked in its scripts and on-screen. It contains no audio or newly imported art. The existing Godot project icon is editor/template material, not final game art.

## Files and credits

Place game assets here. Create subfolders such as `art/`, `models/`, or `audio/` only when there are actual files to put in them. Use descriptive snake_case filenames.

Keep editable source files alongside their exported game assets where practical. Do not store duplicate exports, preview videos, or intermediate renders in the repository.

For each asset or coherent asset pack, record the following in a nearby `CREDITS.md` when adding it:

- Filename or folder covered.
- Creator and source URL, or that it was created for EIGHT.
- License and required attribution; retain any supplied license file.
- Whether the asset is production content or a temporary `PLACEHOLDER`; for a placeholder, record its provenance and intended replacement.

Only publish assets whose rights permit redistribution in this public repository. A purchase or permission to use an asset in a game does not necessarily permit publishing its source files.

Common binary formats are tracked with Git LFS. Let Godot generate import metadata, commit the adjacent `.import` files, and leave `.godot/` untracked.
