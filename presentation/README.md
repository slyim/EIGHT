# EIGHT sunumu

[Sunumu PDF olarak aç](EIGHT-jury.pdf). Yirmi iki slayt: hikâye, harita, koşu döngüsü, savaş ve uyarı dili, şifa, güçlenme, antlaşmalar, dükkân, zorluk, sürü, her diyar için bir infografik sayfa ve sıradaki adım.

Tasarım belgeleri: [Oyun Dinamikleri ve Sistem Tasarımı](docs/oyun-dinamikleri.pdf) · [Oyun Genel Akışı ve Oyun İçi Akış](docs/oyun-akisi.pdf). Sunum, bu belgelerdeki çekirdek döngüyü ve ışıkta iyileşmeyi oyundaki hâliyle gösterir. Tarot / Akıllı AI ve parkur "Sıradaki adım" slaytında henüz oyunda olmayan tasarımlar olarak yer alır; Q W E R yetenekleri tasarımdan çıkarıldı.

[Düzenlenebilir Slidev kaynağı](slides.md) Türkçe konuşmacı notları içerir. İlk kurulum için `npm ci`, sunmak için `npm run dev`, PDF için `npx slidev export slides.md --output EIGHT-jury.pdf` çalıştırılır. P tuşu sunucu görünümünü açar.

- Yazı tipleri oyunla aynıdır: başlıklarda Cinzel Bold, metinde Alegreya Sans (OFL, lisanslar `fonts/` klasöründe).
- `images/sprites/` oyundaki geçici (PLACEHOLDER) Aseprite spritelarının ilk karelerini içerir. Spritelar değişince `bash export_sprites.sh <aseprite.exe>` ile yenilenir.
