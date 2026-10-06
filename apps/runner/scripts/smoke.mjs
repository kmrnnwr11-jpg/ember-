// End-to-end smoke test against a running Runner (real `flutter create`).
// Usage: RUNNER_URL=http://localhost:8787 node scripts/smoke.mjs
import WebSocket from 'ws';

const base = process.env.RUNNER_URL ?? 'http://localhost:8787';
const name = `smoke_${Date.now().toString(36)}`;
const t0 = Date.now();
const log = (...a) => console.log(`[${((Date.now() - t0) / 1000).toFixed(1)}s]`, ...a);

async function http(method, path, token, body) {
  const res = await fetch(base + path, {
    method,
    headers: { ...(token && { authorization: `Bearer ${token}` }), ...(body && { 'content-type': 'application/json' }) },
    body: body && JSON.stringify(body),
  });
  const json = res.status === 204 ? null : await res.json();
  if (res.status >= 400) throw new Error(`${method} ${path} → ${res.status} ${JSON.stringify(json)}`);
  return json;
}

log('health', await http('GET', '/v1/health'));
const { token } = await http('POST', '/v1/auth/dev-login', null, { email: 'smoke@example.com' });
const { workspaces } = await http('GET', '/v1/workspaces', token);
const ws = workspaces[0] ?? (await http('POST', '/v1/workspaces', token, { name: 'default' }));
log('workspace', ws.id);

const sock = new WebSocket(`${base.replace(/^http/, 'ws')}/v1/ws?token=${token}`);
await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
let n = 0;
const pending = new Map();
const events = [];
sock.on('message', (d) => {
  const f = JSON.parse(d.toString());
  if (f.id && pending.has(f.id)) {
    pending.get(f.id)(f);
    pending.delete(f.id);
  } else events.push(f);
});
const req = (type, payload) =>
  new Promise((resolve, reject) => {
    const id = `s${++n}`;
    pending.set(id, (f) => (f.type === 'ok' ? resolve(f.payload) : reject(new Error(JSON.stringify(f.payload)))));
    sock.send(JSON.stringify({ id, type, payload }));
  });

const { project, job } = await http('POST', `/v1/workspaces/${ws.id}/projects`, token, { name });
log('creating', project.name, 'job', job.jobId);
let status;
while (true) {
  status = await http('GET', `/v1/jobs/${job.jobId}`, token);
  if (['succeeded', 'failed', 'cancelled'].includes(status.status)) break;
  await new Promise((r) => setTimeout(r, 1000));
}
log('create job', status.status, `(streamed ${events.filter((e) => e.type === 'job.log').length} log events)`);
if (status.status !== 'succeeded') {
  console.error(status.log.slice(-2000));
  process.exit(1);
}

const tree = await req('fs.list', { projectId: project.id, path: '' });
log('tree', tree.entries.map((e) => e.name).join(', '));
const main = await req('fs.read', { projectId: project.id, path: 'lib/main.dart' });
log('main.dart bytes', main.content.length);
await req('fs.watch', { projectId: project.id });
const edited = main.content.replace('Flutter Demo', 'Ember Smoke');
await req('fs.write', { projectId: project.id, path: 'lib/main.dart', content: edited, expectedMtimeMs: main.mtimeMs });
const again = await req('fs.read', { projectId: project.id, path: 'lib/main.dart' });
if (!again.content.includes('Ember Smoke')) throw new Error('write did not persist');
await new Promise((r) => setTimeout(r, 800));
log('persisted ✓, fs.changed events:', events.filter((e) => e.type === 'fs.changed').length);

// ---- Phase 2: real terminal ----
const waitFor = async (pred, ms = 30000) => {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const i = events.findIndex(pred);
    if (i >= 0) return events.splice(i, 1)[0];
    await new Promise((r) => setTimeout(r, 50));
  }
  throw new Error('timeout waiting for event');
};
const { ptyId } = await req('pty.open', { projectId: project.id, cols: 120, rows: 30 });
await req('pty.input', { ptyId, data: 'echo FC_$((6*7))_OK\r' });
let term = '';
const t1 = Date.now();
while (!/FC_42_OK|FC_\$\(\(6\*7\)\)_OK/.test(term) && Date.now() - t1 < 15000) {
  const f = await waitFor((e) => e.type === 'pty.output' && e.payload.ptyId === ptyId, 15000);
  term += f.payload.data;
}
log('terminal ✓ (shell output received)');
await req('pty.close', { ptyId });

// ---- Phase 2: real web build + preview ----
const started = await req('preview.start', { projectId: project.id, autoRebuild: true });
log('building web, job', started.job.jobId);
const ready = await waitFor((e) => (e.type === 'preview.ready' || e.type === 'preview.failed') && e.payload.projectId === project.id, 600000);
if (ready.type === 'preview.failed') {
  console.error((await http('GET', `/v1/jobs/${started.job.jobId}`, token)).log.slice(-3000));
  process.exit(1);
}
const previewUrl = base + ready.payload.path;
const page = await fetch(previewUrl);
const html = await page.text();
if (page.status !== 200 || !html.includes(`<base href="${ready.payload.path}">`)) throw new Error(`preview bad: ${page.status}`);
const boot = await fetch(previewUrl + 'flutter_bootstrap.js');
log(`preview ✓ ${previewUrl} (index ${html.length}B, bootstrap ${boot.status})`);

// rebuild on save
events.length = 0;
const cur = await req('fs.read', { projectId: project.id, path: 'lib/main.dart' });
await req('fs.write', { projectId: project.id, path: 'lib/main.dart', content: cur.content.replace('Ember Smoke', 'Rebuilt On Save') });
const building = await waitFor((e) => e.type === 'preview.building' && e.payload.projectId === project.id, 20000);
log('auto-rebuild triggered by save ✓ job', building.payload.jobId);
const rebuilt = await waitFor((e) => (e.type === 'preview.ready' || e.type === 'preview.failed') && e.payload.projectId === project.id, 600000);
const js = await (await fetch(previewUrl + 'main.dart.js')).text();
if (rebuilt.type !== 'preview.ready' || !js.includes('Rebuilt On Save')) throw new Error('rebuild did not pick up change');
log('rebuilt preview contains the edit ✓');
await req('preview.stop', { projectId: project.id });

if (process.env.KEEP) {
  log('KEEP set: project left in place', project.id);
  process.exit(0);
}
await http('DELETE', `/v1/projects/${project.id}`, token);
log('cleanup ✓');
sock.close();
