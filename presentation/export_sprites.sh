#!/usr/bin/env bash
# Exports the first idle/walk frame of each game sprite for the deck. Usage: bash export_sprites.sh <path-to-aseprite.exe>
set -euo pipefail
ase="$1"; here="$(cd "$(dirname "$0")" && pwd)"; src="$here/../eight/assets/art/placeholder"; out="$here/images/sprites"
mkdir -p "$out"
for n in player boss_pride boss_greed boss_lust boss_envy boss_gluttony boss_wrath boss_sloth boss_satan boss_satan_head boss_satan_hand pickup_xp pickup_life pickup_item pickup_feather; do
	"$ase" -b --frame-tag idle --frame-range 0,0 "$src/placeholder_$n.aseprite" --save-as "$out/$n.png"
done
for n in husk imp brute; do
	"$ase" -b --frame-tag walk --frame-range 0,0 "$src/placeholder_enemy_$n.aseprite" --save-as "$out/enemy_$n.png"
done
