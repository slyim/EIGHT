---
section: Art
class: art-sprites
---

# Sprites / Pixel Art

<div class="pixel-line">
  <figure><img class="source16" src="../images/sprites/pickup_feather.png" alt="Tüy" /><figcaption><b>Tüy</b><span>16 × 16</span></figcaption></figure>
  <figure><img class="source32" src="../images/sprites/player.png" alt="Melek ve kara öküz" /><figcaption><b>Melek</b><span>32 × 32</span></figcaption></figure>
  <figure><img class="source32" src="../images/sprites/enemy_husk.png" alt="Kabuk" /><figcaption><b>Kabuk</b><span>32 × 32</span></figcaption></figure>
  <figure><img class="source32" src="../images/sprites/enemy_flying_eye.png" alt="Uçan göz" /><figcaption><b>Uçan göz</b><span>32 × 32</span></figcaption></figure>
  <figure><img class="source64" src="../images/sprites/boss_lust.png" alt="Lilith" /><figcaption><b>Lilith</b><span>64 × 64</span></figcaption></figure>
  <figure><img class="source96" src="../images/sprites/boss_satan_head.png" alt="Şeytan kafası" /><figcaption><b>Şeytan kafası</b><span>96 × 96</span></figcaption></figure>
</div>

<div class="palette" aria-label="Oyun paletinden beş renk">
  <div><i style="background:#caebe0"></i><span>#CAEBE0</span></div>
  <div><i style="background:#729aa1"></i><span>#729AA1</span></div>
  <div><i style="background:#e6e29e"></i><span>#E6E29E</span></div>
  <div><i style="background:#995154"></i><span>#995154</span></div>
  <div><i style="background:#97576c"></i><span>#97576C</span></div>
</div>

<p class="sprite-credit">Alfa piksel spriteları · 2× nearest-neighbour · kodla üretildi</p>

<style>
.art-sprites .pixel-line { display: flex; align-items: flex-end; justify-content: center; gap: 20px; height: 252px; }
.art-sprites .pixel-line figure { display: flex; flex-direction: column; align-items: center; justify-content: flex-end; height: 100%; margin: 0; text-align: center; }
.art-sprites .pixel-line img { display: block; flex: none; object-fit: contain; }
.art-sprites .pixel-line .source16 { width: 32px; height: 32px; }
.art-sprites .pixel-line .source32 { width: 64px; height: 64px; }
.art-sprites .pixel-line .source64 { width: 128px; height: 128px; }
.art-sprites .pixel-line .source96 { width: 192px; height: 192px; }
.art-sprites .pixel-line figcaption { margin-top: 8px; white-space: nowrap; }
.art-sprites .pixel-line figcaption b { display: block; font-size: 20px; line-height: 24px; }
.art-sprites .pixel-line figcaption span { display: block; font-size: 18px; line-height: 22px; color: var(--ash); }
.art-sprites .palette { display: flex; justify-content: center; gap: 28px; margin-top: 5px; }
.art-sprites .palette div { text-align: center; }
.art-sprites .palette i { display: block; width: 88px; height: 22px; margin-bottom: 3px; border: 1px solid var(--hair-strong); }
.art-sprites .palette span { font-size: 18px; line-height: 22px; color: var(--bone-dim); letter-spacing: .03em; }
.art-sprites .sprite-credit { margin-top: 5px !important; text-align: center; font-size: 18px; line-height: 24px; color: var(--ash); }
</style>

<!--
Bütün örnekler aynı ölçekte: iki kat, nearest-neighbour. Etiketlerdeki sayılar ekran boyutu değil, gerçek Aseprite tuvali. Oyunda da spritelar iki kat çizilir.
Alfa piksel spriteları sahibin paleti ve yönlendirmesiyle Aseprite batch modunda kodla üretildi; elle çizilmiş değiller. Palette gösterilen beş renk de tools/placeholder_art.lua içindeki 21 renkli oyun paletinden birebir alındı.
-->
