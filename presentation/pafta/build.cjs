const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('../node_modules/playwright-chromium');

(async () => {
  const root = __dirname;
  const pdfPath = path.join(root, 'Pafta.pdf');
  const review = path.join(root, 'review');
  fs.mkdirSync(review, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1588, height: 2245 },
    deviceScaleFactor: 2
  });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });

  try {
    await page.goto(`file:///${path.join(root, 'pafta.html').replace(/\\/g, '/')}`, { waitUntil: 'load' });
    await page.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all(Array.from(document.images).map(async image => {
        if (!image.complete) {
          await new Promise((resolve, reject) => {
            image.addEventListener('load', resolve, { once: true });
            image.addEventListener('error', () => reject(new Error(`Image failed: ${image.src}`)), { once: true });
          });
        }
        await image.decode();
      }));
    });

    const audit = await page.evaluate(() => {
      const poster = document.querySelector('.poster').getBoundingClientRect();
      const clippedText = Array.from(document.querySelectorAll('h1, h2, p, figcaption, .person, .sprite-label, .telegraph'))
        .filter(element => {
          const style = getComputedStyle(element);
          const verticalClip = (style.overflowY === 'hidden' || style.overflowY === 'clip') && element.scrollHeight > element.clientHeight + 1;
          return element.scrollWidth > element.clientWidth + 1 || verticalClip;
        })
        .map(element => ({
          tag: element.tagName,
          className: element.className,
          text: element.textContent.trim().slice(0, 90),
          client: [element.clientWidth, element.clientHeight],
          scroll: [element.scrollWidth, element.scrollHeight]
        }));
      return {
        poster: { width: poster.width, height: poster.height },
        page: { width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight },
        images: document.images.length,
        brokenImages: Array.from(document.images).filter(image => !image.naturalWidth).map(image => image.src),
        fonts: {
          texturina: document.fonts.check('600 29px Texturina'),
          sourceSans: document.fonts.check('400 16px "Source Sans 3"')
        },
        clippedText
      };
    });

    await page.emulateMedia({ media: 'print' });
    await page.pdf({
      path: pdfPath,
      width: '420mm',
      height: '594mm',
      printBackground: true,
      preferCSSPageSize: false,
      margin: { top: '0', right: '0', bottom: '0', left: '0' }
    });
    // Chromium quantizes page boxes; trim only the empty outer edge to exact A2.
    execFileSync('python', ['-c', `
import pymupdf, sys
path = sys.argv[1]
doc = pymupdf.open(path)
assert len(doc) == 1
page = doc[0]
page.set_mediabox(pymupdf.Rect(0, 0, 420 / 25.4 * 72, 594 / 25.4 * 72))
doc.saveIncr()
doc.close()
doc = pymupdf.open(path)
rect = doc[0].rect
assert abs(rect.width / 72 * 25.4 - 420) < 0.001
assert abs(rect.height / 72 * 25.4 - 594) < 0.001
doc.close()
`, pdfPath], { stdio: 'pipe' });
    await page.emulateMedia({ media: 'screen' });
    await page.locator('.poster').screenshot({ path: path.join(root, 'preview.png'), scale: 'device' });

    for (const id of ['header', 'concept-characters', 'flows', 'pixel-art', 'realms', 'ui-palette-tech', 'footer']) {
      await page.locator(`#${id}`).screenshot({ path: path.join(review, `${id}.png`), scale: 'device' });
    }
    for (const [name, selector] of [['gameflow', '.diagram:first-child'], ['core-loop', '.diagram:last-child'], ['gameplay', '.gameplay']]) {
      await page.locator(selector).screenshot({ path: path.join(review, `${name}.png`), scale: 'device' });
    }

    const pdfBytes = fs.statSync(path.join(root, 'Pafta.pdf')).size;
    if (pdfBytes >= 20 * 1024 * 1024) throw new Error(`PDF exceeds 20 MB: ${pdfBytes} bytes`);
    if (errors.length || audit.brokenImages.length || audit.clippedText.length) {
      throw new Error(JSON.stringify({ errors, audit }, null, 2));
    }
    console.log(JSON.stringify({ ...audit, errors, pdfBytes }, null, 2));
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
