---
section: World
---

# Sekiz kat, bir melek

<div class="world">
<div class="world-art"><img class="glass angel" src="../images/glass/angel.png" alt="Mor pelerinli melek, vitray" /><img class="glass buffalo" src="../images/glass/buffalo.png" alt="Meleğin kara öküzü, vitray" /></div>
<div class="world-text">
<p class="world-mark">7 + 1</p>
<p>Yedi katta yedi günah hüküm sürer; sekizinci katta, merkezde Şeytan bekler.</p>
<p>Tanrı, mor pelerinli bir meleği kara öküzüyle aşağı gönderir.</p>
</div>
</div>

<!--
Adın kaynağı: yedi günahın katı ve merkezdeki sekizinci kat. EIGHT, bu sekiz katlık yolculuğun adı.
Melek ve öküz çizimleri ekibimizden Ahmet Altuğ Aktaş'ın; vitray görünümünü oyunun kendi gölgelendiricisi veriyor. Öküz yalnızca binek değil: atılmada hücum eder ve değdiği düşmana mızrak hasarı verir.
-->

<style>
.world { display: grid; grid-template-columns: 480px 1fr; gap: 48px; align-items: center; }
.world-art { display: flex; align-items: flex-end; justify-content: center; gap: 4px; height: 320px; }
.world-art .angel { height: 300px; }
.world-art .buffalo { height: 200px; }
.world-mark { font: 600 56px/1 "Texturina", serif; color: var(--bone); padding-bottom: 16px; margin-bottom: 22px !important;
	background: linear-gradient(90deg, var(--blood) 0 56px, var(--hair) 56px 100%) bottom / 100% 1px no-repeat; }
.world-text p:not(.world-mark) { font-size: 21px; line-height: 1.45; color: var(--bone-dim); }
.world-text p + p { margin-top: 16px; }
</style>
