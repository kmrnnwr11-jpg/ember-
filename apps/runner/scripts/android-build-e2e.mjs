// Real signed Android build: node scripts/android-build-e2e.mjs <projectId> <apk|aab> [email]
import WebSocket from 'ws';

const [projectId, kind = 'aab', email = 'e2e@example.com'] = process.argv.slice(2);
const base = process.env.RUNNER_URL ?? 'http://localhost:8787';
const t0 = Date.now();
const log = (...a) => console.log(`[${((Date.now() - t0) / 1000).toFixed(0)}s]`, ...a);

const { token } = await (await fetch(`${base}/v1/auth/dev-login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email }) })).json();
const sock = new WebSocket(`${base.replace(/^http/, 'ws')}/v1/ws?token=${token}`);
await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
const frames = [];
sock.on('message', (d) => frames.push(JSON.parse(d.toString())));
sock.send(JSON.stringify({ id: 'b1', type: 'job.start', payload: { projectId, kind: kind === 'apk' ? 'build_apk' : 'build_aab' } }));

const until = async (pred, ms) => {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const f = frames.find(pred);
    if (f) return f;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error('timeout');
};
const started = await until((f) => f.id === 'b1', 60000);
if (started.type !== 'ok') throw new Error(JSON.stringify(started.payload));
log('job', started.payload.jobId);
const done = await until((f) => f.type === 'job.status' && f.payload.jobId === started.payload.jobId && ['succeeded', 'failed', 'cancelled'].includes(f.payload.status), 1800000);
log('status', done.payload.status);
if (done.payload.status !== 'succeeded') {
  const j = await (await fetch(`${base}/v1/jobs/${started.payload.jobId}`, { headers: { authorization: `Bearer ${token}` } })).json();
  console.error(j.log.slice(-4000));
  process.exit(1);
}
console.log('DONE');
sock.close();
