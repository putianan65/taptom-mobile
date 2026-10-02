// Drives a demo web build of TAPTOM through Flutter's semantics tree.
//
// Environment:
//   BASE_URL           where the web build is served (default http://localhost:8787)
//   OUT_DIR            where PNGs are written (default docs/screenshots)
//   PLAYWRIGHT         module path for playwright (default 'playwright')
//   HTTPS_PROXY        optional proxy for CDN and map tiles
//   MAPLIBRE_DIST      optional local maplibre-gl/dist folder served instead of unpkg
//   OFFLINE_TILES      set to answer map tile requests with empty tiles
//   REAL_API           set when the build talks to a seeded backend: sign in by typing
const fs = require('fs');
const path = require('path');
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright');

const BASE = process.env.BASE_URL || 'http://localhost:8787';
const OUT = process.env.OUT_DIR || path.join(__dirname, '..', '..', 'docs', 'screenshots');

async function open({ width = 390, height = 844, scheme = 'light', scale = 2, video = null } = {}) {
  const launch = {};
  if (process.env.HTTPS_PROXY) launch.proxy = { server: process.env.HTTPS_PROXY, bypass: '<-loopback>,localhost,127.0.0.1' };
  const browser = await chromium.launch(launch);
  const ctx = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: scale,
    colorScheme: scheme,
    ignoreHTTPSErrors: true,
    locale: 'th-TH',
    ...(video ? { recordVideo: { dir: video, size: { width, height } } } : {}),
  });
  if (process.env.MAPLIBRE_DIST) {
    await ctx.route('https://unpkg.com/maplibre-gl@*/dist/**', (route) => {
      const file = route.request().url().split('/').pop();
      route.fulfill({
        body: fs.readFileSync(path.join(process.env.MAPLIBRE_DIST, file)),
        contentType: file.endsWith('.css') ? 'text/css' : 'application/javascript',
      });
    });
  }
  if (process.env.OFFLINE_TILES) {
    // Sandboxes without map access: answer tile and glyph requests with an
    // empty tile so MapLibre still draws plot outlines on its ground colour.
    const empty = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAABFUlEQVR4nO3BMQEAAADCoPVP7WsIoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAeAMBPAABPO1TCQAAAABJRU5ErkJggg==',
      'base64',
    );
    await ctx.route(/arcgisonline\.com|api\.maptiler\.com\/tiles/, (r) => r.fulfill({ body: empty, contentType: 'image/png' }));
    await ctx.route(/demotiles\.maplibre\.org/, (r) => r.fulfill({ status: 404, body: '' }));
  }
  const page = await ctx.newPage();
  page.on('pageerror', (e) => process.env.DEBUG && console.log('pageerror:', e.stack || e.message));
  page.on('console', (m) => process.env.DEBUG && ['error', 'warning'].includes(m.type()) && console.log('console:', m.text().slice(0, 400)));
  return { browser, page };
}

async function boot(page, route = '/') {
  await page.goto(BASE + route, { waitUntil: 'networkidle' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 30000 });
  await page.waitForTimeout(3000);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(500);
}

async function nodes(page) {
  return page.$$eval('flt-semantics', (els) =>
    els
      .map((e) => {
        const r = e.getBoundingClientRect();
        const own = e.childElementCount === 0 ? e.textContent : '';
        const text = `${e.getAttribute('aria-label') || ''} ${own}`.trim().replace(/\s+/g, ' ');
        return { text, x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height };
      })
      .filter((n) => n.text && n.w > 0 && n.h > 0),
  );
}

async function tap(page, text, { exact = false, nth = 0, wait = 700, scroll = true } = {}) {
  for (let attempt = 0; attempt < 16; attempt++) {
    const all = await nodes(page);
    const hits = all.filter((n) => (exact ? n.text === text : n.text.includes(text)));
    if (hits.length) {
      const n = hits[Math.min(nth, hits.length - 1)];
      const vh = page.viewportSize().height;
      if (scroll && (n.y > vh - 90 || n.y < 60)) {
        // Bring the target into the middle of the screen, then look again.
        await page.mouse.move(page.viewportSize().width / 2, vh / 2);
        await page.mouse.wheel(0, n.y - vh / 2);
        await page.waitForTimeout(700);
        continue;
      }
      await page.mouse.click(n.x, n.y);
      await page.waitForTimeout(wait);
      return;
    }
    // Give the page a moment to load, then look further down long lists.
    if (scroll && attempt >= 4) {
      const vp = page.viewportSize();
      await page.mouse.move(vp.width / 2, vp.height / 2);
      await page.mouse.wheel(0, vp.height * 0.6);
    }
    await page.waitForTimeout(400);
  }
  const all = await nodes(page);
  throw new Error(`No semantics node matching "${text}". Seen: ${all.map((n) => n.text).join(' | ').slice(0, 1500)}`);
}

async function scroll(page, dy, x = 195, y = 500) {
  await page.mouse.move(x, y);
  await page.mouse.wheel(0, dy);
  await page.waitForTimeout(900);
}

/// Taps a destination in the fixed bottom bar or navigation rail.
async function tab(page, label, wait = 2500) {
  await tap(page, `${label} ${label}`, { exact: true, scroll: false, wait });
}

/// Taps the back button of the current page.
async function back(page, wait = 1500) {
  await tap(page, 'กลับ', { scroll: false, wait });
}

async function shot(page, name, wait = 1200) {
  await page.waitForTimeout(wait);
  fs.mkdirSync(OUT, { recursive: true });
  const file = path.join(OUT, `${name}.png`);
  await page.screenshot({ path: file });
  console.log('saved', path.relative(process.cwd(), file));
}

/// Focuses the text field labelled [label] and types [text].
async function fill(page, label, text) {
  await page.click(`input[aria-label="${label}"]`);
  await page.waitForTimeout(300);
  await page.keyboard.type(text, { delay: 30 });
  await page.waitForTimeout(200);
}

// The demo accounts, also seeded into a local backend for REAL_API runs.
const accounts = {
  farmer: ['0812345678', '15', '01', '2518'],
  admin: ['0898765432', '20', '05', '2528'],
  super: ['0800000001', '01', '01', '2525'],
};

async function signIn(page, role) {
  if (process.env.REAL_API) {
    // No one-tap demo accounts: type the phone number and birthday.
    const [phone, d, m, y] = accounts[role];
    await fill(page, '08X XXX XXXX', phone);
    await fill(page, 'วัน', d);
    await fill(page, 'เดือน', m);
    await fill(page, 'ปี พ.ศ.', y);
    // A complete birthday submits the form by itself.
    await page.waitForTimeout(2500);
    if ((await nodes(page)).some((n) => n.text === 'เข้าสู่ระบบ')) await tap(page, 'เข้าสู่ระบบ', { exact: true, wait: 2000 });
  } else {
    const label = { farmer: 'เกษตรกร', admin: 'เจ้าหน้าที่', super: 'ผู้ดูแลระบบ' }[role];
    await tap(page, label, { exact: true });
    await tap(page, 'เข้าสู่ระบบ', { exact: true, wait: 2000 });
  }
  if (role !== 'farmer') {
    for (const d of role === 'super' ? '12345678' : '123456') await tap(page, d, { exact: true, wait: 120 });
    await page.waitForTimeout(3000);
  }
}

module.exports = { OUT, open, boot, nodes, tap, fill, tab, back, scroll, shot, signIn };
