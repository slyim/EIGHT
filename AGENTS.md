# EIGHT: AI coding instructions

## Project boundaries

- Godot 4.7.2 Standard project: `eight/project.godot`; `res://` means `eight/`.
- Use GDScript for new game code unless the owner explicitly chooses another language.
- Preserve the existing renderer, physics backend, and engine version unless a requested change requires otherwise.
- The owner directs the game. Production art, audio, VFX assets, and other creative content must be human-created; AI-assisted code is allowed. Do not invent unrequested mechanics, story, or a roadmap.
- Temporary placeholders, including audio, are allowed only when unmistakably identified as placeholders in the prototype and documented as temporary. Verify source and redistribution rights for any imported placeholder; never present it as production content.
- Implement only requested features. The owner's requested loop is a top-down survival run (hordes, life, experience, level-ups, collectible items) against seven sin bosses and a final boss, Satan. The current graybox (`scenes/run.tscn`) implements that loop with placeholder visuals, stats, and boss patterns; it does not establish final art, enemy or boss designs, balance, or a campaign.

## Implementation

- Read the affected scenes, scripts, and resources before editing. Reuse existing conventions and Godot's built-in features.
- Implement only the requested behavior. No speculative frameworks, plugin dependencies, global managers, or empty systems.
- Prefer text `.tscn` scenes and `.tres` resources so changes remain reviewable. Keep GDScript typed where the type is known; use tabs and snake_case filenames.
- Keep features small and cohesive. Add directories when they contain real content.
- Do not replace, delete, regenerate, or rename authored assets without approval. Preserve Godot resource references and commit related `.uid` and `.import` files.
- Never edit generated `.godot/` data or LFS pointer contents. Binary assets are managed through Git LFS.
- Do not add unlicensed assets, private data, API keys, or exported builds. The repository is public.

## Verification and delivery

- Run `godot --headless --path eight --editor --import --quit` from the repository root after relevant changes. If `godot` is not on PATH, use the installed executable's full path.
- For gameplay changes, run the affected scene and exercise the behavior; import success alone is not gameplay verification.
- Add focused regression tests for meaningful bugs when an existing test setup supports them. Do not introduce a test framework merely for empty-project setup.
- Update the relevant documentation when usage or workflow changes.
- Report what changed, what actually ran, and any unverified behavior. Never claim a game is playable when no main scene exists.
- Do not commit, push, change repository visibility, or rewrite Git history unless the owner requests it.
