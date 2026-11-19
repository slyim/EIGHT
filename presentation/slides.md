---
theme: default
title: EIGHT
htmlAttrs:
  lang: tr
colorSchema: dark
fonts:
  provider: none
layout: center
class: cover
---

<img class="logo" src="./images/eight_logo_pixel.png" alt="EIGHT" />

<img class="hero" src="./images/sprites/player.png" alt="Kara öküzüne binmiş, mor pelerinli melek" />

<p class="tagline">Bir melek. Yedi günah. Tek bir yol.</p>

<div class="caption">Yıldız Teknik Üniversitesi · Oyun Tasarımı · Alfa 0.1</div>

<!-- EIGHT tepeden görünümlü bir hayatta kalma oyunu. Tanrı’nın gönderdiği melek, kara öküzünün sırtında cehennemin yedi katını arındırmaya iner. -->

---
class: cast-slide
---

# Yedi kat, yedi günah

<div class="cast">
  <figure style="--h:#e7a6b5"><img src="./images/sprites/boss_pride.png" alt="" /><b>Odin</b><span>Kibir</span></figure>
  <figure style="--h:#f0d483"><img src="./images/sprites/boss_greed.png" alt="" /><b>Midas</b><span>Açgözlülük</span></figure>
  <figure style="--h:#eea4cd"><img src="./images/sprites/boss_lust.png" alt="" /><b>Lilith</b><span>Şehvet</span></figure>
  <figure style="--h:#9cd6ac"><img src="./images/sprites/boss_envy.png" alt="" /><b>Loki</b><span>Kıskançlık</span></figure>
  <figure style="--h:#efae72"><img src="./images/sprites/boss_gluttony.png" alt="" /><b>Wendigo</b><span>Oburluk</span></figure>
  <figure style="--h:#ee8672"><img src="./images/sprites/boss_wrath.png" alt="" /><b>Kerberos</b><span>Gazap</span></figure>
  <figure style="--h:#99bde7"><img src="./images/sprites/boss_sloth.png" alt="" /><b>Edward</b><span>Tembellik</span></figure>
</div>

<p class="satan"><img src="./images/sprites/boss_satan.png" alt="" /> Yedisi düşünce merkezde <b>Şeytan</b> bekler.</p>

<!-- Her günahın kendi diyarı, kendi sürüsü ve kendi saldırı dili var. Her diyara girerken o diyarın sahibi meleğe seslenir. -->

---

# Yolu sen seçersin

<div class="spread"><div><p>Ana menü bir haritadır: yedi günah pentagramın çevresinde, Şeytan merkezde.</p><p>İlk günahı oyuncu seçer. Kazanılan her diyar bir mührü kapatır ve o diyarın bir üst zorluğunu açar.</p><p>Yedi mühür tamamlanınca merkezin yolu açılır.</p></div><img src="./images/hub.png" alt="Yedi diyarın pentagram etrafında dizildiği ana menü" /></div>

<!-- İlerleme kaydedilir. Her düğüm kendi zorluk kademesini gösterir; kazanılan en yüksek kademe "EN İYİ" olarak yazılır. -->

---

# Bir koşunun döngüsü

<div class="loop">
  <div><img src="./images/sprites/player.png" alt="" /><b>İniş</b><p>Melek ışıkla diyara iner.</p></div>
  <i>→</i>
  <div><img src="./images/sprites/enemy_imp.png" alt="" /><b>Sürüyü biç</b><p>Düşen ruhlar deneyim olur.</p></div>
  <i>→</i>
  <div><img src="./images/sprites/pickup_item.png" alt="" /><b>Beş sunak</b><p>Sekiz dakikada hepsini yık.</p></div>
  <i>→</i>
  <div><img src="./images/sprites/boss_pride.png" alt="" /><b>Günahı yen</b><p>Son sunakla günah gelir.</p></div>
  <i>→</i>
  <div><img src="./images/sprites/pickup_feather.png" alt="" /><b>Geçit</b><p>Tüylerle merkeze dön.</p></div>
</div>

<p class="note-line">Her sunağı, o diyarın günahının zayıf bir kopyası korur. Sunaklar ayaktayken sayaç işler; süre biterse melek düşer.</p>

<!-- Koşu 10-15 dakika sürer. Günah düştükten sonra geçit açılır; melek istediği an çıkabilir, sürü ise güçlenmeye devam eder. -->

---

# Meleğin elleri

<div class="kit">
  <div><img src="./images/icons/strike.svg" alt="" /><b>Işık mızrağı</b><p>Üç vuruşluk kombo. Üçüncü vuruş geniş bir yay çizer ve sürüyü yarar.</p></div>
  <div><img src="./images/icons/strike.svg" alt="" class="flip" /><b>Yay</b><p>Üç atışlık kombo. Son ok 1,5 kat vurur ve bir düşmanı deler.</p></div>
  <div><img src="./images/icons/dash.svg" alt="" /><b>Atılma</b><p>Kısa dokunulmazlık. İçinden geçtiğin her düşmana bir mızrak darbesi vurur ve onu iter.</p></div>
  <div><img src="./images/icons/fly.svg" alt="" /><b>Uçuş</b><p>Space basılıyken yükselir. Yerdeki saldırıların üstünden geçer, dayanıklılık harcar.</p></div>
</div>

<p class="note-line"><b>Kusursuz kaçış:</b> bir darbe atılmanın ilk anına denk gelirse ıskalar, atılma hemen yenilenir ve saldırılar iki saniye hızlanır.</p>

<!-- Kontroller: WASD hareket, fare nişan, sol tık saldırı, Q silah değiştir, Space uç, Shift atıl. F1 kontrolleri gösterir; saldırı ve atılma tuşları Ayarlar'dan değiştirilebilir. -->

---

# Uyarıların dili

<div class="tells">
  <div class="tell ground"><img src="./images/icons/ground.svg" alt="" /><b>Köz rengi: yerden</b><p>Hücum hatları, halkalar, yere vuruşlar. <strong>Üstünden uç</strong> ya da <strong>içinden atıl</strong>.</p></div>
  <div class="tell air"><img src="./images/icons/air.svg" alt="" /><b>Mor: havadan</b><p>Yağmur, öpücükler, cehennem ateşi. Uçmak kurtarmaz: <strong>alandan çık</strong> ya da <strong>atıl</strong>.</p></div>
</div>

<p class="note-line">Her saldırı önce çizilir, sonra vurur, sonra bir açık bırakır. Çizilen ne ise vuran odur.</p>

<!-- Bu kural sekiz patronun hepsinde aynı. Oyuncu bir kez öğrendikten sonra her yeni patronu okuyabilir. -->

---

# Işıkta kalmak mı, ilerlemek mi?

<div class="spread"><div><p>Yıkılan sunağın çevresine gökten ışık iner.</p><p class="big">10 saniye</p><p>Halkanın içinde dayanırsan canının dörtte biri geri gelir. Dışarı çıkarsan sayaç başa döner. Her sunak bir kez şifa verir.</p></div><img src="./images/heal.png" alt="Melek, yıkılmış bir sunağın şifa halkasında; altta ŞİFA 7 sn yazıyor" /></div>

<!-- Şifa bedava değil: oyuncu dar bir alanda saldırılara dayanmak zorunda, içerideyken diğer sunakların süresi işliyor. -->

---

# Güçlenmek

<div class="spread img-left"><img src="./images/levelup.png" alt="Seviye atlama kartları" /><div class="grow">
<p><b>Seviye</b> · Her seviyede oyun durur, üç karttan biri seçilir: hasar, hız, zırh, menzil…</p>
<p><b>Evrim</b> · Muhafızlar evrim eşyası düşürür. Her silah bir kez evrilir:<br><span class="pill">Kasırga</span><span class="pill">Zincir Işık</span><span class="pill">Sekme</span><span class="pill">Işık Yağmuru</span></p>
<p><b>Yan silahlar</b> · Sandıklardan ve muhafızlardan; aynısı gelirse III'e kadar güçlenir:<br><span class="pill">Yörünge Haleleri</span><span class="pill">Güdümlü Tüyler</span><span class="pill">Kutsal Nabız</span><span class="pill">Yargı Şimşeği</span></p>
</div></div>

<!-- Seviye kartları bu koşuyu değiştirir; evrim yolları silahın bitiricisini değiştirir. -->

---

# Sunak antlaşmaları

<div class="spread even"><div><p>Bir sunak yıkılınca iki antlaşma sunulur. Biri alınır ya da hiçbirine el sürülmez. Koşu başına en fazla üç.</p>
<ul class="pacts">
<li><b>Cam Işık</b><span>+%25 hasar, −%25 azami can</span></li>
<li><b>Altın Öşür</b><span>+%50 tüy, kalpler yarı sıklıkta</span></li>
<li><b>Çevik Kan</b><span>Saldırı ve atılma %15 hızlı, düşmanlar %20 sert</span></li>
</ul></div><img src="./images/pact.png" alt="Sunak antlaşması seçimi" /></div>

<!-- Her antlaşma bir güç verir, bir bedel ister. Risk oyuncunun elinde. -->

---

# Tüy ve dükkân

<div class="spread img-left"><img src="./images/shop.png" alt="Dükkân ekranı" /><div>
<div class="earn"><img src="./images/sprites/pickup_feather.png" alt="" /><p>Öldürme <b>1</b> · Muhafız <b>10</b> · Sunak <b>15</b> · Günah <b>50</b> · Şeytan <b>100</b></p></div>
<p>Zaferde tüylerin hepsi, yenilgide yarısı saklanır.</p>
<p>Merkezdeki dükkânda sekiz kalıcı güç, her biri beş kademe: <span class="pill">Dirilik</span><span class="pill">Kudret</span><span class="pill">Zırh</span><span class="pill">Sürat</span><span class="pill">Şans</span><span class="pill">Çeviklik</span><span class="pill">Çekim</span><span class="pill">Kanatlar</span></p>
</div></div>

<!-- Satın alınan güç sonraki her koşuya taşınır. Zorluk kademesi kazanılan tüyü katlar. -->

---

# Zorluk ve her koşunun farkı

<div class="tiers">
  <div><b>Kefaret</b><span>×1 tüy</span></div><i>→</i>
  <div><b>Araf</b><span>×1,5 tüy</span></div><i>→</i>
  <div><b>Lanet</b><span>×2 tüy</span></div><i>→</i>
  <div><b>Uçurum</b><span>×3 tüy</span></div>
</div>
<p class="note-line">Bir günahı bir kademede yenmek o günahın bir sonraki kademesini açar. Kademe yükseldikçe sürü kalabalıklaşır, patronlar yeni hamleler öğrenir. Süre hiç kısalmaz.</p>

<div class="variety">
  <div><b>Seçkinler</b><p>Nadir, güçlü düşmanlar. Ayaklarında halka, kesin tüy ödülü.</p></div>
  <div><b>Sürü Dalgası</b><p>Arada bir yirmi saniyelik akın; ekranda duyurulur.</p></div>
  <div><b>Kavrulmuş Toprak</b><p>Üç koşuda bir: lav daha sık ve sert yakar, tüy ×1,25.</p></div>
</div>

---

# Sürü

<div class="horde">
  <figure><img src="./images/sprites/enemy_husk.png" alt="" /><b>Kabuk</b><span>Yavaş, kalabalık</span></figure>
  <figure><img src="./images/sprites/enemy_imp.png" alt="" /><b>İfrit</b><span>Hızlı, kanatlı</span></figure>
  <figure><img src="./images/sprites/enemy_brute.png" alt="" /><b>İri</b><span>Ağır, dayanıklı</span></figure>
</div>

<div class="archetypes">
  <span><b>Hücumcu</b>Kibir · Gazap</span>
  <span><b>Yer büyücüsü</b>Açgözlülük · Şehvet</span>
  <span><b>Bombacı</b>Gazap</span>
  <span><b>Bölünen</b>Oburluk · Kıskançlık</span>
  <span><b>Kalkanlı</b>Kibir</span>
  <span><b>Havan</b>Tembellik · Açgözlülük</span>
  <span><b>Uyuyan</b>Tembellik</span>
  <span><b>Ayna</b>Kıskançlık</span>
</div>

<!-- Her diyarın sürüsü günahına göre karışır; yeni türler koşunun ilk dakikalarında sırayla katılır. Şeytan'ın diyarında hepsi bir arada. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/pride.png" alt="" />
<div class="realm-card" style="--h:#e7a6b5">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_pride.png" alt="" /><div><h1>Odin</h1><p class="sin">I · Kibir · 100 can</p></div></div>
<q>Burada ışık bile eğilir.</q>
<ol class="rail">
<li><em>%100</em><div><b>Nişanlı yelpaze ve hücum</b><p>Yerdeki köz hattı hücumun ilk engele kadar yolunu gösterir.</p></div></li>
<li><em>%50</em><div><b>Kalkan duruşu, ardından yere vuruş</b><p>1,5 saniye önünden gelen darbeyi keser, sonra 110 px'lik bir halka iner.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/step.svg" alt="" />Hattan yana çekil</span><span><img src="./images/icons/break.svg" alt="" />Kalkanı bitiricin kırar</span><span><img src="./images/icons/fly.svg" alt="" />Halkanın üstünden uç</span></div>
<p class="horde-line">Sürü: dengeli · Hücumcu · Kalkanlı</p>
</div>

<!-- Kibir'in derdi gurur: önünden geçilmez. Bitirici ya da arkadan gelen darbe kalkanı kırar ve Odin 1,2 saniye açık kalır. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/greed.png" alt="" />
<div class="realm-card" style="--h:#f0d483">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_greed.png" alt="" /><div><h1>Midas</h1><p class="sin">II · Açgözlülük · 130 can</p></div></div>
<q>Geçmek için ne vereceksin?</q>
<ol class="rail">
<li><em>%100</em><div><b>Altın halkaları</b><p>On iki yöne sikke saçar; nişan aldığı atışın iki yanında boşluk bırakır. Yer büyücüleri çağırır.</p></div></li>
<li><em>%60</em><div><b>Altın yağmuru</b><p>Meleğin çevresine sırayla beş mor daire düşer.</p></div></li>
<li><em>%25</em><div><b>Sarmal</b><p>Halkalar dönerek gelir; sarmalla birlikte adım at.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/step.svg" alt="" />Boşluğa adım at</span><span><img src="./images/icons/dash.svg" alt="" />Yağmurdan atıl</span><span><img src="./images/icons/fly.svg" alt="" />Sikkelerin üstünden uç</span></div>
<p class="horde-line">Sürü: ifritler · Yer büyücüsü · Havan</p>
</div>

<!-- Açgözlülük her şeyi ister: ekranı sikkeyle doldurur ama her halkada bir kapı bırakır. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/lust.png" alt="" />
<div class="realm-card" style="--h:#eea4cd">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_lust.png" alt="" /><div><h1>Lilith</h1><p class="sin">III · Şehvet · 110 can · en hızlı</p></div></div>
<q>Kal. Işık bekleyebilir.</q>
<ol class="rail">
<li><em>%100</em><div><b>Hücum ve öpücükler</b><p>Üç yavaş, mor öpücük havadan gelir; uçmak kurtarmaz.</p></div></li>
<li><em>%50</em><div><b>Göz kırpma</b><p>Meleğin 120 px arkasında bir daire belirir; Lilith oraya ışınlanıp hemen hücum eder.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/dash.svg" alt="" />Öpücüklerin içinden atıl</span><span><img src="./images/icons/step.svg" alt="" />İşaretli noktaya bas, ışınlanma bozulur</span></div>
<p class="horde-line">Sürü: ifritler · uçanlar · Yer büyücüsü</p>
</div>

<!-- Şehvet meleği oyalamak ister: arkasında belirir. Oyuncu işaretli noktaya basarsa ışınlanma iptal olur. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/envy.png" alt="" />
<div class="realm-card" style="--h:#9cd6ac">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_envy.png" alt="" /><div><h1>Loki</h1><p class="sin">IV · Kıskançlık · 165 can</p></div></div>
<q>O ışık kimin elinde olduğunu biliyor mu?</q>
<ol class="rail">
<li><em>%100</em><div><b>Ayna</b><p>Meleğin silahını kopyalar. Mızrağa karşı 120 px'lik saplama, yaya karşı 340 px'ten üç hızlı atış.</p></div></li>
<li><em>%60</em><div><b>Sahte kopya</b><p>Yanında karanlık bir ikizi belirir. İsim etiketi ve can barı yalnızca gerçeğinde var.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/step.svg" alt="" />Saplama hattından çekil</span><span><img src="./images/icons/strike.svg" alt="" />Etiketli olanı vur</span><span><img src="./images/icons/fly.svg" alt="" />Hattın üstünden uç</span></div>
<p class="horde-line">Sürü: uçanlar · Bölünen · Ayna</p>
</div>

<!-- Kıskançlık sahip olmadığını ister: meleğin silahını taklit eder. Silah değiştirmek Loki'nin taktiğini de değiştirir. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/gluttony.png" alt="" />
<div class="realm-card" style="--h:#efae72">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_gluttony.png" alt="" /><div><h1>Wendigo</h1><p class="sin">V · Oburluk · 220 can</p></div></div>
<q>Yutulacak bir ışık daha.</q>
<ol class="rail">
<li><em>%100</em><div><b>Sıçrama ve kusma</b><p>Meleğin üstüne 120 px'lik bir daireyle iner, ardında 4 saniyelik safra bırakır.</p></div></li>
<li><em>%50</em><div><b>Yutma</b><p>Ağzı meleği ve sürüyü çeker. Ağza ulaşan düşman yok olur; ağızda kalan melek ısırılır.</p></div></li>
<li><em>%20</em><div><b>Bölünenler</b><p>Ölünce ikiye ayrılan yaratıklar çağırır.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/fly.svg" alt="" />Safranın üstünden uç</span><span><img src="./images/icons/dash.svg" alt="" />Atılma çekimi yok sayar</span></div>
<p class="horde-line">Sürü: iriler · Bölünen</p>
</div>

<!-- Oburluk doymaz: kendi sürüsünü bile yer ama asla iyileşmez. Yutma sırasında atılmak çekimden kurtarır. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/wrath.png" alt="" />
<div class="realm-card" style="--h:#ee8672">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_wrath.png" alt="" /><div><h1>Kerberos</h1><p class="sin">VI · Gazap · 200 can</p></div></div>
<q>Üç ağız. Tek kapı.</q>
<ol class="rail">
<li><em>%100</em><div><b>Çift hücum, yere vuruş</b><p>İki hücum arka arkaya, durduğu yerde 90 px'lik bir vuruş.</p></div></li>
<li><em>%50</em><div><b>Öfke</b><p>%20 hızlanır; her hücumdan sonra bir mermi halkası.</p></div></li>
<li><em>%20</em><div><b>Şok dalgası</b><p>Üç köz halkası 0,45 saniye arayla dışa yayılır.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/step.svg" alt="" />Hücum hattından çekil</span><span><img src="./images/icons/fly.svg" alt="" />Halkaların üstünden uç</span><span><img src="./images/icons/dash.svg" alt="" />Aralarından atıl</span></div>
<p class="horde-line">Sürü: ifritler · iriler · Hücumcu · Bombacı</p>
</div>

<!-- Gazap hiç durmaz: canı azaldıkça hızlanır. Bombacıları ona doğru çekmek, patlamalarını ona karşı kullanmaktır. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/sloth.png" alt="" />
<div class="realm-card" style="--h:#99bde7">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_sloth.png" alt="" /><div><h1>Edward</h1><p class="sin">VII · Tembellik · 240 can</p></div></div>
<q>Mızrağını bırak. Dinlen.</q>
<ol class="rail">
<li><em>%100</em><div><b>Horlama ve çamur</b><p>Yavaş bir mermi halkası; çamur birikintileri yürüyüşü %60'a düşürür.</p></div></li>
<li><em>%65</em><div><b>Esneme</b><p>1,4 saniyelik uyarıyla 320 px'lik dev vuruş; ardından iki saniye uyur.</p></div></li>
<li><em>%25</em><div><b>Uyanış</b><p>Kızarır, iki buçuk kat hızlanır ve hücum etmeye başlar.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/fly.svg" alt="" />Esnemenin üstünden uç</span><span><img src="./images/icons/strike.svg" alt="" />Uykusunda vur</span></div>
<p class="horde-line">Sürü: yavaş kabuklar · Uyuyan · Havan</p>
</div>

<!-- Tembellik meleği yavaşlatır ve uyutmaya çalışır. Esnemeden sonraki uyku, en büyük hasar fırsatıdır. -->

---
class: realm
---

<img class="realm-bg" src="./images/realms/satan.png" alt="" />
<div class="realm-card" style="--h:#ee8672">
<div class="realm-head"><img class="realm-sprite" src="./images/sprites/boss_satan.png" alt="" /><div><h1>Şeytan</h1><p class="sin">Merkez · 520 can · 40 sn ritüel</p></div></div>
<q>Yedi mühür seni bana getirdi.</q>
<ol class="rail">
<li><em>%100</em><div><b>Cehennem ateşi</b><p>Havadan mor yelpazeler, hücum ve yağmur.</p></div></li>
<li><em>%66</em><div><b>Yedi imza</b><p>Yedi günahın hamlesi pentagram sırasıyla.</p></div></li>
<li><em>%33</em><div><b>Pentagram</b><p>Beş ışın 500 px uzanır, köz ve mor sırayla. Ortadaki beşgen güvenlidir.</p></div></li>
</ol>
<div class="answers"><span><img src="./images/icons/fly.svg" alt="" />Köz ışından uç</span><span><img src="./images/icons/dash.svg" alt="" />Mordan çık ya da atıl</span></div>
<p class="horde-line">Sürü: yedi diyarın hepsi</p>
</div>

<!-- Final, tüm oyunun özeti: her günahın imzası tek dövüşte. Zafer meleği yükseltir ve dünyayı iyileştirir. -->

---

# Sıradaki adım

<p class="sub">Tasarımı hazır, henüz oyunda değil</p>

<div class="planned">
  <div><b>Tarot</b><p>Her beş seviyede üç karttan biri. Biri bedel ister, biri sürüyü akıllandırır: bir tür hariç tüm yaratıkların saldırı deseni değişir.</p></div>
  <div><b>Parkur</b><p>Üzerine çıkılabilen engeller ve ağaçlar. Sürüden yukarıda nefes alıp yeniden saldırı açısı bulmak için.</p></div>
</div>

<!-- Bu ikisi Oyun Dinamikleri ve Akış dokümanlarından geliyor. Amaç aynı: her beş seviyede kuralları esnetmek ve haritayı taktik bir alana çevirmek. -->

---
layout: center
class: closing
---

<img class="logo small" src="./images/eight_logo_pixel.png" alt="EIGHT" />

<p class="question">Sizce melek ışıkta kalmalı mı, yoksa ilerlemeli mi?</p>

<div class="caption">Canlı gösterim · Kibir diyarı</div>

<!-- Canlı gösterimde Kibir'e girip ilk muhafızın saldırı hazırlığını göster. Tartışmayı jüriye bu soruyla aç. -->
