---
section: Gameplay
---

# Run

<img class="ui run-hud" src="../images/ui/objective.png" alt="Oyun içi hedef: Şeytan'ın sunaklarını yok et, 5 kaldı, 7:57" />

<div class="run-beats">
<div><p class="run-big">8 dakika</p><p>Süre dolarsa melek düşer.</p></div>
<div><p class="run-big">5 sunak</p><p>Sonuncusu günahı çağırır.</p></div>
<div><p class="run-big">Geçit</p><p>Günah düşünce açılır; çıkınca mühür kaydedilir.</p></div>
</div>

<!--
Normal bir diyarın kuralı bu: inişten sonra sekiz dakika içinde beş sunak yıkılmalı. Son sunak düşünce süre durur, diyarın sahibi gelir; sürü ise güçlenmeye devam eder.
Günah yenilince yanında bir geçit açılır. Melek geçitten çıktığında zafer, mühür ve tüyler kaydedilir ve merkeze dönülür. Bir koşu yaklaşık on - on beş dakika.
Şeytan'ın diyarında sunak ve geri sayım yok; orada bu kural değişir.
-->

<style>
.run-hud { width: 470px !important; margin: 34px auto 0; }
.run-beats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 40px; margin-top: 60px; }
.run-beats > div { position: relative; padding-top: 22px; border-top: 1px solid var(--hair-strong); }
.run-beats > div::before { content: ""; position: absolute; left: 0; top: -1px; width: 40px; height: 1px; background: var(--blood); }
.run-big { font: 600 36px/1.1 "Texturina", serif; color: var(--bone); margin-bottom: 10px !important; }
.run-beats p:not(.run-big) { font-size: 19px; line-height: 1.4; color: var(--ash); }
</style>
