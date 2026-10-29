#!/usr/bin/env bash
set -euo pipefail
# Generated helpers and tool packages live outside the checkout; repository files stay intact.
# Public npm registry use was explicitly approved for this environment.
rwa_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
rwa_repo_dir="${RWA_REPO_DIR:-$(git -C "$rwa_script_dir" rev-parse --show-toplevel)}"
rwa_repo_dir="$(git -C "$rwa_repo_dir" rev-parse --show-toplevel)"
export RWA_REPO_DIR="$rwa_repo_dir"
if ! git -C "$rwa_repo_dir" remote get-url upstream >/dev/null 2>&1; then
  git -C "$rwa_repo_dir" remote add upstream https://github.com/cypress-io/cypress-realworld-app.git
fi
mkdir -p /workspace/.tools /workspace/artifacts
cd /workspace
npm install --save-exact --prefix /workspace/.tools --registry=https://registry.npmjs.org --no-audit --no-fund node@22.20.0 yarn@1.22.22 @playwright/mcp@0.0.83
export PATH="/workspace/.tools/node_modules/.bin:$PATH"
for rwa_command in chromium ffmpeg ffprobe Xorg xdpyinfo; do
  if ! command -v "$rwa_command" >/dev/null; then
    printf 'Missing base-image prerequisite: %s. Restore this capability before continuing.\n' "$rwa_command" >&2
    exit 1
  fi
done
test -f /usr/lib/xorg/modules/drivers/dummy_drv.so || { printf 'Xorg dummy driver is missing.\n' >&2; exit 1; }
rwa_encoders="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
[[ "$rwa_encoders" == *libx264* ]] || { printf 'FFmpeg H.264 encoder is missing.\n' >&2; exit 1; }
# Preserve existing helper edits before replacing generated files. Repeated identical runs make no backups.
rwa_write_helper() {
  local rwa_name="$1" rwa_temporary rwa_destination rwa_backup
  rwa_temporary="$(mktemp /workspace/.tools/.rwa-helper.XXXXXX)"
  cat > "$rwa_temporary"
  rwa_destination="/workspace/.tools/$rwa_name"
  if [[ -e "$rwa_destination" || -L "$rwa_destination" ]]; then
    if cmp -s -- "$rwa_temporary" "$rwa_destination"; then
      rm -- "$rwa_temporary"
      return
    fi
    mkdir -p /workspace/.tools/backups
    rwa_backup="$(mktemp -d /workspace/.tools/backups/changed-helper.XXXXXX)"
    cp -a -- "$rwa_destination" "$rwa_backup/$rwa_name"
  fi
  mv -- "$rwa_temporary" "$rwa_destination"
}
rwa_write_helper 'rwa-repo-path' <<<"$rwa_repo_dir"
rwa_write_helper 'rwa-install.sh' < "$rwa_repo_dir/.agents/skills/cloud-development/scripts/bootstrap.sh"
rwa_write_helper 'rwa-env.sh' <<'RWA_GENERATED_HELPER_0_END'
#!/usr/bin/env bash
export PATH="/workspace/.tools/node_modules/.bin:$PATH"
if [[ -z "${RWA_REPO_DIR:-}" ]]; then
  IFS= read -r RWA_REPO_DIR < /workspace/.tools/rwa-repo-path
fi
export RWA_REPO_DIR
RWA_GENERATED_HELPER_0_END
rwa_write_helper 'rwa-start.sh' <<'RWA_GENERATED_HELPER_1_END'
#!/usr/bin/env bash
set -euo pipefail
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
case "${1:-}" in
  frontend)
    exec env NODE_ENV=development yarn start:react --host 0.0.0.0 --port 3000 --strictPort
    ;;
  api)
    exec env NODE_ENV=development yarn start:api:watch
    ;;
  prepare)
    if [[ ! -e src/aws-exports.js ]]; then
      cp scripts/mock-aws-exports.js src/aws-exports.js
    fi
    if [[ ! -e aws-exports-es5.js ]]; then
      cp scripts/mock-aws-exports-es5.js aws-exports-es5.js
    fi
    ;;
  reset-demo-data)
    exec yarn db:seed:dev
    ;;
  *)
    printf 'Usage: bash /workspace/.tools/rwa-start.sh {frontend|api|prepare|reset-demo-data}\n' >&2
    exit 2
    ;;
esac
RWA_GENERATED_HELPER_1_END
rwa_write_helper 'rwa-mcp.sh' <<'RWA_GENERATED_HELPER_2_END'
#!/usr/bin/env bash
set -euo pipefail
source /workspace/.tools/rwa-env.sh
cd /workspace
rwa_mode=(--headless)
if [[ "${1:-}" == --headed ]]; then
  rwa_mode=()
  shift
fi
exec node /workspace/.tools/node_modules/@playwright/mcp/cli.js \
  "${rwa_mode[@]}" --isolated --no-sandbox --executable-path /usr/bin/chromium \
  --caps devtools --viewport-size 1180x800 --timeout-navigation 20000 \
  --output-dir /workspace/artifacts "$@"
RWA_GENERATED_HELPER_2_END
rwa_write_helper 'rwa-check.cjs' <<'RWA_GENERATED_HELPER_3_END'
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const repo = process.env.RWA_REPO_DIR || readFileSync('/workspace/.tools/rwa-repo-path', 'utf8').trim();
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function request(url, options = {}) {
  return fetch(url, { ...options, signal: AbortSignal.timeout(5000) });
}
(async () => {
  let ready = false;
  const deadline = Date.now() + 45000;
  while (Date.now() < deadline) {
    try {
      const frontend = await request('http://127.0.0.1:3000/');
      const html = await frontend.text();
      const backend = await request('http://127.0.0.1:3001/');
      ready = frontend.ok && html.includes('id="root"') &&
        html.includes('/src/index.tsx') && backend.ok &&
        (await backend.text()).includes('Cypress Realworld App - backend');
      if (ready) break;
    } catch {}
    await delay(500);
  }
  assert(ready, 'Frontend or API did not become ready; inspect their logs');
  const first = JSON.parse(readFileSync(join(repo, 'data/database.json'), 'utf8')).users[0];
  const password = require(join(repo, 'node_modules/dotenv')).parse(
    readFileSync(join(repo, '.env'))).SEED_DEFAULT_USER_PASSWORD;
  assert(first && password, 'The demo database and default password are required');
  const login = await request('http://127.0.0.1:3001/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: first.username, password }),
  });
  assert.equal(login.status, 200, 'Seeded demo login failed; preserve custom data and diagnose credentials');
  assert.equal((await login.json()).user.id, first.id);
  const cookie = login.headers.getSetCookie().map(value => value.split(';')[0]).join('; ');
  assert(cookie, 'Login did not create a session');
  const auth = await request('http://127.0.0.1:3001/checkAuth', { headers: { Cookie: cookie } });
  assert.equal(auth.status, 200);
  assert.equal((await auth.json()).user.id, first.id);
  const transactions = await request('http://127.0.0.1:3001/transactions/public', { headers: { Cookie: cookie } });
  assert.equal(transactions.status, 200);
  assert(Array.isArray((await transactions.json()).results), 'Transaction response is invalid');
  console.log('PASS: IPv4 frontend, API, demo login, session, and transaction data');
})().catch(error => { console.error(error.message); process.exitCode = 1; });
RWA_GENERATED_HELPER_3_END
rwa_write_helper 'rwa-unit.sh' <<'RWA_GENERATED_HELPER_4_END'
#!/usr/bin/env bash
set -euo pipefail
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
rwa_backup_dir="$(mktemp -d /tmp/rwa-unit.XXXXXX)"
cp -p data/database.json "$rwa_backup_dir/database.json"
rwa_restore_database() {
  rwa_test_status=$?
  trap - EXIT
  if ! cp -p "$rwa_backup_dir/database.json" data/database.json; then
    printf 'Could not restore database; backup retained at %s\n' "$rwa_backup_dir" >&2
    exit 1
  fi
  rm -rf -- "$rwa_backup_dir"
  exit "$rwa_test_status"
}
trap rwa_restore_database EXIT
yarn test:unit:ci
RWA_GENERATED_HELPER_4_END
rwa_write_helper 'rwa-playwright.cjs' <<'RWA_GENERATED_HELPER_5_END'
const assert = require('node:assert/strict');
const { spawn, spawnSync } = require('node:child_process');
const { createInterface } = require('node:readline');
const { mkdirSync, mkdtempSync, writeFileSync, readFileSync } = require('node:fs');
const { join } = require('node:path');
const mode = process.argv[2] || '--screenshot';
assert(['--screenshot', '--record', '--native-video'].includes(mode),
  'Usage: node /workspace/.tools/rwa-playwright.cjs [--screenshot|--record|--native-video]');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const outputRoot = '/workspace/artifacts';
mkdirSync(outputRoot, { recursive: true });
const runDir = mkdtempSync(join(outputRoot, 'playwright-'));
const requests = new Map();
let sequence = 0;
let server;
let lines;
let ownedDisplay;
let recorder;
let recorderDone;
let recordingStarted = false;
let display = process.env.DISPLAY || ':99';
function spawnOwned(command, args, options = {}) {
  return spawn(command, args, { detached: true, ...options });
}
async function stopOwned(child) {
  if (!child?.pid) return;
  const done = child.exitCode !== null || child.signalCode !== null
    ? Promise.resolve() : new Promise(resolve => child.once('exit', resolve));
  try { process.kill(-child.pid, 'SIGTERM'); } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
  await Promise.race([done, delay(3000)]);
  try { process.kill(-child.pid, 'SIGKILL'); } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}
async function ensureDisplay() {
  const available = () => spawnSync('xdpyinfo', ['-display', display], { stdio: 'ignore' }).status === 0;
  if (available()) return;
  ownedDisplay = spawnOwned('Xorg', [display, '-config', '/workspace/.tools/xorg-rwa.conf',
    '-logfile', join(runDir, 'xorg.log'), '-nolisten', 'tcp', '-noreset'], { stdio: 'ignore' });
  for (let attempt = 0; attempt < 40; attempt++) {
    if (available()) return;
    if (ownedDisplay.exitCode !== null) break;
    await delay(250);
  }
  throw new Error('Local display did not start; use supported escalated execution and inspect xorg.log');
}
function rpc(method, params = {}) {
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { requests.delete(id); reject(new Error(`MCP timeout: ${method}`)); }, 45000);
    requests.set(id, { resolve, reject, timer });
    server.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
}
async function call(name, args = {}) {
  const result = await rpc('tools/call', { name, arguments: args });
  if (result.isError) {
    throw new Error(`${name}: ${result.content?.filter(c => c.type === 'text').map(c => c.text).join('\n')}`);
  }
  return result;
}
async function requirePage(pathname, selectors) {
  await call('browser_evaluate', { function: `() => {
    if (location.pathname !== ${JSON.stringify(pathname)}) throw new Error('Unexpected route: ' + location.pathname);
    for (const selector of ${JSON.stringify(selectors)}) {
      if (!document.querySelector(selector)) throw new Error('Missing control: ' + selector);
    }
    if (document.querySelector('vite-error-overlay')) throw new Error('Vite error overlay is visible');
    return { route: location.pathname, title: document.title };
  }` });
}
async function stopRecorder() {
  if (!recorder) return;
  recorder.kill('SIGINT');
  const { code, signal } = await recorderDone;
  recorder = null;
  assert(code === 0 || code === 255, `Screen recording failed: ${code || signal}`);
}
(async () => {
  try {
    if (mode === '--record') await ensureDisplay();
    server = spawnOwned('bash', ['/workspace/.tools/rwa-mcp.sh',
      ...(mode === '--record' ? ['--headed'] : []), '--output-dir', runDir], {
      cwd: '/workspace', env: { ...process.env, DISPLAY: display }, stdio: ['pipe', 'pipe', 'pipe'],
    });
    const stderr = [];
    server.stderr.on('data', chunk => stderr.push(chunk));
    server.on('exit', code => {
      for (const request of requests.values()) {
        clearTimeout(request.timer);
        request.reject(new Error(`MCP exited (${code}); inspect ${join(runDir, 'mcp.log')}`));
      }
      requests.clear();
    });
    lines = createInterface({ input: server.stdout });
    lines.on('line', line => {
      let message;
      try { message = JSON.parse(line); } catch { return; }
      if (message.method === 'roots/list' && message.id !== undefined) {
        server.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: message.id,
          result: { roots: [{ uri: 'file:///workspace', name: 'workspace' }] } }) + '\n');
        return;
      }
      const request = requests.get(message.id);
      if (!request) return;
      requests.delete(message.id);
      clearTimeout(request.timer);
      if (message.error) request.reject(new Error(JSON.stringify(message.error)));
      else request.resolve(message.result);
    });
    const initialized = await rpc('initialize', { protocolVersion: '2024-11-05',
      capabilities: { roots: { listChanged: false } }, clientInfo: { name: 'rwa-dev-environment', version: '1.0' } });
    assert.equal(initialized.serverInfo.name, 'Playwright');
    server.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
    const { tools } = await rpc('tools/list');
    for (const name of ['browser_navigate', 'browser_evaluate', 'browser_take_screenshot', 'browser_start_video']) {
      assert(tools.some(tool => tool.name === name), `MCP tool missing: ${name}`);
    }
    await call('browser_navigate', { url: 'http://localhost:3000/signin' });
    await call('browser_wait_for', { text: 'Sign in' });
    await requirePage('/signin', ['[data-test="signin-username"]', '[data-test="signin-password"]', '[data-test="signin-submit"]']);
    if (mode === '--record') {
      recorder = spawnOwned('ffmpeg', ['-nostdin', '-loglevel', 'error', '-f', 'x11grab',
        '-draw_mouse', '1', '-framerate', '25', '-video_size', '1280x1024', '-i', display.includes('.') ? display : `${display}.0`,
        '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23', '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart', join(runDir, 'frontend.mp4')], { stdio: ['ignore', 'ignore', 'pipe'] });
      recorder.stderr.on('data', chunk => stderr.push(chunk));
      recorderDone = new Promise(resolve => recorder.once('exit', (code, signal) => resolve({ code, signal })));
    } else if (mode === '--native-video') {
      await call('browser_start_video', { filename: join(runDir, 'frontend.webm'), fps: 25, cursor: true });
      recordingStarted = true;
    }
    if (mode !== '--screenshot') {
      await call('browser_wait_for', { time: 2 });
      await call('browser_navigate', { url: 'http://localhost:3000/signup' });
      await call('browser_wait_for', { text: 'Sign Up' });
      await requirePage('/signup', ['[data-test="signup-title"]', '[data-test="signup-first-name"]']);
      await call('browser_wait_for', { time: 2 });
      await call('browser_navigate', { url: 'http://localhost:3000/signin' });
      await call('browser_wait_for', { text: 'Sign in' });
      await requirePage('/signin', ['[data-test="signin-submit"]']);
      await call('browser_wait_for', { time: 2 });
    }
    await call('browser_take_screenshot', { filename: join(runDir, 'frontend.png'), fullPage: true, type: 'png', scale: 'css' });
    if (recordingStarted) { await call('browser_stop_video'); recordingStarted = false; }
    await stopRecorder();
    await call('browser_close');
    if (mode !== '--screenshot') {
      const file = join(runDir, mode === '--record' ? 'frontend.mp4' : 'frontend.webm');
      const probe = spawnSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration:stream=codec_name,width,height', '-of', 'json', file], { encoding: 'utf8' });
      assert.equal(probe.status, 0, 'Video file could not be decoded');
      const metadata = JSON.parse(probe.stdout);
      assert(Number(metadata.format.duration) > 0 && metadata.streams.length, 'Video has no frames');
      writeFileSync(join(runDir, 'video-metadata.json'), JSON.stringify(metadata, null, 2));
    }
    writeFileSync(join(runDir, 'mcp.log'), Buffer.concat(stderr));
    console.log(`PASS: Playwright MCP ${mode.slice(2)}; artifacts: ${runDir}`);
  } finally {
    if (recordingStarted && server?.exitCode === null) {
      try { await call('browser_stop_video'); } catch {}
    }
    await stopRecorder();
    if (server?.exitCode === null) {
      try { await call('browser_close'); } catch {}
    }
    lines?.close();
    server?.stdin.end();
    await stopOwned(server);
    await stopOwned(ownedDisplay);
  }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
RWA_GENERATED_HELPER_5_END
rwa_write_helper 'xorg-rwa.conf' <<'RWA_GENERATED_HELPER_6_END'
Section "ServerFlags"
  Option "AutoAddDevices" "false"
  Option "AutoEnableDevices" "false"
  Option "DontVTSwitch" "true"
EndSection
Section "Device"
  Identifier "DummyDevice"
  Driver "dummy"
  VideoRam 256000
EndSection
Section "Monitor"
  Identifier "DummyMonitor"
  HorizSync 5.0-1000.0
  VertRefresh 5.0-200.0
  Modeline "1280x1024" 108.00 1280 1328 1440 1688 1024 1025 1028 1066 +HSync +VSync
EndSection
Section "Screen"
  Identifier "DummyScreen"
  Device "DummyDevice"
  Monitor "DummyMonitor"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "1280x1024"
  EndSubSection
EndSection
RWA_GENERATED_HELPER_6_END
rwa_write_helper 'rwa-browser-smoke.cjs' <<'RWA_GENERATED_HELPER_7_END'
process.argv[2] = '--screenshot';
require('/workspace/.tools/rwa-playwright.cjs');
RWA_GENERATED_HELPER_7_END
rwa_write_helper 'try-playwright-mcp.cjs' <<'RWA_GENERATED_HELPER_8_END'
const mode = process.argv[2];
process.argv[2] = mode === '--screen-video' ? '--record' : mode === '--video' ? '--native-video' : '--screenshot';
require('/workspace/.tools/rwa-playwright.cjs');
RWA_GENERATED_HELPER_8_END
cd "$rwa_repo_dir"
CYPRESS_INSTALL_BINARY=0 npm_config_registry=https://registry.npmjs.org yarn install --frozen-lockfile --non-interactive --registry https://registry.npmjs.org --network-concurrency 32 --network-timeout 60000
# Only create missing ignored authentication mocks; never overwrite a user's configuration or database.
bash /workspace/.tools/rwa-start.sh prepare
yarn types
# Same build command as build:ci, after safe mock preparation instead of its unconditional copy hook.
CYPRESS_COVERAGE=true yarn exec vite build
# Cypress is optional: a blocked desktop download must not prevent application/Playwright setup.
if [[ "${RWA_INSTALL_CYPRESS:-0}" == 1 ]]; then
  yarn cypress install
  rwa_cypress_version="$(node -p "require('cypress/package.json').version")"
  test -x "${CYPRESS_CACHE_FOLDER:-$HOME/.cache/Cypress}/$rwa_cypress_version/Cypress/Cypress" || {
    printf 'Cypress did not install. Apply download.cypress.io and cdn.cypress.io access, then retry.\n' >&2
    exit 1
  }
else
  printf 'Cypress desktop download skipped. Opt in later with RWA_INSTALL_CYPRESS=1.\n'
fi
printf 'Prepared Node %s, Yarn %s, and Playwright MCP %s.\n' "$(node --version)" "$(yarn --version)" "$(node /workspace/.tools/node_modules/@playwright/mcp/cli.js --version)"
printf 'Start the frontend and API using /workspace/.tools/rwa-start.sh in separate long-lived sessions.\n'
