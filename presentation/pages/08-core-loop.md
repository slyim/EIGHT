---
section: Gameplay
---

# Core Loop

<svg class="core-loop-diagram" viewBox="0 0 852 338" role="img" aria-label="Savaş ve kaçın, ruh topla, Level Up, güç seç ve tekrar savaş.">
  <defs><marker id="loop-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto"><path d="M1 1L9 5L1 9" fill="none" stroke="var(--blood)" stroke-width="1.5" /></marker></defs>
  <g class="loop-lines">
    <path d="M322 48H534" />
    <path d="M720 65Q775 65 775 120V228Q775 283 720 283" />
    <path d="M534 283H322" />
    <path d="M132 283Q77 283 77 228V103Q77 48 132 48" />
  </g>
  <g class="loop-labels" text-anchor="middle">
    <text x="226" y="56">Savaş ve kaçın</text>
    <text x="630" y="56">Ruh topla</text>
    <text x="630" y="291">Level Up</text>
    <text x="226" y="291">Güç seç</text>
    <text class="loop-centre" x="426" y="175">Güçlenirken beş sunağa ulaş.</text>
  </g>
</svg>

<style>
.slidev-layout .core-loop-diagram { width: 100%; height: 338px; }
.core-loop-diagram .loop-lines { fill: none; stroke: var(--blood); stroke-width: 2; marker-end: url(#loop-arrow); }
.core-loop-diagram .loop-labels { fill: var(--bone); font: 600 27px 'Source Sans 3', sans-serif; }
.core-loop-diagram .loop-centre { fill: var(--bone-dim); font-size: 24px; font-weight: 400; }
</style>

<!-- Savaş ve kaçınma ruh toplamayı mümkün kılar. Ruhlar deneyim çubuğunu doldurur; seviye atlayınca oyun durur ve üç yükseltmeden biri seçilir. Oyuncu güçlenmiş olarak savaşa döner. Beş sunağa ulaşmak bu döngünün koşu boyunca süren mekânsal hedefidir; her turda zorunlu bir sunak yoktur. Silah evrimi ayrı bir iki seçenekli karardır. Tüy ve dükkân bu koşu içi döngünün dışında kalır. -->

