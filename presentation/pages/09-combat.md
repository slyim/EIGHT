---
section: Gameplay
---

# Combat

<div class="cb">
<div class="cb-crop"><img src="../images/realms/greed.png" alt="Açgözlülük diyarı: melek ışık mızrağıyla Midas'a ve sürüye vuruyor" /></div>
<ul class="cb-moves">
<li><span class="tile"><ph-sword-fill /></span><div><b>Işık mızrağı</b><p>Üç vuruşluk kombo; nişanı oyuncu alır.</p></div></li>
<li><span class="tile"><ph-crosshair-fill /></span><div><b>Yay</b><p>Üç atış; son ok düşmanı deler.</p></div></li>
<li><span class="tile"><ph-caret-double-right-fill /></span><div><b>Atılma</b><p>Dokunulmaz geçiş; tam zamanında olursa darbe ıskalar.</p></div></li>
</ul>
</div>

<!--
Saldırılar otomatik değil: mızrak ve yay fareyle nişan alır, oyuncu basınca vurur.
Mızrağın üçüncü vuruşu geniş bir yay çizip sürüyü yarar. Yayın son oku 1,5 kat vurur ve bir düşmanı deler.
Atılma kısa bir dokunulmazlık verir ve içinden geçilen her düşmana mızrak darbesi vurur. Darbe atılmanın ilk anına denk gelirse kusursuz kaçış olur: atılma hemen yenilenir, saldırılar iki saniye hızlanır.
Uçuş yerdeki saldırıların üstünden geçirir; dayanıklılık bitince melek iner.
Kontroller: WASD hareket, fare nişan, sol tık saldırı, Q silah değiştir, Space uçuş, Shift atılma. F1 kontrolleri gösterir; tuşlar Ayarlar'dan değiştirilebilir.
-->

<style>
.cb { display: grid; grid-template-columns: 500px 1fr; gap: 38px; align-items: center; }
.cb-crop { position: relative; width: 500px; height: 330px; overflow: hidden; border-radius: 6px; box-shadow: 0 0 0 1px var(--hair-strong), 0 18px 40px #000a; }
.cb-crop img { position: absolute; max-width: none; width: 1000px; left: -480px; top: -120px; }
.cb-moves { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 26px; }
.cb-moves > li { list-style: none; margin: 0; display: flex; gap: 14px; align-items: flex-start; }
.cb-moves > li::marker { content: none; }
.cb-moves b { display: block; font-size: 21px; line-height: 1.2; }
.cb-moves p { font-size: 18px; color: var(--ash); line-height: 1.35; margin-top: 2px; }
</style>
