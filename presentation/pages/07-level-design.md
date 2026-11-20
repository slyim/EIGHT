---
section: Gameplay
---

# Level Design

<div class="level-overview">
  <div class="level-map">
    <img src="../images/maps/wrath-overview.png" alt="Gerçek Wrath sahnesi: merkezde iniş, çevresinde beş sunak, duvarlar ve lav havuzları" />
    <svg viewBox="0 0 440 338" role="img" aria-label="Ortada iniş, çevresinde 1–5 numaralı sunaklar">
      <g class="shrine-pins"><circle cx="220" cy="59" r="10" /><circle cx="324" cy="135" r="10" /><circle cx="284" cy="258" r="10" /><circle cx="155" cy="258" r="10" /><circle cx="115" cy="135" r="10" /></g>
      <g class="map-labels" text-anchor="middle"><text x="220" y="39">1</text><text x="346" y="141">2</text><text x="306" y="265">3</text><text x="133" y="265">4</text><text x="93" y="141">5</text></g>
      <path class="landing-pin" d="M214 169H226 M220 163V175 M230 177L245 193H283" />
      <text class="map-labels" x="249" y="188">İniş</text>
    </svg>
  </div>
  <div class="level-reading">
    <b>Gazap · Wrath</b>
    <p>İniş merkezde.<br>Beş sunak çevrede.</p>
    <p class="level-key">1–5 · Sunaklar</p>
    <p>Rotayı oyuncu seçer.</p>
  </div>
</div>

<style>
.level-overview { display: grid; grid-template-columns: 440px 1fr; align-items: center; gap: 32px; }
.level-map { position: relative; width: 440px; height: 338px; }
.level-map img { position: absolute; width: 338px; height: 338px; left: 51px; top: 0; }
.slidev-layout .level-map svg { position: absolute; inset: 0; width: 440px; height: 338px; }
.level-map .shrine-pins { fill: none; stroke: var(--blood); stroke-width: 2; }
.level-map .landing-pin { fill: none; stroke: var(--bone); stroke-width: 1.5; }
.level-map .map-labels { fill: var(--bone); font: 600 20px 'Source Sans 3', sans-serif; }
.level-reading b { display: block; font-size: 28px; margin-bottom: 24px; }
.slidev-layout .level-reading p { font-size: 23px; line-height: 1.5; margin-bottom: 22px; color: var(--bone-dim); }
.slidev-layout .level-reading .level-key { color: var(--ash); font-size: 20px; }
</style>

<!-- Gerçek scenes/sins/wrath.tscn sahnesinin 4000 × 4000 birimlik ARENA_RECT sınırları gösterilir. Harita yeni çizilmedi. Beş sunak konumu sahneden doğrulandı: (0,-1300), (1236,-402), (764,1052), (-764,1052), (-1236,-402). İniş merkezde; duvarlar ve lav havuzları geçişleri etkiler. Sayılar okuma etiketidir, zorunlu sıra değildir. Çekimde HUD gizlendi, intro ve sürü üretimi kapatıldı, sahne işlemesi donduruldu. -->
