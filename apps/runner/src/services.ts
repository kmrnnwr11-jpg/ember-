import { existsSync } from 'node:fs';
import path from 'node:path';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { nanoid } from 'nanoid';
import type { Config } from './config.js';
import { FsError, ProjectFs } from './fs.js';
import type { Job, JobKind, JobManager } from './jobs.js';
import { validateProjectName } from './paths.js';
import { claimBundleId, claimPackageName } from './publish_prep.js';
import { readAppleCreds, readAppleKey, rememberTeamId } from './apple_creds.js';
import { ensureDevelopmentTeam } from './ios_signing.js';
import { bumpBuildNumber, lastAppStoreBuildNumber, lastPublishedBuildNumber, lastPublishedVersionCode, prepareSignedBuild } from './signing.js';
import { pinProjectSdk, tuneGradle } from './sdk_pins.js';
import type { ProjectRow, Store, WorkspaceRow } from './store.js';
import type { WorkspaceDriver } from './workspaces/driver.js';

export class NotFound extends FsError {
  constructor(what: string) {
    super('not_found', `${what} not found`);
  }
}

const PROJECTS_DIR = 'projects';
export const TEMPLATES = ['empty'] as const;

/** Fixed command lines per job kind: clients never send raw commands here. */
const JOB_COMMANDS: Partial<Record<JobKind, string[]>> = {
  pub_get: ['pub', 'get'],
  analyze: ['analyze', '--no-fatal-infos', '--no-fatal-warnings'],
  test: ['test', '--reporter', 'expanded'],
  build_apk: ['build', 'apk', '--release'],
  // For trying the app on a phone: no shrinking, no obfuscation, minutes faster.
  build_apk_fast: ['build', 'apk', '--debug'],
  build_aab: ['build', 'appbundle', '--release'],
  // iPhone: only a Mac can make this file, so it is refused elsewhere (see startJob).
  build_ipa: ['build', 'ipa', '--release'],
  launcher_icons: ['pub', 'run', 'flutter_launcher_icons'],
};

/** Downloadable Android artifacts, relative to the project root. */
export const ARTIFACTS: Record<string, { rel: string; contentType: string }> = {
  'app-release.apk': { rel: 'build/app/outputs/flutter-apk/app-release.apk', contentType: 'application/vnd.android.package-archive' },
  'app-debug.apk': { rel: 'build/app/outputs/flutter-apk/app-debug.apk', contentType: 'application/vnd.android.package-archive' },
  'app-release.aab': { rel: 'build/app/outputs/bundle/release/app-release.aab', contentType: 'application/octet-stream' },
};

export type SignedBuildPreparer = typeof prepareSignedBuild;

export class Services {
  constructor(
    readonly cfg: Config,
    readonly store: Store,
    readonly driver: WorkspaceDriver,
    readonly jobs: JobManager,
    private readonly prepareSigned: SignedBuildPreparer = prepareSignedBuild,
  ) {
    jobs.on('status', (job) => void this.onJobStatus(job));
  }

  // ---- workspaces ----

  listWorkspaces(ownerId: string) {
    return this.store.listWorkspaces(ownerId);
  }

  async createWorkspace(ownerId: string, name: string): Promise<WorkspaceRow> {
    const trimmed = name.trim().slice(0, 64) || 'default';
    const now = new Date().toISOString();
    const row: WorkspaceRow = {
      id: nanoid(12).toLowerCase().replace(/[^a-z0-9]/g, 'x'),
      ownerId,
      name: trimmed,
      status: 'starting',
      containerId: null,
      createdAt: now,
      lastActiveAt: now,
    };
    await this.store.insertWorkspace(row);
    try {
      const { containerId } = await this.driver.ensure(row.id);
      await this.store.updateWorkspace(row.id, { status: 'running', containerId });
      return { ...row, status: 'running', containerId };
    } catch (e) {
      await this.store.updateWorkspace(row.id, { status: 'error' });
      throw e;
    }
  }

  async ownedWorkspace(ownerId: string, workspaceId: string): Promise<WorkspaceRow> {
    const ws = await this.store.getWorkspace(workspaceId);
    if (!ws || ws.ownerId !== ownerId) throw new NotFound('workspace');
    return ws;
  }

  // ---- projects ----

  async listProjects(ownerId: string, workspaceId: string) {
    await this.ownedWorkspace(ownerId, workspaceId);
    return this.store.listProjects(workspaceId);
  }

  async ownedProject(ownerId: string, projectId: string): Promise<{ project: ProjectRow; workspace: WorkspaceRow }> {
    const project = await this.store.getProject(projectId);
    if (!project) throw new NotFound('project');
    const workspace = await this.ownedWorkspace(ownerId, project.workspaceId).catch(() => {
      throw new NotFound('project');
    });
    return { project, workspace };
  }

  projectRoot(project: ProjectRow): string {
    return path.join(this.driver.hostRoot(project.workspaceId), PROJECTS_DIR, project.name);
  }

  async projectFs(ownerId: string, projectId: string): Promise<{ fs: ProjectFs; project: ProjectRow }> {
    const { project } = await this.ownedProject(ownerId, projectId);
    if (project.status !== 'ready') throw new FsError('not_ready', `project is ${project.status}`);
    return { fs: new ProjectFs(this.projectRoot(project), this.cfg.MAX_WS_FILE_BYTES), project };
  }

  async createProject(
    ownerId: string,
    workspaceId: string,
    rawName: unknown,
    template: unknown = 'empty',
  ): Promise<{ project: ProjectRow; job: Job }> {
    await this.ownedWorkspace(ownerId, workspaceId);
    const name = validateProjectName(rawName);
    const tpl = typeof template === 'string' && (TEMPLATES as readonly string[]).includes(template) ? template : null;
    if (!tpl) throw new FsError('bad_template', `unknown template; available: ${TEMPLATES.join(', ')}`);
    const existing = await this.store.listProjects(workspaceId);
    if (existing.some((p) => p.name === name)) throw new FsError('exists', `project ${name} already exists`);

    const project: ProjectRow = {
      id: nanoid(12),
      workspaceId,
      name,
      template: tpl,
      status: 'creating',
      lastModel: null,
      createdAt: new Date().toISOString(),
    };
    await this.store.insertProject(project);
    await mkdir(path.join(this.driver.hostRoot(workspaceId), PROJECTS_DIR), { recursive: true });
    const job = this.jobs.enqueue({
      kind: 'create',
      ownerId,
      workspaceId,
      projectId: project.id,
      cwd: PROJECTS_DIR,
      cmd: 'flutter',
      args: ['create', '--org', 'dev.fluttercursor.app', '--project-name', name, '--platforms', 'web,android,ios', name],
    });
    return { project, job };
  }

  /**
   * Registers an app whose files another computer made (restored from GitHub).
   * Returns the row and the folder the files must be written into.
   */
  async importProject(ownerId: string, workspaceId: string, rawName: unknown): Promise<{ project: ProjectRow; root: string }> {
    await this.ownedWorkspace(ownerId, workspaceId);
    const name = validateProjectName(rawName);
    const existing = await this.store.listProjects(workspaceId);
    if (existing.some((p) => p.name === name)) throw new FsError('exists', `project ${name} already exists`);
    const project: ProjectRow = {
      id: nanoid(12),
      workspaceId,
      name,
      template: 'empty',
      status: 'ready',
      lastModel: null,
      createdAt: new Date().toISOString(),
    };
    await this.store.insertProject(project);
    await mkdir(path.join(this.driver.hostRoot(workspaceId), PROJECTS_DIR), { recursive: true });
    return { project, root: this.projectRoot(project) };
  }

  async deleteProject(ownerId: string, projectId: string) {
    const { project } = await this.ownedProject(ownerId, projectId);
    const { rm } = await import('node:fs/promises');
    await rm(this.projectRoot(project), { recursive: true, force: true });
    await this.store.deleteProject(project.id);
  }

  async startJob(ownerId: string, projectId: string, kind: unknown): Promise<Job> {
    const { project } = await this.projectFs(ownerId, projectId);
    const args = typeof kind === 'string' ? JOB_COMMANDS[kind as JobKind] : undefined;
    if (!args) throw new FsError('bad_job', `unsupported job kind; available: ${Object.keys(JOB_COMMANDS).join(', ')}`);
    // Apple only allows building for iPhone on a Mac: say so instead of failing deep in Xcode.
    if (kind === 'build_ipa' && process.platform !== 'darwin') {
      throw new FsError('needs_mac', 'Only a Mac can build the iPhone app. Open Ember on your Mac, take this app back from GitHub, and build it there.');
    }
    // Keep AI-chosen dependencies compatible with this Runner's Flutter SDK.
    await pinProjectSdk(this.projectRoot(project));
    await tuneGradle(this.projectRoot(project));
    let env: Record<string, string> | undefined;
    if (kind === 'build_apk' || kind === 'build_aab') {
      // The package name is forever once Google has it: swap the placeholder for
      // the app's real name before the first file that could reach the store.
      const root = this.projectRoot(project);
      const listing = JSON.parse(await readFile(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '{}')) as { title?: string };
      const manifest = await readFile(path.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), 'utf8').catch(() => '');
      const appName = listing.title || /android:label\s*=\s*"([^"@]+)"/.exec(manifest)?.[1] || '';
      await claimPackageName(root, {
        appName,
        prefix: this.cfg.PACKAGE_PREFIX,
        alreadyPublished: (await lastPublishedVersionCode(root)) > 0,
      }).catch(() => null);
      // Signed release for Play Console: upload key + bumped versionCode.
      try {
        env = (await this.prepareSigned(this.cfg, project.id, this.projectRoot(project), project.name)).env;
      } catch (e) {
        throw new FsError('signing_failed', (e as Error).message);
      }
    }
    if (kind === 'build_ipa') {
      // The iPhone app carries the same name as the Android one, and its build
      // number must rise on every upload, exactly like Google's version code.
      const root = this.projectRoot(project);
      const gradle = await readFile(path.join(root, 'android', 'app', 'build.gradle.kts'), 'utf8').catch(() => '');
      const applicationId = /applicationId\s*=\s*"([^"]+)"/.exec(gradle)?.[1] ?? '';
      if (applicationId && !applicationId.startsWith('dev.fluttercursor.app.')) {
        // Only Apple fixes the Bundle ID for good: a version already on Google
        // Play must not keep the placeholder on the iPhone.
        await claimBundleId(root, applicationId, (await lastAppStoreBuildNumber(root)) > 0).catch(() => null);
      }
      // Xcode will not archive without a Team: write the account's one in.
      const creds = await readAppleCreds().catch(() => null);
      const team = await ensureDevelopmentTeam(root, {
        savedTeamId: creds?.teamId,
        key: await readAppleKey().catch(() => null),
      }).catch(() => null);
      if (team && team.source !== 'saved') await rememberTeamId(team.teamId).catch(() => {});
      if (!team && existsSync(path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'))) {
        throw new FsError(
          'no_team',
          'Non trovo il Team Apple per firmare l’app iPhone. Scrivi il Team ID (10 caratteri, lo vedi su developer.apple.com → Membership) nella scheda "Send to the App Store", oppure salva lì la chiave App Store Connect: Ember lo legge da Apple.',
        );
      }
      const pubspecPath = path.join(root, 'pubspec.yaml');
      const pubspec = await readFile(pubspecPath, 'utf8').catch(() => '');
      if (pubspec) {
        const { text } = bumpBuildNumber(pubspec, await lastPublishedBuildNumber(root));
        await writeFile(pubspecPath, text);
      }
    }
    return this.jobs.enqueue({
      kind: kind as JobKind,
      ownerId,
      workspaceId: project.workspaceId,
      projectId: project.id,
      cwd: `${PROJECTS_DIR}/${project.name}`,
      cmd: 'flutter',
      args,
      env,
    });
  }

  ownedJob(ownerId: string, jobId: string): Job {
    const job = this.jobs.get(jobId);
    if (!job || job.ownerId !== ownerId) throw new NotFound('job');
    return job;
  }

  private async onJobStatus(job: Job) {
    if (job.kind !== 'create' || !job.projectId) return;
    if (job.status === 'succeeded') await this.store.updateProject(job.projectId, { status: 'ready' });
    else if (job.status === 'failed' || job.status === 'cancelled') await this.store.updateProject(job.projectId, { status: 'error' });
  }
}
