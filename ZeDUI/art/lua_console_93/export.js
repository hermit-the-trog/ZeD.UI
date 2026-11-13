// Exports the Lua Console 93 box art from lua_console_93_box.html: node export.js <html> <out-dir>
const { chromium } = require('playwright'); const path = require('path');
(async () => {
  const [html, out] = process.argv.slice(2);
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1960, height: 900 }, deviceScaleFactor: 2 });
  await p.goto('file://' + path.resolve(html));
  await p.screenshot({ path: path.join(out, 'lua_console_93_sheet.png'), fullPage: true });
  await p.locator('.front').first().screenshot({ path: path.join(out, 'lua_console_93_front.png') });
  await p.locator('.stage > div > .back').screenshot({ path: path.join(out, 'lua_console_93_back.png') });
  await p.addStyleTag({ content: 'body{background:transparent!important}' });
  await p.locator('.box').first().screenshot({ path: path.join(out, 'lua_console_93_box.png'), omitBackground: true });
  await p.evaluate(() => { const e = document.getElementById('s512'); document.body.appendChild(e); e.style.cssText = 'position:fixed;left:0;top:0;z-index:9'; });
  await p.locator('#s512').screenshot({ path: path.join(out, 'lua_console_93_square_1024.png') });
  await p.evaluate(() => { document.getElementById('s512').remove(); const e = document.getElementById('icon'); document.body.appendChild(e); e.style.position = 'fixed'; e.style.left = '0'; e.style.top = '0'; e.style.zIndex = '9'; });
  await p.locator('#icon').screenshot({ path: path.join(out, 'lua_console_93_icon_512.png') });
  await b.close();
})();
