import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Factory } from './engine.js';
import { assignEngines } from './engines.js';
import { MAX_IDEAS } from './ideas.js';
import { NoAi, type FactoryService } from './service.js';
import { planApps } from './supervisor.js';
import { FACTORY_ENGINES, GOALS, STAGES, type FactoryApp, type FactoryEngine, type Idea } from './types.js';

const LIST_LOG_LINES = 8;

/** One app as the list shows it: no brief, a short log. */
export function viewApp(app: FactoryApp, full = false) {
  const { log, brief, ...rest } = app;
  return { ...rest, log: full ? log : log.slice(-LIST_LOG_LINES), ...(full ? { brief } : {}) };
}

const engineWeights = z.partialRecord(z.enum(FACTORY_ENGINES), z.number().min(0).max(100));

const ideaSchema = z.object({
  name: z.string().trim().min(1).max(40),
  summary: z.string().trim().min(1).max(1000),
  brief: z.string().max(4000).optional(),
  size: z.enum(['small', 'big']).optional(),
  category: z.string().max(40).optional(),
  engine: z.enum(FACTORY_ENGINES).optional(),
});

const recipeSchema = z
  .object({
    engines: engineWeights,
    quality: z.enum(['fast', 'best']),
    logoBy: z.enum(['codex', 'claude_code', 'gemini_runner', 'auto']),
    goal: z.enum(GOALS),
    languages: z.array(z.string().min(2).max(10)).min(1).max(100),
    maxAttempts: z.number().int().min(1).max(5),
    extra: z.string().max(2000),
  })
  .partial();

const settingsSchema = z.object({
  lanes: z.record(z.string().regex(/^[a-z:-]{2,30}$/), z.number().int().min(0).max(32)).optional(),
  maxInFlight: z.number().int().min(1).max(100).optional(),
  dailyStoreCap: z.object({ play: z.number().int().min(0).max(500).optional(), appstore: z.number().int().min(0).max(500).optional() }).optional(),
  minFreeDiskGb: z.number().min(0).max(500).optional(),
});

const stageEnum = z.enum(STAGES);

function stateView(factory: Factory, simulated: boolean) {
  return {
    rev: factory.rev,
    paused: factory.paused,
    interrupted: factory.interrupted,
    lowDisk: factory.isLowDisk,
    simulated,
    summary: factory.summary(),
    settings: factory.settings,
    uploads: factory.uploadsToday(),
    lanes: factory.lanes.snapshot(),
    batches: factory.batches(),
    apps: factory.apps().map((a) => viewApp(a)),
    needsYou: factory.needsYou(),
  };
}

/** The `/v1/factory` routes. Call inside the authenticated scope. */
export function registerFactoryRoutes(r: FastifyInstance, service: FactoryService): void {
  const simulated = service.deps.simulated;

  /** Weights for a batch: what the owner chose, else every engine that is connected. */
  const weightsFor = async (ownerId: string, given?: Partial<Record<FactoryEngine, number>>) => {
    if (given && Object.values(given).some((w) => (w ?? 0) > 0)) return given;
    const connected = await service.connectedEngines(ownerId);
    return Object.fromEntries((connected.length ? connected : ['claude-code' as const]).map((e) => [e, 1])) as Partial<Record<FactoryEngine, number>>;
  };

  r.get('/v1/factory', async (req) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    const since = Number((req.query as { rev?: string }).rev);
    if (Number.isFinite(since) && since === factory.rev) return { unchanged: true, rev: factory.rev };
    return stateView(factory, simulated);
  });

  r.get('/v1/factory/apps/:id', async (req, reply) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    const app = factory.app((req.params as { id: string }).id);
    if (!app) return reply.status(404).send({ code: 'not_found', message: 'app not found' });
    return viewApp(app, true);
  });

  r.get('/v1/factory/connections', async (req) => service.connections(req.user.id));

  r.post('/v1/factory/plan', async (req, reply) => {
    const body = z
      .object({ text: z.string().min(1).max(400_000), count: z.number().int().min(1).max(MAX_IDEAS).optional(), engines: engineWeights.optional() })
      .parse(req.body);
    try {
      const plan = await planApps(body.text, (system, prompt) => service.deps.complete(req.user.id, system, prompt), { count: body.count });
      const weights = await weightsFor(req.user.id, body.engines);
      const engines = assignEngines(plan.apps.map((a) => a.size ?? 'small'), weights);
      return {
        apps: plan.apps.map((a, i) => ({ ...a, engine: engines[i] })),
        dropped: plan.dropped,
        warnings: plan.withoutAi ? ['no_ai'] : [],
        source: plan.source,
      };
    } catch (e) {
      if (e instanceof NoAi) return reply.status(502).send({ code: 'no_ai', message: e.message });
      return reply.status(502).send({ code: 'plan_failed', message: (e as Error).message.slice(0, 400) });
    }
  });

  r.post('/v1/factory/batches', async (req, reply) => {
    const body = z
      .object({ name: z.string().trim().min(1).max(60), apps: z.array(ideaSchema).min(1).max(MAX_IDEAS), recipe: recipeSchema.optional(), start: z.boolean().default(true) })
      .parse(req.body);
    const factory = await service.forOwner(req.user.id, req.user.email);
    const engines = await weightsFor(req.user.id, body.recipe?.engines);
    const ideas: Idea[] = body.apps;
    const batch = factory.addBatch({ name: body.name, ideas, recipe: { ...body.recipe, engines } });
    return reply.status(201).send({ batchId: batch.id, rev: factory.rev });
  });

  r.post('/v1/factory/pause', async (req) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    factory.setPaused(true);
    return { paused: true, rev: factory.rev };
  });

  r.post('/v1/factory/resume', async (req) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    factory.setPaused(false);
    return { paused: false, rev: factory.rev };
  });

  r.patch('/v1/factory/settings', async (req) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    factory.updateSettings(settingsSchema.parse(req.body ?? {}));
    return stateView(factory, simulated);
  });

  const appCommand = (path: string, run: (factory: Factory, id: string, body: Record<string, unknown>, query: Record<string, string>) => Promise<boolean> | boolean) =>
    r.route({
      method: path.startsWith('DELETE') ? 'DELETE' : 'POST',
      url: `/v1/factory/apps/:id${path.startsWith('DELETE') ? '' : `/${path}`}`,
      handler: async (req, reply) => {
        const factory = await service.forOwner(req.user.id, req.user.email);
        const { id } = req.params as { id: string };
        if (!factory.app(id)) return reply.status(404).send({ code: 'not_found', message: 'app not found' });
        const ok = await run(factory, id, (req.body ?? {}) as Record<string, unknown>, (req.query ?? {}) as Record<string, string>);
        return { ok, rev: factory.rev };
      },
    });

  appCommand('retry', (f, id, body) => f.retryApp(id, body.from === undefined ? undefined : stageEnum.parse(body.from)));
  appCommand('cancel', (f, id) => f.cancelApp(id));
  appCommand('resolve', (f, id, body) => {
    const b = z.object({ needId: z.string().max(20).optional(), skip: z.boolean().optional() }).parse(body);
    return f.resolveNeed(id, b.needId ?? null, { skip: b.skip });
  });
  appCommand('DELETE', (f, id, _body, query) => f.removeApp(id, query.project === 'true'));

  r.post('/v1/factory/apps/bulk', async (req) => {
    const body = z.object({ ids: z.array(z.string().max(20)).min(1).max(200), action: z.enum(['retry', 'cancel', 'delete']) }).parse(req.body);
    const factory = await service.forOwner(req.user.id, req.user.email);
    let done = 0;
    for (const id of body.ids) {
      const ok = body.action === 'retry' ? factory.retryApp(id) : body.action === 'cancel' ? factory.cancelApp(id) : await factory.removeApp(id, false);
      if (ok) done++;
    }
    return { done, rev: factory.rev };
  });

  r.post('/v1/factory/batches/:id/retry-failed', async (req, reply) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    const { id } = req.params as { id: string };
    if (!factory.batch(id)) return reply.status(404).send({ code: 'not_found', message: 'batch not found' });
    return { done: factory.retryFailed(id), rev: factory.rev };
  });

  r.post('/v1/factory/batches/:id/cancel', async (req, reply) => {
    const factory = await service.forOwner(req.user.id, req.user.email);
    const { id } = req.params as { id: string };
    if (!factory.batch(id)) return reply.status(404).send({ code: 'not_found', message: 'batch not found' });
    return { done: factory.cancelBatch(id), rev: factory.rev };
  });
}
