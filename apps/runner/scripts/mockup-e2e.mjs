// Real mockup generation via Claude Code (agent.complete), same prompts as the IDE.
// Usage: node scripts/mockup-e2e.mjs <outFile.html> "<app description>" [styleIndex]
import { readFileSync, writeFileSync } from 'node:fs';
import WebSocket from 'ws';

const [out = 'mockup.html', description = "App di ricette con foto, lista della spesa e timer di cottura", styleIdx = '1'] = process.argv.slice(2);
const base = process.env.RUNNER_URL ?? 'http://localhost:8787';
const dart = readFileSync(new URL('../../ide/lib/features/mockups/mockup_controller.dart', import.meta.url), 'utf8');
const system = /const mockupSystemPrompt = '''\n([\s\S]*?)''';/.exec(dart)[1];
const styles = [...dart.matchAll(/MockupStyle\('(\w+)', '([^']+)', '([^']+)'\)/g)].map((m) => ({ id: m[1], name: m[2], direction: m[3] }));
const style = styles[Number(styleIdx)];
const prompt = `App description:\n${description}\n\nVisual style: ${style.name} — ${style.direction}\n`;

const { token } = await (await fetch(`${base}/v1/auth/dev-login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email: 'e2e@example.com' }) })).json();
const sock = new WebSocket(`${base.replace(/^http/, 'ws')}/v1/ws?token=${token}`);
await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
const t0 = Date.now();
const res = await new Promise((resolve) => {
  sock.on('message', (d) => {
    const f = JSON.parse(d.toString());
    if (f.id === 'm1') resolve(f);
  });
  sock.send(JSON.stringify({ id: 'm1', type: 'agent.complete', payload: { system, prompt, quality: 'fast' } }));
});
console.log(`style=${style.name} status=${res.type} time=${((Date.now() - t0) / 1000).toFixed(0)}s cost=${res.payload.costUsd}`);
if (res.type !== 'ok') {
  console.error(res.payload);
  process.exit(1);
}
const text = res.payload.text;
console.log(text.split('\n')[0].slice(0, 300));
const html = /```html[^\n]*\n([\s\S]*?)\n```/.exec(text)?.[1];
if (!html) throw new Error('no html block');
writeFileSync(out, html);
console.log(`html ${html.length} bytes → ${out}`);
sock.close();
