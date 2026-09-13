// Real terminal check: shells + AI CLIs through the Runner PTY.
// Usage: node scripts/terminal-cli-e2e.mjs <projectId> [email]
import WebSocket from 'ws';

const [projectId, email = 'e2e@example.com'] = process.argv.slice(2);
const base = process.env.RUNNER_URL ?? 'http://localhost:8787';
const health = await (await fetch(`${base}/v1/health`)).json();
console.log('shells', health.shells, 'cli', health.cli);
const { token } = await (await fetch(`${base}/v1/auth/dev-login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email }) })).json();
const sock = new WebSocket(`${base.replace(/^http/, 'ws')}/v1/ws?token=${token}`);
await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
const output = new Map();
let n = 0;
const pending = new Map();
sock.on('message', (d) => {
  const f = JSON.parse(d.toString());
  if (f.id && pending.has(f.id)) return pending.get(f.id)(f);
  if (f.type === 'pty.output') output.set(f.payload.ptyId, (output.get(f.payload.ptyId) ?? '') + f.payload.data);
});
const req = (type, payload) => new Promise((resolve, reject) => {
  const id = `t${++n}`;
  pending.set(id, (f) => (f.type === 'ok' ? resolve(f.payload) : reject(new Error(JSON.stringify(f.payload)))));
  sock.send(JSON.stringify({ id, type, payload }));
});
const strip = (s) => s.replace(/\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|\x1b[=>]/g, '');
const waitText = async (ptyId, re, ms) => {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    if (re.test(strip(output.get(ptyId) ?? ''))) return true;
    await new Promise((r) => setTimeout(r, 200));
  }
  return false;
};

const checks = [
  ['cmd', 'claude --version', /\d+\.\d+\.\d+ \(Claude Code\)/],
  ['cmd', 'codex --version', /codex-cli \d|codex \d/i],
  ['cmd', 'gemini --version', />\s*gemini --version\s+\d+\.\d+\.\d+/],
  ['powershell', 'flutter --version', /Flutter \d+\.\d+/],
];
for (const [shell, command, re] of checks) {
  const { ptyId } = await req('pty.open', { projectId, shell, cols: 120, rows: 30, command });
  const ok = await waitText(ptyId, re, 60000);
  const tail = strip(output.get(ptyId) ?? '').trim().split(/\r?\n/).filter(Boolean).slice(-2).join(' | ');
  console.log(`${ok ? 'OK ' : 'FAIL'} [${shell}] ${command} → ${tail.slice(0, 160)}`);
  await req('pty.close', { ptyId });
}

// Interactive Claude Code TUI starts and renders.
const { ptyId } = await req('pty.open', { projectId, shell: 'cmd', cols: 100, rows: 30, command: 'claude' });
const tuiOk = await waitText(ptyId, /trust|Welcome|Claude Code|>\s|\? for shortcuts|Do you/i, 40000);
console.log(`${tuiOk ? 'OK ' : 'FAIL'} interactive claude TUI → ${strip(output.get(ptyId) ?? '').replace(/\s+/g, ' ').slice(-200)}`);
await req('pty.input', { ptyId, data: '\x03' });
await new Promise((r) => setTimeout(r, 500));
await req('pty.input', { ptyId, data: '\x03' });
await req('pty.close', { ptyId });
sock.close();
