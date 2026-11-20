---
section: Gameplay
---

# Gameplay

<div class="gp">
<img class="gp-shot" src="../images/gameplay.jpg" alt="Gazap diyarı, oyundan bir kare: melek mızrakla sürüye dalıyor, yerde turuncu hücum hattı, solda bir sunak" />
<ol class="gp-steps">
<li><span class="tile"><ph-sword-fill /></span><div><b>Savaş</b><p>Mızrak ve yayla vur.</p></div></li>
<li><span class="tile"><ph-diamond-fill /></span><div><b>Ruh topla</b><p>Ruhlar seviye getirir.</p></div></li>
<li><span class="tile"><ph-bank-fill /></span><div><b>Sunağa ulaş</b><p>Beş sunağı yık.</p></div></li>
</ol>
</div>

<!--
Oyuncu ilk dakikada üç şey yapar: savaşır, ruh toplar ve sunaklara yürür. Görüntü Gazap diyarından: melek Kerberos'la dövüşüyor, yerdeki turuncu çerçeve Kerberos'un hücum hattı. Altın elmaslar beş sunağın yeri.
-->

<style>
.gp { display: grid; grid-template-columns: 560px 1fr; gap: 36px; align-items: center; }
.slidev-layout .gp-shot { image-rendering: auto; }
.gp-shot { width: 560px; height: 315px; object-fit: cover; border-radius: 6px; box-shadow: 0 0 0 1px var(--hair-strong), 0 18px 40px #000a; }
.gp-steps { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 26px; }
.gp-steps > li { list-style: none; margin: 0; display: flex; gap: 14px; align-items: flex-start; }
.gp-steps > li::marker { content: none; }
.gp-steps b { display: block; font-size: 21px; line-height: 1.2; }
.gp-steps p { font-size: 18px; color: var(--ash); line-height: 1.35; margin-top: 2px; }
</style>
