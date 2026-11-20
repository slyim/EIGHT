---
section: Realms
class: realm
---

<img class="realm-bg" src="../images/realms/gluttony.png" alt="" />
<div class="realm-card">
<div class="realm-head"><img class="realm-sprite" src="../images/sprites/boss_gluttony.png" alt="" /><div><h1>Wendigo</h1><p class="sin">Oburluk · V. kat</p></div></div>
<q>Yutulacak bir ışık daha.</q>
<ol class="rail">
<li><em>%100</em><b><span class="tile ember"><ph-fire-fill /></span>Sıçrama ve safra</b></li>
<li><em>%50</em><b><span class="tile violet"><ph-arrows-in-fill /></span>Yutma</b></li>
<li><em>%20</em><b><span class="tile"><ph-skull-fill /></span>Bölünenler</b></li>
</ol>
<ul class="answers"><li><span class="tile"><ph-wind-fill /></span>Safranın üstünden uç</li><li><span class="tile"><ph-caret-double-right-fill /></span>Atıl, çekimi yok say</li></ul>
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
Oburluk, 220 can. Meleğin durduğu yeri 120 piksellik köz bir daireyle işaretleyip oraya sıçrar ve 4 saniye kalan safra bırakır; dokuz atışlık bir kusma yelpazesi de atar. Canın yarısında yutar: 0,5 saniyelik mor uyarının ardından 260 piksellik nefesi meleği ve sürüyü ağzına çeker. Ağza ulaşan düşman yok olur ama Wendigo asla iyileşmez; ağızda kalan melek havada bile ısırılır. Atılma çekimi yok sayar. Beşte birde ölünce ikiye ayrılan bölünenler çağırır. Sürü: iriler, bölünenler.
-->
