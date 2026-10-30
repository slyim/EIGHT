# EIGHT

Game development project for YTU, built with Godot. Most programming will be AI-assisted; game direction and asset creation remain human-led.

## Open the project

1. Install **Godot 4.7.2 Standard** (not .NET) and [Git LFS](https://git-lfs.com/).
2. Clone the repository:

   ```sh
   git lfs install
   git clone https://github.com/slyim/EIGHT.git
   cd EIGHT
   git lfs pull
   ```

3. In Godot's Project Manager, import `eight/project.godot` and open it.

The existing project uses Forward Plus, Direct3D 12 on Windows, and Jolt Physics. Keep these settings unless a deliberate engine/platform change requires otherwise. The original Steam editor reports `4.7.2.stable.steam.ed1daf0bf`.

This repository currently contains the project setup only. There is no main scene or gameplay yet; open the editor rather than pressing Run Project.

## Layout

- `eight/` — Godot project; this is `res://` in the editor.
- `eight/assets/` — game assets and their source/credit information.
- `AGENTS.md` — instructions for AI coding agents.

Create scene and script folders when the first actual feature needs them, not in advance.

## Asset workflow

Add assets under `eight/assets/`; see its README for organization and attribution. Common binary art, model, audio, and video formats use Git LFS automatically. LFS has storage and bandwidth quotas: avoid committing renders, exports, or duplicate source files.

Commit Godot `.import` settings and `.uid` files alongside their source files. Do not commit `.godot/`, build exports, credentials, or local editor state. Never hand-edit LFS pointer files.

The GitHub repository is public. Upload only material you have permission to publish; do not commit purchased asset packs or private credentials.

## Checks

With the Godot executable available as `godot`, run this from the repository root:

```sh
godot --headless --path eight --editor --import --quit
```

This checks project loading and asset imports, not gameplay. Once gameplay exists, also run the changed scene in the editor and exercise its behavior before committing.
