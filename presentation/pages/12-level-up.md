---
section: Gameplay
---

# Level Up

<div class="lu">
<img class="ui" src="../images/ui/levelup.png" alt="Seviye atladın: üç karttan birini seç" />
<div>
<p class="lu-lead">Ruhlar dolunca oyun durur; üç karttan biri seçilir.</p>
<p class="lu-label"><ph-git-fork-fill /> Evrim</p>
<div class="lu-fork">
<div class="lu-root"><span class="tile"><ph-sword-fill /></span><b>Işık mızrağı</b></div>
<div class="lu-paths"><span>Kasırga</span><span>Zincir Işık</span></div>
</div>
<p class="lu-note">Muhafızın düşürdüğü eşya silahı iki yoldan birine evriltir.</p>
</div>
</div>

<!--
Seviye kartları hasar, hız, zırh ve menzil gibi küçük artışlar verir; her seviyede üç seçenekten biri alınır.
Evrim ayrı bir karar: sunak muhafızları evrim eşyası düşürür, her silah koşuda bir kez ve iki yoldan biriyle evrilir. Mızrak: Kasırga ya da Zincir Işık. Yay: Sekme ya da Işık Yağmuru.
Yan silahlar sandıklardan ve muhafızlardan gelir, kendiliğinden çalışır; aynısı gelirse III'e kadar güçlenir: Yörünge Haleleri, Güdümlü Tüyler, Kutsal Nabız, Yargı Şimşeği.
-->

<style>
.lu { display: grid; grid-template-columns: 470px 1fr; gap: 44px; align-items: center; }
.lu .ui { width: 470px; }
.lu-lead { font-size: 21px; line-height: 1.4; color: var(--bone-dim); margin-bottom: 28px !important; }
.lu-label { font-size: 18px; color: var(--ash); margin-bottom: 12px !important; }
.lu-fork { display: flex; align-items: center; }
.lu-root { display: flex; align-items: center; gap: 12px; }
.lu-root b { font-size: 21px; white-space: nowrap; }
.lu-paths { position: relative; margin-left: 40px; padding-left: 28px; display: flex; flex-direction: column; gap: 18px; border-left: 1px solid var(--blood); }
.lu-paths::before { content: ""; position: absolute; left: -28px; top: 50%; width: 28px; height: 1px; background: var(--blood); }
.lu-paths span { position: relative; font-size: 20px; font-weight: 600; color: var(--bone); white-space: nowrap; }
.lu-paths span::before { content: ""; position: absolute; left: -28px; top: 50%; width: 18px; height: 1px; background: var(--blood); }
.lu-note { font-size: 18px; line-height: 1.4; color: var(--ash); margin-top: 26px !important; }
</style>
