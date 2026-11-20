---
section: Realms
class: realm
---

<img class="realm-bg" src="../images/realms/envy.png" alt="" />
<div class="realm-card">
<div class="realm-head"><img class="realm-sprite" src="../images/sprites/boss_envy.png" alt="" /><div><h1>Loki</h1><p class="sin">Kıskançlık · IV. kat</p></div><img class="glass" src="../images/glass/loki.png" alt="Loki, vitray" /></div>
<q>O ışık kimin elinde olduğunu biliyor mu?</q>
<ol class="rail">
<li><em>%100</em><b><span class="tile ember"><ph-fire-fill /></span>Ayna: mızrak ya da yay</b></li>
<li><em>%60</em><b><span class="tile"><ph-eye-fill /></span>Sahte ikiz</b></li>
</ol>
<ul class="answers"><li><span class="tile"><ph-footprints-fill /></span>Saplama hattından çekil</li><li><span class="tile"><ph-sword-fill /></span>Can barı olanı vur</li></ul>
</div>

<style>
/* Shared by the eight realm pages (19-26); keep the copies identical. */
.realm-bg { -webkit-mask-image: linear-gradient(#000 76%, #0000 90%); mask-image: linear-gradient(#000 76%, #0000 90%); }
.realm-card { width: 57%; padding: 44px 24px 62px 72px; gap: 16px; justify-content: flex-start; background: linear-gradient(90deg, #070506f7 0%, #070506ee 86%, #07050600 100%); }
.realm-head { display: grid; grid-template-columns: 128px auto auto; justify-content: start; gap: 18px; align-items: center; }
.realm-sprite { width: 128px; }
.glass { max-height: 116px; max-width: 120px; width: auto; height: auto; margin-left: 6px; image-rendering: auto !important; }
.sin { font-size: 18px; color: var(--ash); margin-top: 10px !important; }
q { font-size: 20px; line-height: 1.3; color: var(--bone-dim); }
.rail { gap: 10px; margin: 0; }
.rail li { grid-template-columns: 52px 1fr; gap: 12px; align-items: center; }
.rail em { font-size: 18px; font-weight: 400; color: var(--ash); padding: 0; }
.rail b, .answers li { display: flex; align-items: center; gap: 12px; font-size: 20px; line-height: 1.2; }
.rail b { font-weight: 600; }
.tile { width: 34px; height: 34px; font-size: 19px; }
.rail .tile svg { color: inherit; margin: 0; }
.answers { flex-direction: column; gap: 10px; margin: 0; padding-top: 16px; font-size: 20px; }
.parts { position: relative; width: 128px; height: 128px; display: block; }
.parts img { position: absolute; margin: 0; }
.parts .head { width: 96px; left: 16px; top: 0; }
.parts .hand { width: 48px; top: 80px; left: 80px; }
.parts .hand.flip { left: 0; }
</style>

<!--
Kıskançlık, 165 can. Meleğin silahını taklit eder: mızrağa karşı önünde 120 piksellik köz bir saplama hattı açar, vurduktan sonra 0,8 saniye açık kalır; yaya karşı yaklaşık 340 piksel uzakta durur ve üç hızlı yer atışı yapar. Nişanlı yelpaze de atar. Yüzde 60'ta yanında daha koyu bir sahte ikiz belirir; isim ve can barı yalnızca gerçeğinde vardır. Silah değiştirmek Loki'nin taktiğini de değiştirir. Sürü: uçanlar, bölünenler, aynalar.
-->
