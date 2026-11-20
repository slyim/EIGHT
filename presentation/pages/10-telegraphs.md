---
section: Gameplay
---

# Telegraphs

<div class="tg">
<figure class="tg-ember">
<div class="tg-crop"><img src="../images/telegraph_ground.jpg" alt="Kibir: yere çizilen turuncu nişanlı yelpaze" /></div>
<figcaption><b><ph-fire-fill /> Yerden gelen</b><p>Üstünden uç ya da içinden atıl.</p></figcaption>
</figure>
<figure class="tg-violet">
<div class="tg-crop"><img src="../images/telegraph_air.jpg" alt="Şeytan: meleğin çevresine düşen mor yağmur halkaları" /></div>
<figcaption><b><ph-cloud-lightning-fill /> Havadan gelen</b><p>Alandan çık ya da içinden atıl.</p></figcaption>
</figure>
</div>

<p class="tg-rule">Önce yere çizer, sonra vurur, sonra açık verir.</p>

<!--
Bütün diyarların sahipleri aynı dili konuşur. Turuncu çizilen saldırı yerden gelir: hücum hatları, halkalar, yere vuruşlar, şok dalgaları. Uçan melek bunlardan etkilenmez. Mor çizilen saldırı havadan gelir: yağmur, öpücükler, cehennem ateşi. Uçmak kurtarmaz; alandan çıkmak ya da atılmak gerekir.
Çizilen ne ise vuran odur; saldırıdan sonra günah kısa bir süre savunmasız kalır. Bir kez öğrenilen kural her yeni dövüşte işe yarar.
-->

<style>
.tg { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; }
.tg figure { margin: 0; }
.tg-crop { position: relative; height: 204px; overflow: hidden; border-radius: 6px; box-shadow: 0 0 0 1px var(--hair-strong), 0 14px 30px #0009; }
.tg-crop::after { content: ""; position: absolute; inset: 0 0 auto; height: 2px; }
.tg-ember .tg-crop::after { background: var(--ember); }
.tg-violet .tg-crop::after { background: var(--violet); }
.slidev-layout .tg-crop img { width: 100%; height: 100%; object-fit: cover; image-rendering: auto; }
.tg figcaption { margin-top: 12px; }
.tg figcaption b { display: block; font-size: 21px; }
.tg-ember b svg { color: var(--ember); }
.tg-violet b svg { color: var(--violet); }
.tg figcaption p { font-size: 18px; color: var(--ash); margin-top: 2px; }
.tg-rule { margin-top: 18px !important; padding-top: 12px; border-top: 1px solid var(--hair); font-size: 20px; color: var(--bone-dim); }
</style>
