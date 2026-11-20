# EIGHT — Jury Presentation & A2 Pafta

| Deliverable | Description |
| --- | --- |
| **[EIGHT-jury.pdf](EIGHT-jury.pdf)** | 30-slide jury presentation (16:9, Turkish, dark gothic palette) |
| **[Pafta.pdf](pafta/Pafta.pdf)** | Single-page A2 poster (420 × 594 mm, print-ready) |
| **[Play EIGHT](https://slyim.github.io/EIGHT/)** | Playable Alpha 0.1 web build (desktop browser, keyboard & mouse) |

[![EIGHT A2 Pafta](pafta/preview.png)](pafta/Pafta.pdf)

## Deck structure (30 slides)

Split into one source file per slide under `pages/` (`01-cover.md` – `30-play.md`), assembled by [slides.md](slides.md) with Turkish speaker notes:

1. **World** — Cover, References (*Hyper Light Drifter*, *Vampire Survivors*, *20 Minutes Till Dawn*), World (`7 + 1`)
2. **Gameplay** — Gameplay, Gameflow, Run, Level Design (Wrath map), Core Loop, Combat, Telegraphs (ground vs. air), Shrines & Pacts, Level Up, Feathers & Shop, Difficulty
3. **Art** — Horde, Sprites / Pixel Art, Animation, Stained Glass
4. **Realms** — Kerberos, Midas, Lilith, Loki, Wendigo, Odin, Edward, Satan
5. **Production** — Production pipeline, Team, Roadmap, Play link

Design documents: [Oyun Dinamikleri ve Sistem Tasarımı](docs/oyun-dinamikleri.pdf) · [Oyun Genel Akışı ve Oyun İçi Akış](docs/oyun-akisi.pdf). Tarot / Smart AI and parkour appear on the **Roadmap** slide as planned designs; Q W E R active skills were removed from the design.

## Build locally

```sh
cd presentation
npm ci

# Present with speaker notes (press P for presenter view)
npm run dev

# Export the 30-slide PDF
npx slidev export slides.md --output EIGHT-jury.pdf

# Rebuild the A2 poster (requires Python + PyMuPDF for exact A2 MediaBox)
node pafta/build.cjs
```

## Sources & credits

- **Team:** Mustafa Yıldız (`2308A008`), Lila Aydın (`2308A025`), Ahmet Altuğ Aktaş (`2308A061`) — Yıldız Teknik Üniversitesi, Oyun Tasarımı.
- **Typography:** Texturina (headings) and Source Sans 3 (body), both SIL OFL 1.1 (licenses in `fonts/`).
- **Icons:** [Phosphor Icons](https://phosphoricons.com) fill weight (MIT), matching the game's icon set.
- **Vector art & stained glass (`images/glass/`, `images/sprites/lilith_vector_source.png`):** Hand-drawn vector illustrations by Ahmet Altuğ Aktaş (Angel, Buffalo, Kerberos, Lilith, Loki, Edward, Satan), passed through the game's stained-glass shader (`eight/shaders/stained_glass.gdshader`) via `godot --path eight --script res://tools/render_glass.gd -- <in_dir> presentation/images/glass`.
- **Pixel sprites & strips (`images/sprites/`, `images/strips/`, `images/diagrams/`, `pafta/img/`):** Exported from the code-generated alpha 0.1 `.aseprite` placeholders (`tools/placeholder_art.lua`); see [eight/assets/art/placeholder/CREDITS.md](../eight/assets/art/placeholder/CREDITS.md) and [pafta/img/CREDITS.md](pafta/img/CREDITS.md). Refresh single frames with `bash export_sprites.sh <aseprite.exe>`.
- **Screenshots & UI captures (`images/ui/`, `images/realms/`, `images/maps/`, `images/gameplay.jpg`, `images/telegraph_*.jpg`):** Captured directly from the Godot 4.7.2 game build.
