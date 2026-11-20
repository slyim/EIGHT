# EIGHT sunumu

[Sunumu PDF olarak aç](EIGHT-jury.pdf). Son slayt oynanabilir sürümün bağlantısını verir: [slyim.github.io/EIGHT](https://slyim.github.io/EIGHT/). Yirmi yedi slayt, dört bölüm: Evren (sekiz kat, gizli yüzlü melek, yedi günahın sesi, vitrayda günahlar, arınma), Oynanış (simge dili, pentagram, koşu, savaş, uyarılar, şifa, güçlenme, antlaşmalar, dükkân, zorluk, sürü), Diyarlar (her günah için bir infografik sayfa) ve Yol haritası.

Tasarım belgeleri: [Oyun Dinamikleri ve Sistem Tasarımı](docs/oyun-dinamikleri.pdf) · [Oyun Genel Akışı ve Oyun İçi Akış](docs/oyun-akisi.pdf). Sunum, bu belgelerdeki çekirdek döngüyü ve ışıkta iyileşmeyi oyundaki hâliyle gösterir. Tarot / Akıllı AI ve parkur "Sıradaki adım" slaytında henüz oyunda olmayan tasarımlar olarak yer alır; Q W E R yetenekleri tasarımdan çıkarıldı.

[Düzenlenebilir Slidev kaynağı](slides.md) Türkçe konuşmacı notları içerir. İlk kurulum için `npm ci`, sunmak için `npm run dev`, PDF için `npx slidev export slides.md --output EIGHT-jury.pdf` çalıştırılır. P tuşu sunucu görünümünü açar.

- Simgeler oyunla aynı set olan [Phosphor Icons](https://phosphoricons.com) dolgu (fill) ağırlığından gelir (MIT) ve sunum boyunca aynı anlamda kullanılır; anlamları "Simge dili" slaytındadır.
- Arayüz görselleri (`images/ui/`) oyunun kendi vektör arayüzünden 2x çözünürlükte çekilmiştir.
- Yazı tipleri oyunla aynıdır: başlıklarda Cinzel Bold, metinde Alegreya Sans (OFL, lisanslar `fonts/` klasöründe).
- Ekip: Mustafa Yıldız (2308A008), Lila Aydın (2308A025), Ahmet Altuğ Aktaş (2308A061); kapakta ve kapanışta yer alır.
- `images/glass/` Ahmet Altuğ Aktaş'ın vektör karakter çizimlerinin, oyunun vitray gölgelendiricisinden (`eight/shaders/stained_glass.gdshader`) geçmiş hâlidir: `godot --path eight --script res://tools/render_glass.gd -- <girdi_klasörü> presentation/images/glass`.
- `images/sprites/` oyundaki Aseprite spritelarının ilk karelerini içerir (alfa 0.1, kodla üretilmiş). Spritelar değişince `bash export_sprites.sh <aseprite.exe>` ile yenilenir.
