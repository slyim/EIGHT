---
section: Art
class: art-animation
---

# Animation

<p class="animation-lead">Melek · Koşu · 4 kare · 100 ms/kare · 4×</p>

<div class="run-strip" aria-label="Meleğin dört karelik koşu animasyonu">
  <figure><img src="../images/strips/player_run_01_4x.png" alt="Koşu, birinci kare" /><figcaption>01</figcaption></figure>
  <ph-arrow-right-fill class="run-arrow" />
  <figure><img src="../images/strips/player_run_02_4x.png" alt="Koşu, ikinci kare" /><figcaption>02</figcaption></figure>
  <ph-arrow-right-fill class="run-arrow" />
  <figure><img src="../images/strips/player_run_03_4x.png" alt="Koşu, üçüncü kare" /><figcaption>03</figcaption></figure>
  <ph-arrow-right-fill class="run-arrow" />
  <figure><img src="../images/strips/player_run_04_4x.png" alt="Koşu, dördüncü kare" /><figcaption>04</figcaption></figure>
</div>

<p class="animation-note">Dört kare, tek koşu döngüsü.</p>

<style>
.art-animation .animation-lead { font-size: 22px; line-height: 30px; text-align: center; color: var(--bone-dim); }
.art-animation .run-strip { display: grid; grid-template-columns: 128px 36px 128px 36px 128px 36px 128px; align-items: start; justify-content: center; column-gap: 12px; margin-top: 22px; }
.art-animation .run-strip figure { margin: 0; text-align: center; }
.art-animation .run-strip img { display: block; width: 128px; height: 128px; }
.art-animation .run-strip figcaption { margin-top: 10px; font-size: 20px; line-height: 26px; color: var(--bone-dim); font-variant-numeric: tabular-nums; }
.art-animation .run-arrow { align-self: start; margin-top: 49px; font-size: 30px; color: var(--blood); }
.art-animation .animation-note { margin-top: 24px !important; text-align: center; font-size: 21px; line-height: 28px; color: var(--ash); }
</style>

<!--
Meleğin koşusu dört kareden oluşur; her kare 100 milisaniye sürer. İzleyici canlı sunumda kareleri sırayla takip eder; kare numaraları ve oklar PDF'de de hareket yönünü korur.
Kareler mevcut Aseprite dosyasından dört kat nearest-neighbour ile alındı. Kaynakta saklanan etiket aralıkları çakıştığı için şeritte üreticideki amaçlanan run bloğu, yani 4–7 numaralı kareler kullanıldı; yeni animasyon üretilmedi.
-->
