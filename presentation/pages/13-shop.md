---
section: Gameplay
---

# Feathers & Shop

<div class="fs">
<img class="ui" src="../images/ui/shop.png" alt="Dükkân: tüylerle alınan sekiz kalıcı güç" />
<ul class="fs-steps">
<li><span class="tile"><ph-feather-fill /></span><div><b>Kazan</b><p>Öldürme, sunak ve günah tüy bırakır.</p></div></li>
<li><span class="tile"><ph-vault-fill /></span><div><b>Sakla</b><p>Zaferde hepsi, yenilgide yarısı kalır.</p></div></li>
<li><span class="tile"><ph-storefront-fill /></span><div><b>Harca</b><p>Sekiz kalıcı güç, her biri beş kademe.</p></div></li>
</ul>
</div>

<!--
Tüy koşular arasında kalan tek kazanç. Bugünkü değerler (denge hâlâ ayarlanıyor): öldürme 1, muhafız 10, sunak 15, yerdeki tüy 5, günah 50, Şeytan 100.
Zaferde tüylerin hepsi, yenilgide yarısı saklanır. Zorluk kademesi kazanılan tüyü katlar.
Dükkândaki sekiz güç: Dirilik, Kudret, Zırh, Sürat, Şans, Çeviklik, Çekim, Kanatlar. Satın alınan güç sonraki her koşuya taşınır.
-->

<style>
.fs { display: grid; grid-template-columns: 420px 1fr; gap: 48px; align-items: center; }
.fs .ui { width: 420px; }
.fs-steps { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 28px; }
.fs-steps > li { list-style: none; margin: 0; display: flex; gap: 14px; align-items: flex-start; }
.fs-steps > li::marker { content: none; }
.fs-steps b { display: block; font-size: 21px; line-height: 1.2; }
.fs-steps p { font-size: 18px; color: var(--ash); line-height: 1.35; margin-top: 2px; }
</style>
