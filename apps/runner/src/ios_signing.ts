import { spawn } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { AppStore, type AppStoreKey } from './appstore.js';

/**
 * Xcode signs the iPhone app for a Team, and `flutter build ipa` refuses to
 * archive without one ("requires a development team"). A fresh Flutter project
 * has none, so Ember finds the account's Team ID and writes it into the Xcode
 * project before every iPhone build.
 */

export const TEAM_ID = /^[A-Z0-9]{10}$/;

export type TeamSource = 'project' | 'saved' | 'appstore' | 'xcode';

type Fetch = typeof fetch;
type Run = (bin: string, args: string[]) => Promise<{ code: number; out: string }>;

/** The team the Xcode project already names, if any. */
export function projectTeam(pbxproj: string): string | null {
  const m = /DEVELOPMENT_TEAM = "?([A-Z0-9]{10})"?;/.exec(pbxproj);
  return m?.[1] ?? null;
}

/**
 * Writes DEVELOPMENT_TEAM into every build configuration that carries a Bundle
 * ID (the app, Debug/Release/Profile, and its test bundle). Returns the new
 * text, unchanged when a team is already there: someone chose it in Xcode.
 */
export function withDevelopmentTeam(pbxproj: string, teamId: string): string {
  if (!TEAM_ID.test(teamId) || projectTeam(pbxproj)) return pbxproj;
  return pbxproj.replace(/(\n([ \t]*)buildSettings = \{\n)((?:(?!\n[ \t]*\};)[\s\S])*?PRODUCT_BUNDLE_IDENTIFIER = )/g, (_all, head: string, indent: string, rest: string) => {
    return `${head}${indent}\tDEVELOPMENT_TEAM = ${teamId};\n${rest}`;
  });
}

/** Team IDs Xcode knows from the Apple accounts signed in there (paid ones only). */
export function parseXcodeTeams(defaultsOut: string): string[] {
  const teams: string[] = [];
  const blocks = defaultsOut.split(/\}\s*,?/);
  for (const b of blocks) {
    const id = /teamID = "?([A-Z0-9]{10})"?;/.exec(b)?.[1];
    if (!id || /isFreeProvisioningTeam = 1;/.test(b)) continue;
    if (!teams.includes(id)) teams.push(id);
  }
  return teams;
}

function runTool(bin: string, args: string[]): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const p = spawn(bin, args, { windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => p.kill(), 15_000);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out })));
  });
}

/**
 * The account's Team ID, from App Store Connect: every Bundle ID carries it as
 * `seedId`. The app's own Bundle ID first, any other one of the account after.
 */
export async function teamFromAppStore(key: AppStoreKey, bundleId: string, fetchImpl: Fetch = fetch): Promise<string | null> {
  const store = await AppStore.open(key, fetchImpl);
  const read = async (filter: string) => {
    const { data } = await store.call<{ data: Array<{ attributes?: { seedId?: string } }> }>(
      'GET',
      `/bundleIds?limit=1&fields[bundleIds]=seedId${filter}`,
      undefined,
      'Looking for the Team ID',
    );
    const id = `${data?.[0]?.attributes?.seedId ?? ''}`;
    return TEAM_ID.test(id) ? id : null;
  };
  return (bundleId ? await read(`&filter[identifier]=${encodeURIComponent(bundleId)}`) : null) ?? (await read(''));
}

export interface FindTeamInput {
  pbxproj: string;
  bundleId: string;
  savedTeamId?: string;
  key?: AppStoreKey | null;
  fetchImpl?: Fetch;
  run?: Run;
}

/**
 * Where the team comes from, first match wins: the Xcode project itself, the
 * one saved with the Apple key, App Store Connect, then the single paid team
 * Xcode is signed in with.
 */
export async function findTeamId(input: FindTeamInput): Promise<{ teamId: string; source: TeamSource } | null> {
  const inProject = projectTeam(input.pbxproj);
  if (inProject) return { teamId: inProject, source: 'project' };
  if (input.savedTeamId && TEAM_ID.test(input.savedTeamId)) return { teamId: input.savedTeamId, source: 'saved' };
  if (input.key) {
    const fromApple = await teamFromAppStore(input.key, input.bundleId, input.fetchImpl).catch(() => null);
    if (fromApple) return { teamId: fromApple, source: 'appstore' };
  }
  const res = await (input.run ?? runTool)('defaults', ['read', 'com.apple.dt.Xcode', 'IDEProvisioningTeamByIdentifier']);
  const teams = res.code === 0 ? parseXcodeTeams(res.out) : [];
  if (teams.length === 1) return { teamId: teams[0]!, source: 'xcode' };
  return null;
}

/**
 * Makes sure the project's Xcode file names a team before `flutter build ipa`.
 * Returns the team used, or null when none could be found.
 */
export async function ensureDevelopmentTeam(
  projectRoot: string,
  opts: Omit<FindTeamInput, 'pbxproj' | 'bundleId'> = {},
): Promise<{ teamId: string; source: TeamSource } | null> {
  const file = path.join(projectRoot, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
  const text = await readFile(file, 'utf8').catch(() => null);
  if (text === null) return null;
  const bundleId = [...text.matchAll(/PRODUCT_BUNDLE_IDENTIFIER = ([\w.-]+);/g)].map((m) => m[1]!).find((id) => !id.endsWith('.RunnerTests')) ?? '';
  const found = await findTeamId({ ...opts, pbxproj: text, bundleId });
  if (!found) return null;
  const next = withDevelopmentTeam(text, found.teamId);
  if (next !== text) await writeFile(file, next);
  return found;
}
