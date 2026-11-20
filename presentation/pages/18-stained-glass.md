---
section: Art
class: art-glass
---

# Stained Glass

<div class="glass-compare">
  <figure><figcaption>Vektör çizim · Lilith</figcaption><img src="../images/sprites/lilith_vector_source.png" alt="Ahmet Altuğ Aktaş'ın Lilith vektör çizimi" /></figure>
  <div class="glass-arrow"><ph-arrow-right-fill /><span>shader</span></div>
  <figure><figcaption>Oyun içi vitray</figcaption><img src="../images/glass/lilith.png" alt="Lilith'in oyun içi vitray görünümü" /></figure>
</div>

<div class="glass-portraits" aria-label="Beş vitray portresi">
  <figure><img src="../images/glass/kerberos.png" alt="Kerberos" /><figcaption>Kerberos</figcaption></figure>
  <figure><img src="../images/glass/lilith.png" alt="Lilith" /><figcaption>Lilith</figcaption></figure>
  <figure><img src="../images/glass/loki.png" alt="Loki" /><figcaption>Loki</figcaption></figure>
  <figure><img src="../images/glass/edward.png" alt="Edward" /><figcaption>Edward</figcaption></figure>
  <figure><img src="../images/glass/satan.png" alt="Şeytan" /><figcaption>Şeytan</figcaption></figure>
</div>

<p class="glass-credit">Vektör çizimler: Ahmet Altuğ Aktaş; vitray görünümü oyun içi shader ile.</p>

<style>
.art-glass .glass-compare { display: grid; grid-template-columns: 1fr 54px 1fr; gap: 12px; align-items: center; }
.art-glass .glass-compare figure { margin: 0; text-align: center; }
.art-glass .glass-compare figcaption { margin-bottom: 4px; font-size: 20px; line-height: 26px; color: var(--bone-dim); }
.art-glass .glass-compare img { display: block; width: 100%; height: 198px; margin: 0 auto; object-fit: contain; image-rendering: auto; }
.art-glass .glass-arrow { display: grid; place-items: center; align-content: center; gap: 5px; color: var(--blood); font-size: 30px; }
.art-glass .glass-arrow span { font-size: 18px; line-height: 22px; color: var(--ash); }
.art-glass .glass-portraits { display: grid; grid-template-columns: repeat(5, 1fr); gap: 20px; margin-top: 8px; }
.art-glass .glass-portraits figure { margin: 0; text-align: center; }
.art-glass .glass-portraits img { display: block; width: 100%; height: 46px; object-fit: contain; image-rendering: auto; }
.art-glass .glass-portraits figcaption { margin-top: 3px; font-size: 18px; line-height: 22px; }
.art-glass .glass-credit { margin-top: 8px !important; text-align: center; font-size: 18px; line-height: 24px; color: var(--ash); }
</style>

<!--
Ahmet Altuğ Aktaş'ın düz renkli vektör çizimi, oyunda her rengi aydınlatmalı bir cam parçası gibi gölgelendiren shader'dan geçer. Solda kaynak Lilith çizimi, sağda aynı çizimin oyun içi sonucu var; iki görsel de yeniden renklendirilmedi.
Vektör portre ile piksel sprite aynı üretim hattı değildir. Beş portre Kerberos, Lilith, Loki, Edward ve Şeytan için hazır. Midas, Wendigo ve Odin için vektör portre yok.
-->
