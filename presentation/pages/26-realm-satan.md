---
section: Realms
class: realm
---

<img class="realm-bg" src="../images/realms/satan.png" alt="" />
<div class="realm-card">
<div class="realm-head"><span class="parts"><img class="hand flip" src="../images/sprites/boss_satan_hand.png" alt="" /><img class="head" src="../images/sprites/boss_satan_head.png" alt="" /><img class="hand" src="../images/sprites/boss_satan_hand.png" alt="" /></span><div><h1>Şeytan</h1><p class="sin">Sekizinci kat</p></div><img class="glass" src="../images/glass/satan.png" alt="Şeytan, vitray" /></div>
<q>Yedi mühür seni bana getirdi.</q>
<ol class="rail">
<li><em>Önce</em><b><span class="tile"><ph-hourglass-fill /></span>Ritüel: yalnızca sürü gelir</b></li>
<li><em>Sonra</em><b><span class="tile"><ph-skull-fill /></span>Üç parça: üçü de düşmeli</b></li>
<li><em>%33</em><b><span class="tile"><ph-star-fill /></span>Pentagram: ortası güvenli</b></li>
</ol>
<ul class="answers"><li><span class="tile"><ph-wind-fill /></span>Köz vuruşların üstünden uç</li><li><span class="tile"><ph-caret-double-right-fill /></span>Mor ateşten atıl</li></ul>
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
Sekizinci kat: sunak yok, geri sayım yok. İnişten sonra 40 saniyelik ritüel boyunca yalnızca sürü gelir ve melek güçlenir; sonra Şeytan gelir. Toplam 520 can, üç parça: kafa 280, iki el 120'şer; üçü de düşmeden Şeytan ölmez. Eller sırayla yerden saldırır: 110 piksellik yere vuruş ve süpürme; üstünden uç ya da çekil. Düşen her el kafayı bir evre ileri iter. Kafa havadan mor ateş ve yağmur gönderir; üçte iki canda yedi günahın imzalarını pentagram sırasıyla dener; üçte birde beş ışınlı pentagram iner: köz ışının üstünden uç, mordan çık ya da atıl, ortadaki beşgen güvenlidir. Final, oyunun özeti: her günahın imzası tek dövüşte.
-->
