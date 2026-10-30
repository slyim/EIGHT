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

## Prototype

Press **F5 / Run Project** to open `eight/scenes/prototype.tscn`.

The current graybox tests top-down mounted movement and a **melee spear thrust**. Rider and ox move as one unit; movement and mouse aiming are independent, and a thrust keeps its aim direction until it finishes. A stationary practice target takes three test hits and can be reset. Walls and the test block stop movement and spear hits.

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move the mounted character |
| Mouse | Aim the spear |
| Hold left mouse button or Space | Repeat spear thrusts |
| R | Reset the player and practice target |
| Close the game window | Exit |

All geometry, colors, layout, and target visuals are explicitly **PLACEHOLDER**, not final game art or enemy designs. There is no audio. No enemy AI, waves, player damage, progression, or bosses are implemented.

Movement speed, spear reach, thrust duration, cooldown, and damage can be tuned on the `MountedPlayer` node in the Inspector. These are test values, not settled game balance.

### Confirmed game direction

A top-down 2D game about an unnamed angel, a hooded ox rider, who comes to destroy the seven sins and then Satan. The reference games are *Hyper Light Drifter*, *Vampire Survivors*, and *20 Minutes Till Dawn*. This prototype is a control/combat starting point, not an implementation of that campaign.

## Layout

- `eight/` — Godot project; this is `res://` in the editor.
- `eight/assets/` — game assets and their source/credit information.
- `eight/scenes/` — the graybox test space, mounted player, and practice target.
- `eight/scripts/` — movement, spear, target, and test-space behavior.
- `eight/tests/prototype_smoke.gd` — native Godot behavior checks, with no test framework.
- `AGENTS.md` — instructions for AI coding agents.

## Asset workflow

Production creative assets must be **human-created**. Clearly identified temporary placeholders, including audio, are permitted for prototyping; their temporary status, source, and redistribution rights must be documented. AI-assisted code is allowed.

Add assets under `eight/assets/`; see its README for organization, attribution, and placeholder-labeling requirements. Common binary art, model, audio, and video formats use Git LFS automatically. LFS has storage and bandwidth quotas: avoid committing renders, exports, or duplicate source files.

Commit Godot `.import` settings and `.uid` files alongside their source files. Do not commit `.godot/`, build exports, credentials, or local editor state. Never hand-edit LFS pointer files.

The GitHub repository is public. Upload only material you have permission to publish; do not commit purchased asset packs or private credentials.

## Checks

With the Godot executable available as `godot`, run this from the repository root:

```sh
godot --headless --path eight --editor --import --quit
```

This checks project loading and asset imports, not gameplay. Run the native behavior smoke check separately:

```sh
godot --headless --path eight --script res://tests/prototype_smoke.gd
```

It exercises movement, normalized diagonals, wall collision, mouse aiming, one hit per thrust, spear range, wall-blocked attacks, held attacks, target clearing, and reset. Also run the prototype with a visible window to judge control feel and readability; automated checks do not establish that the movement feels good.
