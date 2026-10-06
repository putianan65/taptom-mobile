// One command to refresh docs/screenshots on your own computer, where map
// imagery is reachable:
//
//   node tool/screenshots/run-local.js                 every scene
//   node tool/screenshots/run-local.js farmer,trace    some scenes
//
// Builds the demo web app, serves it on port 8787, installs Playwright's
// Chromium the first time, then runs capture.js. Needs Flutter and Node 18+.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawnSync, spawn } = require('child_process');

const root = path.join(__dirname, '..', '..');
const web = path.join(root, 'build', 'web');
const port = Number(process.env.PORT || 8787);

function run(cmd, args, opts = {}) {
  // shell: true lets Windows find flutter.bat and npx.cmd.
  const r = spawnSync(cmd, args, { cwd: root, stdio: 'inherit', shell: true, ...opts });
  if (r.status !== 0) {
    console.error(`\n${cmd} ${args.join(' ')} failed`);
    process.exit(r.status || 1);
  }
}

function hasPlaywright() {
  try {
    require.resolve('playwright', { paths: [root] });
    return true;
  } catch {
    return false;
  }
}

const types = {
  '.html': 'text/html', '.js': 'application/javascript', '.mjs': 'application/javascript',
  '.json': 'application/json', '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.webp': 'image/webp', '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.ttf': 'font/ttf',
  '.otf': 'font/otf', '.frag': 'application/octet-stream', '.bin': 'application/octet-stream',
};

function serve() {
  return http
    .createServer((req, res) => {
      const url = decodeURIComponent(req.url.split('?')[0]);
      let file = path.join(web, url === '/' ? 'index.html' : url);
      if (!file.startsWith(web)) return res.writeHead(403).end();
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(web, 'index.html');
      res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    })
    .listen(port);
}

console.log('1/3 Building the demo web app');
// BUILD_ARGS adds flags, e.g. "--no-web-resources-cdn" where gstatic is blocked.
run('flutter', ['build', 'web', '--release', '--dart-define=TAPTOM_DEMO=true', ...(process.env.BUILD_ARGS || '').split(' ').filter(Boolean)]);

if (!hasPlaywright()) {
  console.log('2/3 Installing Playwright (first run only)');
  run('npm', ['install', '--no-save', '--no-audit', '--no-fund', 'playwright']);
  run('npx', ['playwright', 'install', 'chromium']);
} else {
  console.log('2/3 Playwright is installed');
}

console.log(`3/3 Capturing from http://localhost:${port}`);
const server = serve();
const child = spawn(process.execPath, [path.join(__dirname, 'capture.js')], {
  cwd: root,
  stdio: 'inherit',
  env: {
    ...process.env,
    BASE_URL: `http://localhost:${port}`,
    PLAYWRIGHT: require.resolve('playwright', { paths: [root] }),
    ...(process.argv[2] ? { SCENES: process.argv[2] } : {}),
  },
});
child.on('exit', (code) => {
  server.close();
  console.log(code === 0 ? '\nDone. New images are in docs/screenshots.' : '\nCapture failed.');
  process.exit(code ?? 1);
});
