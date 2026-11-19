# EIGHT artist handoff verification

Verified 19 November 2026 against the shared workspace captured in `runtime_manifest.json`.

## Result

**PASS.** The offline handoff contains **376 pictures**, all original PNG/SVG copies are byte-identical, every required image/link is present, and there are no web dependencies. The machine-readable result is in [`verification.json`](verification.json).

| Check | Verified result |
| --- | --- |
| Existing art sheets | **23 / 23** `placeholder_*.aseprite` files, exact on-disk set |
| Unique source frames | **136 / 136**, counted independently from the Aseprite headers |
| Stored tag coverage | **234 / 234** PNG tag-frame views; every range is complete and sequential |
| Overlapping tags | Preserved as saved; overlapping views of one source frame have identical decoded pixels |
| Native source dimensions | Every exported frame matches its sheet canvas; no production resampling |
| Original PNGs | **2 / 2**, SHA-256 identical to workspace originals |
| Original project SVG | **1 / 1**, SHA-256 identical to `eight/icon.svg` |
| Actual runtime stills | **139 / 139** PNGs — **115** staged live renders + **24** full-scene captures |
| Required enemy variants | All 12 horde types plus ground/flying elite treatments and state overlays |
| Required pickups | XP, life, item, spear/bow evolution, side-weapon relic and feather currency |
| Required boss visuals | Every rendered `Boss.Pattern` tell, both Mirror outcomes and all seven release formations |
| Breakables | All kinds, wall orientations, three damage stages per kind and debris per kind |
| Realms and endings | All eight realms plus ascent, victory and defeat |
| Offline HTML | **376 / 376** images loaded; no broken images, missing local links or duplicate IDs |
| External dependencies | **0** HTTP(S) resources or external font/script requirements |
| Browser runtime errors | **0** page errors |
| Deep links | Verified on `placeholder_player`, shared/tinted horde, and realm sections |
| Machine assertions | **2,447 / 2,447 passed** |
| Godot editor import | Exit code **0** |
| Documentary `.import` sidecars | **0** after a clean editor import |
| Source-code drift at final audit | **None** — current script/scene/shader MD5 values match the capture manifest |

The complete handoff folder is **383 files**, approximately **7.2 MB** before this report text; PNG data accounts for approximately **6.47 MB**. Common PNG formats remain covered by the repository’s existing Git LFS rules.

## Original-image hashes

These are the hashes of both the original workspace files and the copies supplied in `originals/`:

| File | SHA-256 |
| --- | --- |
| `Sprite-0001.png` | `d655b8edba97ddb8a3496bcb52b41cb354b32ea06675bd51593388d5f09ea771` |
| `eight_logo_pixel.png` | `67c42ac884789b9b3d721c47ccac35325b31ee65512fe3d9e005d72ec63f6bbe` |
| `icon.svg` | `6c80384360a5b269d1054bfb27241258154e2cc8167c522016fdc1820e84e0f8` |

## What actually ran

1. **Original source-frame export.** A read-only Aseprite parser decoded the original RGBA cells, durations and tag ranges. Assertions rejected malformed frames, unsupported formats, uncovered source frames and inconsistent tag data. Overlapping ranges were deliberately retained rather than “fixed.” No `.aseprite` file was rewritten.
2. **Live Godot capture.** Godot `4.7.2.stable.official.ed1daf0bf`, Forward+ / D3D12, with the real project scenes and materials. The final capture command completed successfully and printed `RUNTIME CAPTURE COMPLETE: 139`:

   ```powershell
   Godot_v4.7.2-stable_win64_console.exe --path eight --audio-driver Dummy --script '<capture-workspace>/capture_runtime.gd'
   ```

   Individually staged images instantiate the real game nodes in project scenes. Full-scene images capture the hub, instructions, shop, settings, eight realms, HUD panels, live feedback, descent/ascent, endings and spear test space. Save/settings paths were isolated to temporary capture-only files and removed afterward; the player’s save was not used as the refreshed source.

3. **Offline browser inspection.** The installed Chrome was driven through the project’s existing Playwright Chromium installation. It reported:

   ```text
   imageResult: { count: 376, broken: [] }
   errors: []
   external: []
   ```

   It also rendered screenshots after scrolling to the player sheet, horde gallery and realm sections. Those diagnostic screenshots were inspected; they remain temporary and are not additional game assets.

4. **Integrity checker.** The checker opened every PNG, compared every decoded tag-view duplicate, checked source hashes and canvas sizes, enumerated all required captures, and resolved every local image/link/anchor in `index.html`.

5. **Godot import.** The required repository-root command passed:

   ```powershell
   Godot_v4.7.2-stable_win64_console.exe --headless --path eight --editor --import --quit
   ```

   Stale documentary sidecars from the initial export were removed. A clean import then left **0** `.import` files under `handoff/`; `.gdignore` is working as intended.

## Scope, exclusions and remaining uncertainty

- **No new production art was created.** Gallery styling, captions, native source exports and runtime screenshots are documentary work only.
- **No game script or scene was edited for this handoff.** Task-owned text changes are `eight/assets/art/DRAW_LIST.md`, the documentary exception in `eight/assets/README.md`, and this `handoff/` folder. Other shared-workspace script/scene edits were left intact.
- **Not every procedural permutation is pictured.** Random arena layouts, decoration scatter, obstacle crack paths, debris trajectories and shader phases have representative captures, not exhaustive state-by-state coverage.
- **Stills do not verify motion or feel.** Animation timing, pulsing eyes, lava shimmer, glow evolution, transitions and play-scale readability still require a human check in Godot.
- **The Mirror selector has no distinct draw call.** Its actual spear-thrust and bow-shot results are pictured; no imaginary third asset was invented for the selector.
- **Runtime cache atlases are excluded as duplicates.** The sheet gallery covers original source data rather than importer-generated timing/cache textures.
- **Audio is outside this visual handoff.** Fonts are retained licensed UI resources and appear in the UI screenshots; they are not marked for world-art replacement.
- **No full gameplay smoke-test suite was run**, because this task does not alter game behavior. Runtime rendering, browser behavior, imports and document integrity were tested directly; current game balance/functionality is not certified by this report.

To repeat the broad checks after changing artwork, recapture the runtime images, rebuild the gallery inventory, then run equivalent source/hash/browser assertions. Do not present later replacements as verified by this old report without refreshing it.
