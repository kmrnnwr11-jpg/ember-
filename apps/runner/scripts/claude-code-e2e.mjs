// Real end-to-end "Crea App" with Claude Code: create project → agent builds → web preview.
// Usage: RUNNER_URL=http://localhost:8787 node scripts/claude-code-e2e.mjs "<prompt>"
import WebSocket from 'ws';

const base = process.env.RUNNER_URL ?? 'http://localhost:8787';
const prompt = process.argv[2] ?? 'App contatore di bicchieri d\'acqua bevuti oggi, con obiettivo giornaliero modificabile e storico dei giorni passati salvato sul telefono. Interfaccia in italiano, colori azzurri.';
const t0 = Date.now();
const log = (...a) => console.log(`[${((Date.now() - t0) / 1000).toFixed(0)}s]`, ...a);

const http = async (method, path, token, body) => {
  const res = await fetch(base + path, { method, headers: { ...(token && { authorization: `Bearer ${token}` }), ...(body && { 'content-type': 'application/json' }) }, body: body && JSON.stringify(body) });
  const json = res.status === 204 ? null : await res.json();
  if (res.status >= 400) throw new Error(`${method} ${path} → ${res.status} ${JSON.stringify(json)}`);
  return json;
};

const health = await http('GET', '/v1/health');
log('engines', health.engines);
if (!health.engines?.claudeCode) throw new Error('Claude Code not available on Runner');
const { token } = await http('POST', '/v1/auth/dev-login', null, { email: 'e2e@example.com' });
const { workspaces } = await http('GET', '/v1/workspaces', token);
const ws = workspaces[0] ?? (await http('POST', '/v1/workspaces', token, { name: 'default' }));

const sock = new WebSocket(`${base.replace(/^http/, 'ws')}/v1/ws?token=${token}`);
await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
let n = 0;
const pending = new Map();
const listeners = new Set();
sock.on('message', (d) => {
  const f = JSON.parse(d.toString());
  if (f.id && pending.has(f.id)) { pending.get(f.id)(f); pending.delete(f.id); } else listeners.forEach((l) => l(f));
});
const req = (type, payload) => new Promise((resolve, reject) => {
  const id = `e${++n}`;
  pending.set(id, (f) => (f.type === 'ok' ? resolve(f.payload) : reject(new Error(JSON.stringify(f.payload)))));
  sock.send(JSON.stringify({ id, type, payload }));
});
const waitFor = (pred, ms) => new Promise((resolve, reject) => {
  const t = setTimeout(() => (listeners.delete(fn), reject(new Error('timeout'))), ms);
  const fn = (f) => { if (pred(f)) { clearTimeout(t); listeners.delete(fn); resolve(f); } };
  listeners.add(fn);
});

const name = `acqua_e2e_${Date.now().toString(36).slice(-4)}`;
const { project, job } = await http('POST', `/v1/workspaces/${ws.id}/projects`, token, { name });
await waitFor((f) => f.type === 'job.status' && f.payload.jobId === job.jobId && ['succeeded', 'failed'].includes(f.payload.status), 300000);
log('project created', project.id, name);

listeners.add((f) => {
  if (f.type !== 'agent.event') return;
  const e = f.payload.event;
  if (e.kind === 'tool') log('  🔧', e.name, e.summary);
  else if (e.kind === 'text') log('  💬', e.text.slice(0, 160).replace(/\n/g, ' '));
  else if (e.kind === 'result') log('  ✅ result ok=', e.ok, 'turns=', e.turns, 'cost≈$', e.costUsd);
  else if (e.kind === 'error') log('  ⚠️', e.message.slice(0, 300));
});
const run = await req('agent.start', { projectId: project.id, engine: 'claude-code', prompt });
log('agent started', run.id);
const status = await waitFor((f) => f.type === 'agent.status' && f.payload.id === run.id && f.payload.status !== 'running', 3600000);
log('agent finished:', status.payload.status);
if (status.payload.status !== 'succeeded') process.exit(1);

await req('preview.start', { projectId: project.id, autoRebuild: false });
const ready = await waitFor((f) => (f.type === 'preview.ready' || f.type === 'preview.failed') && f.payload.projectId === project.id, 900000);
if (ready.type === 'preview.failed') {
  console.error((await http('GET', `/v1/jobs/${ready.payload.jobId}`, token)).log.slice(-3000));
  process.exit(1);
}
const url = base + ready.payload.path;
const page = await fetch(url);
log(`PREVIEW ${page.status} ${url}`);
console.log(JSON.stringify({ projectId: project.id, url }));
sock.close();
