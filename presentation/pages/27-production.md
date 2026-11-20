---
section: Production
---

# Production

<div class="production-pipeline">
  <div><b>Aseprite</b><span>.aseprite</span></div><i>→</i>
  <div><b>SpriteFrames</b><span>Aseprite Wizard</span></div><i>→</i>
  <div><b>Godot 4.7.2</b><span>GDScript</span></div><i>→</i>
  <div><b>Web build</b><span>Tarayıcı</span></div>
</div>

<figure class="production-example">
  <img src="../images/diagrams/player-strip.png" alt="Gerçek melek ve öküz run animasyonunun dört karesi" />
  <figcaption>Oyuncu · run · 4 kare<br>32 × 32 px</figcaption>
</figure>

<p class="production-credit">Alfa piksel spriteları: sahibin paleti ve yönlendirmesiyle<br>Aseprite batch modunda kodla üretildi. Vektör çizimler: Ahmet Altuğ Aktaş.</p>

<style>
.production-pipeline { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; margin-top: 5px; }
.production-pipeline b { display: block; font-size: 25px; white-space: nowrap; }
.production-pipeline span { display: block; color: var(--ash); font-size: 19px; margin-top: 6px; }
.production-pipeline i { color: var(--blood); font-size: 28px; font-style: normal; line-height: 1.1; }
.production-example { display: flex; align-items: center; gap: 32px; margin: 28px 0 22px; padding: 16px 0; border-top: 1px solid var(--hair); border-bottom: 1px solid var(--hair); }
.production-example img { width: 384px; height: 96px; }
.production-example figcaption { color: var(--bone-dim); font-size: 20px; max-width: 240px; }
.slidev-layout .production-credit { color: var(--ash); font-size: 18px; line-height: 1.45; }
</style>

<!-- Şerit mevcut oyuncu asset'inin dört run karesidir; yeni çizim üretilmedi. Aseprite Wizard, Aseprite dosyasını SpriteFrames kaynağına aktarır. Godot 4.7.2 Standard / GDScript kullanılır; web ihracı Compatibility ile çalışır. Piksel spriteları sahibin paleti ve yönlendirmesiyle Aseprite batch modunda kodla üretilmiştir, elle çizim değildir. Ahmet Altuğ Aktaş'ın vektör çizimleri ayrı bir sanat katmanıdır, bu hattın girdisi değildir. -->

