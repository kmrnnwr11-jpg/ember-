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
const edited = main.content.replace('Flutter Demo', 'FlutterCursor Smoke');
await req('fs.write', { projectId: project.id, path: 'lib/main.dart', content: edited, expectedMtimeMs: main.mtimeMs });
const again = await req('fs.read', { projectId: project.id, path: 'lib/main.dart' });
if (!again.content.includes('FlutterCursor Smoke')) throw new Error('write did not persist');
await new Promise((r) => setTimeout(r, 800));
log('persisted ✓, fs.changed events:', events.filter((e) => e.type === 'fs.changed').length);

await http('DELETE', `/v1/projects/${project.id}`, token);
log('cleanup ✓');
sock.close();
