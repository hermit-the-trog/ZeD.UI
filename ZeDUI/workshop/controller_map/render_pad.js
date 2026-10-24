// ZeDUI/workshop/controller_map/render_pad.js: controller_pad.html -> controller_pad.png (3840 x 2160)
// Run with Playwright's Chromium:  node render_pad.js   (fonts beside the HTML)
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 2 });
  await p.goto('file://' + path.resolve(__dirname, 'controller_pad.html'));
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(300);
  await p.screenshot({ path: path.resolve(__dirname, 'controller_pad.png'), omitBackground: true });
  await b.close();
})();
