import { describe, expect, it } from 'vitest';
import { AbortedError, Lanes } from './scheduler.js';

const tick = (ms = 5) => new Promise((r) => setTimeout(r, ms));

describe('Lanes', () => {
  it('never runs more than the limit of a lane at once', async () => {
    const lanes = new Lanes({ build: 2 });
    let now = 0;
    let peak = 0;
    const job = () =>
      lanes.run('build', 0, async () => {
        peak = Math.max(peak, ++now);
        await tick(10);
        now--;
      });
    await Promise.all(Array.from({ length: 8 }, job));
    expect(peak).toBe(2);
  });

  it('serves lower priority numbers first, then arrival order', async () => {
    const lanes = new Lanes({ x: 1 });
    const order: string[] = [];
    const first = lanes.run('x', 0, async () => {
      await tick(15);
    });
    const late = lanes.run('x', 5, async () => void order.push('late'));
    const urgent = lanes.run('x', 1, async () => void order.push('urgent'));
    const same = lanes.run('x', 5, async () => void order.push('same'));
    await Promise.all([first, late, urgent, same]);
    expect(order).toEqual(['urgent', 'late', 'same']);
  });

  it('keeps lanes independent of each other', async () => {
    const lanes = new Lanes({ a: 1, b: 1 });
    const seen: string[] = [];
    const a = lanes.run('a', 0, async () => {
      await tick(20);
      seen.push('a');
    });
    const b = lanes.run('b', 0, async () => void seen.push('b'));
    await Promise.all([a, b]);
    expect(seen).toEqual(['b', 'a']);
  });

  it('holds a paused lane and lets it go on time', async () => {
    const lanes = new Lanes({ agent: 2 });
    lanes.pauseLane('agent', 60);
    expect(lanes.isLanePaused('agent')).toBe(true);
    const started = Date.now();
    await lanes.run('agent', 0, async () => undefined);
    expect(Date.now() - started).toBeGreaterThanOrEqual(50);
    expect(lanes.isLanePaused('agent')).toBe(false);
  });

  it('stops starting work when everything is paused, without interrupting what runs', async () => {
    const lanes = new Lanes({ x: 2 });
    let finished = false;
    const running = lanes.run('x', 0, async () => {
      await tick(20);
      finished = true;
    });
    await tick(2);
    lanes.setPaused(true);
    let ran = false;
    const waiting = lanes.run('x', 0, async () => void (ran = true));
    await running;
    await tick(10);
    expect(finished).toBe(true);
    expect(ran).toBe(false);
    lanes.setPaused(false);
    await waiting;
    expect(ran).toBe(true);
  });

  it('drops an aborted request from the line', async () => {
    const lanes = new Lanes({ x: 1 });
    const hold = lanes.run('x', 0, () => tick(30));
    const ctrl = new AbortController();
    let ran = false;
    const waiting = lanes.run('x', 0, async () => void (ran = true), ctrl.signal);
    ctrl.abort();
    await expect(waiting).rejects.toBeInstanceOf(AbortedError);
    await hold;
    expect(ran).toBe(false);
    expect(lanes.snapshot().x?.waiting).toBe(0);
  });

  it('reports what each lane is doing', async () => {
    const lanes = new Lanes({ build: 1 });
    const a = lanes.run('build', 0, () => tick(20));
    const b = lanes.run('build', 0, () => tick(1));
    await tick(2);
    expect(lanes.snapshot().build).toMatchObject({ limit: 1, running: 1, waiting: 1 });
    await Promise.all([a, b]);
    expect(lanes.snapshot().build).toMatchObject({ running: 0, waiting: 0 });
  });

  it('allows one at a time in a lane nobody configured', async () => {
    expect(new Lanes().limitOf('whatever')).toBe(1);
  });
});
