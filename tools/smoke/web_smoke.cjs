// Loads the web build in headless Chromium (SwiftShader WebGL 2), waits for the game to
// boot, saves a screenshot, and checks the phone block message.
// Usage: NODE_PATH=$(npm root -g) node tools/smoke/web_smoke.cjs <url> <out_dir>
const { chromium, devices } = require('playwright');

(async () => {

const url = process.argv[2] || 'http://localhost:8060/index.html';
const out = process.argv[3] || 'production/screens';
const browser = await chromium.launch({
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
});
let failures = 0;

// Desktop
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const logs = [];
page.on('console', (m) => logs.push(`[${m.type()}] ${m.text()}`));
page.on('pageerror', (e) => logs.push(`[pageerror] ${e.message}`));
const t0 = Date.now();
await page.goto(url);
// The status overlay is removed once the engine has started.
await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 120000 }).catch(() => {});
const booted = await page.evaluate(() => !document.getElementById('status'));
console.log(`desktop: booted=${booted} in ${((Date.now() - t0) / 1000).toFixed(1)}s`);
await page.waitForTimeout(6000);
await page.screenshot({ path: `${out}/web_desktop.png` });
const errors = logs.filter((l) => l.startsWith('[error]') || l.startsWith('[pageerror]'));
console.log(logs.slice(0, 40).join('\n'));
if (!booted) failures++;
if (errors.length) { console.log(`desktop: ${errors.length} console errors`); failures++; }

// Phone: must show the block message instead of loading.
const phone = await browser.newContext({ ...devices['Pixel 7'] });
const p2 = await phone.newPage();
await p2.goto(url);
await p2.waitForTimeout(1500);
const notice = await p2.evaluate(() => document.getElementById('status-notice')?.innerText || '');
console.log(`phone: notice="${notice.replace(/\n/g, ' | ')}"`);
if (!/desktop|ordinateur/i.test(notice)) failures++;
await p2.screenshot({ path: `${out}/web_phone.png` });

await browser.close();
console.log(`web_smoke: ${failures} failure(s)`);
process.exit(failures ? 1 : 0);
})();
