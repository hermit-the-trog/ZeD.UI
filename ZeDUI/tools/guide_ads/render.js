// render every ad (or the ones named): out/preview/<name>.png on paper, out/final/<name>.png ink on transparent, 2x
const { chromium } = require('playwright'); const fs = require('fs'), path = require('path');
(async () => {
  const names = process.argv.slice(2).length ? process.argv.slice(2) : fs.readdirSync('src').filter(f => f.endsWith('.html')).map(f => f.slice(0, -5));
  const b = await chromium.launch();
  const p = await b.newPage({ deviceScaleFactor: 2, viewport: { width: 700, height: 900 } });
  for (const n of names) {
    for (const [hash, dir, omit] of [['', 'preview', false], ['#final', 'final', true]]) {
      await p.goto('about:blank');   // (a hash-only change does not reload the page: the final came out on paper)
      await p.goto('file://' + path.resolve('src', n + '.html') + hash);
      await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(80);
      const el = await p.$('#ad');
      const bb = await el.boundingBox();
      await el.screenshot({ path: `out/${dir}/${n}.png`, omitBackground: omit });
      if (!omit) {
        const of = await p.evaluate(() => [...document.querySelectorAll('#ad *')].filter(e => { const r = e.getBoundingClientRect(), a = document.getElementById('ad').getBoundingClientRect(); return r.width > 0 && (r.right > a.right + .5 || r.bottom > a.bottom + .5 || r.left < a.left - .5); }).map(e => e.className.baseVal ?? e.className).slice(0, 5));
        console.log(n, bb.width + 'x' + bb.height, of.length ? 'OVERFLOW ' + of.join(',') : '');
      }
    }
  }
  await b.close();
})();
