// Captures the portfolio screenshots in docs/screenshots from a demo web build.
//
//   flutter build web --release --dart-define=TAPTOM_DEMO=true
//   (cd build/web && python3 -m http.server 8787)
//   node tool/screenshots/capture.js            every scene
//   SCENES=farmer,admin node tool/screenshots/capture.js
//
// See driver.js for the environment variables. TRACE_LOT picks the lot
// report to capture (default: the demo lot TPT-2568-0042).
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const D = require('./driver.js');

const scenes = {
  async login() {
    for (const scheme of ['light', 'dark']) {
      const { browser, page } = await D.open({ scheme });
      await D.boot(page);
      await D.shot(page, `${scheme}-login`, 2500);
      if (scheme === 'light') {
        await D.scroll(page, 2000);
        await D.shot(page, 'login-credit');
      }
      await browser.close();
    }
  },

  // Login backdrop and Lung Tom in motion, as a GIF. Needs ffmpeg.
  async motion() {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'taptom-video-'));
    const { browser, page } = await D.open({ scale: 1, video: dir });
    await D.boot(page);
    await page.waitForTimeout(7000);
    const video = await page.video().path();
    await page.context().close();
    await browser.close();
    const out = path.join(D.OUT, 'login-motion.gif');
    execFileSync('ffmpeg', [
      // The last six seconds skip the boot frames.
      '-y', '-loglevel', 'error', '-sseof', '-6', '-i', video,
      '-vf', 'fps=15,crop=390:390:0:0,scale=390:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4',
      '-loop', '0', out,
    ]);
    console.log('saved', path.relative(process.cwd(), out));
  },

  async farmer() {
    const { browser, page } = await D.open();
    await D.boot(page);
    await D.signIn(page, 'farmer');
    await D.shot(page, 'farmer-home', 2500);

    await D.scroll(page, 900);
    await D.tap(page, 'สวนกระท่อมหนองปลิง', { wait: 3500 });
    await D.shot(page, 'plot-detail', 1500 + D.MAP_WAIT);
    await D.back(page);
    await D.scroll(page, -3000);

    await D.tap(page, 'การแจ้งเตือน', { scroll: false, wait: 2000 });
    await D.shot(page, 'notifications');
    await D.back(page);

    await D.tap(page, 'ถามลุงต้อม', { wait: 2500 });
    await D.tap(page, 'ใส่ปุ๋ย', { wait: 4500 });
    await D.shot(page, 'ask-lung-tom', 1500);
    await D.back(page);

    await D.tab(page, 'แผนที่');
    await D.shot(page, 'map', 4000 + D.MAP_WAIT);

    await D.tab(page, 'บัญชี');
    await D.scroll(page, 3000);
    await D.shot(page, 'farmer-account', 1500);

    await D.tab(page, 'บันทึก GAP');
    await D.shot(page, 'gap-overview', 2000);
    await D.tap(page, 'ถัดไป: 1.4', { wait: 2500 });
    await D.shot(page, 'gap-plot');
    await D.tap(page, '1.4 การเก็บเกี่ยว', { wait: 2500 });
    await D.shot(page, 'gap-form');
    await browser.close();
  },

  async trace() {
    const { browser, page } = await D.open();
    await D.boot(page, `/#/traceability/${process.env.TRACE_LOT || 'TPT-2568-0042'}`);
    await D.shot(page, 'traceability', 3000 + D.MAP_WAIT);
    await browser.close();
  },

  async admin() {
    const { browser, page } = await D.open();
    await D.boot(page);
    await D.signIn(page, 'admin');
    await D.shot(page, 'admin-home', 2500);

    await D.tap(page, 'ตรวจข้อมูล GAP', { wait: 2000 });
    await D.fill(page, 'ชื่อ เบอร์โทร หรือพื้นที่', 'สมชาย');
    await D.tap(page, 'สมชาย ใจดี', { wait: 2000 });
    await D.shot(page, 'admin-farmer-plots');
    await D.tap(page, 'แปลงริมคลองวังทอง', { wait: 3000 });
    await D.shot(page, 'admin-inspection', 1500);
    await D.back(page);
    await D.back(page);

    await D.tab(page, 'สมาชิก');
    await D.shot(page, 'admin-members', 2000);
    await D.tab(page, 'แผนที่');
    await D.shot(page, 'admin-map', 4000 + D.MAP_WAIT);
    await browser.close();
  },

  async super() {
    const { browser, page } = await D.open();
    await D.boot(page);
    await D.signIn(page, 'super');
    await D.shot(page, 'super-admin-home', 2500);
    await D.scroll(page, 1100);
    await D.shot(page, 'super-admin-charts', 1500);
    await D.tab(page, 'เจ้าหน้าที่');
    await D.shot(page, 'super-admin-officers', 2000);
    await browser.close();
  },

  async dark() {
    for (const role of ['farmer', 'super']) {
      const { browser, page } = await D.open({ scheme: 'dark' });
      await D.boot(page);
      await D.signIn(page, role);
      await D.shot(page, `dark-${role === 'super' ? 'super-admin' : role}-home`, 2500);
      await browser.close();
    }
  },

  async desktop() {
    for (const role of ['super', 'admin']) {
      const { browser, page } = await D.open({ width: 1280, height: 800, scale: 1.5 });
      await D.boot(page);
      await D.signIn(page, role);
      await D.shot(page, `desktop-${role === 'super' ? 'super-admin' : role}`, 3000);
      await browser.close();
    }
  },
};

(async () => {
  const wanted = (process.env.SCENES || Object.keys(scenes).join(',')).split(',');
  for (const name of wanted) {
    console.log('scene', name);
    await scenes[name]();
  }
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
