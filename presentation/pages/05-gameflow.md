---
section: Gameplay
---

# Gameflow

<svg class="gameflow-diagram" viewBox="0 0 852 338" role="img" aria-label="Pentagram, diyar seçimi, koşu, diyarın sahibi, geçit ve mühür; yedi mühürle Şeytan. Yenilgide tüylerin yarısıyla merkeze dönüş.">
  <defs>
    <marker id="flow-progress" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M1 1L9 5L1 9" fill="none" stroke="var(--blood)" stroke-width="1.5" /></marker>
    <marker id="flow-return" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M1 1L9 5L1 9" fill="none" stroke="var(--ash)" stroke-width="1.5" /></marker>
  </defs>
  <g class="progress-lines"><path d="M115 55H149" /><path d="M270 55H301" /><path d="M414 55H444" /><path d="M603 55H640" /><path d="M723 55H738" /><path d="M790 86V230" /></g>
  <g class="flow-labels" text-anchor="middle">
    <text x="59" y="61">Pentagram</text>
    <text x="212" y="61">Diyar seç</text><text class="secondary" x="212" y="91">+ zorluk</text>
    <text x="358" y="61">Koşu</text><text class="secondary" x="358" y="91">5 sunak · 8:00</text>
    <text x="524" y="61">Diyarın sahibi</text>
    <text x="679" y="61">Mühür</text><text class="secondary" x="679" y="91">Geçitten çık</text>
    <text x="790" y="61">7 mühür?</text><text class="secondary" x="819" y="175">Evet</text><text x="790" y="260">Şeytan</text>
  </g>
  <g class="return-lines"><path d="M790 30V0H59V30" /><path d="M358 107V208H59V105" /><path d="M22 74V288H106" marker-start="url(#flow-return)" /></g>
  <g class="flow-labels secondary"><text x="441" y="22">Hayır · merkeze dön</text><text x="92" y="200">Yenilgi · tüylerin yarısı</text><text x="119" y="295">Dükkân</text><text x="510" y="303">Ritüel → kafa + iki el → zafer</text></g>
</svg>

<style>
.slidev-layout .gameflow-diagram { width: 100%; height: 338px; overflow: visible; }
.gameflow-diagram .flow-labels { fill: var(--bone); font-size: 22px; font-family: 'Source Sans 3', sans-serif; }
.gameflow-diagram .secondary { fill: var(--ash); font-size: 20px; }
.gameflow-diagram .progress-lines { fill: none; stroke: var(--blood); stroke-width: 2; marker-end: url(#flow-progress); }
.gameflow-diagram .return-lines { fill: none; stroke: var(--ash); stroke-width: 1.5; stroke-dasharray: 5 5; marker-end: url(#flow-return); }
</style>

<!-- Her normal diyar ayrı bir koşudur; sıra ve açık zorluk kademesi oyuncuya aittir. Son sunak diyarın sahibini çağırır. Onu yenmek geçidi açar; mühür geçitten çıkınca kaydedilir. Zaferde bütün tüyler, yenilgide yarısı bankalanır. Yenilgi ekranında aynı koşuyu tekrar deneme seçeneği de vardır; şema merkeze dönüş yolunu gösterir. Yedi mühürden sonra merkezden Şeytan çağrılır: finalde sunak sayacı veya çıkış geçidi yoktur; ritüelin ardından kafa ve iki elin tamamı yenilmelidir. -->

