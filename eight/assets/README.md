# Assets

Place game assets here. Create subfolders such as `art/`, `models/`, or `audio/` only when there are actual files to put in them. Use descriptive snake_case filenames.

Keep editable source files alongside their exported game assets where practical. Do not store duplicate exports, preview videos, or intermediate renders in the repository.

For each asset or coherent asset pack, record the following in a nearby `CREDITS.md` when adding it:

- Filename or folder covered.
- Creator and source URL, or that it was created for EIGHT.
- License and required attribution; retain any supplied license file.
- For AI-generated material, the tool/model and relevant usage-rights information.

Only publish assets whose rights permit redistribution in this public repository. A purchase or permission to use an asset in a game does not necessarily permit publishing its source files.

Common binary formats are tracked with Git LFS. Let Godot generate import metadata, commit the adjacent `.import` files, and leave `.godot/` untracked.
