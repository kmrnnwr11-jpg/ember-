import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { findTeamId, parseXcodeTeams, projectTeam, withDevelopmentTeam } from './ios_signing.js';

const PBX = readFileSync(new URL('./fixtures/flutter_project.pbxproj', import.meta.url), 'utf8');

const XCODE_DEFAULTS = `{
    "67FEABDB-F4F4-4B3B-A0E5-14BE2938218D" =     (
                {
            isFreeProvisioningTeam = 0;
            teamID = ABCDE12345;
            teamName = "Example Dev";
            teamType = Individual;
        },
                {
            isFreeProvisioningTeam = 1;
            teamID = FREE000001;
            teamName = "Personal Team";
        }
    );
}`;

const noXcode = async () => ({ code: 1, out: '' });

describe('iPhone signing team', () => {
  it('writes the team into every configuration that has a Bundle ID, once', () => {
    expect(projectTeam(PBX)).toBeNull();
    const out = withDevelopmentTeam(PBX, 'ABCDE12345');
    const ids = (PBX.match(/PRODUCT_BUNDLE_IDENTIFIER = /g) ?? []).length;
    expect((out.match(/DEVELOPMENT_TEAM = ABCDE12345;/g) ?? []).length).toBe(ids);
    expect(projectTeam(out)).toBe('ABCDE12345');
    // Nothing else moves, and a second pass changes nothing.
    expect(out.replace(/\n\t*DEVELOPMENT_TEAM = ABCDE12345;/g, '')).toBe(PBX);
    expect(withDevelopmentTeam(out, 'ABCDE12345')).toBe(out);
  });

  it('refuses something that is not a Team ID', () => {
    expect(withDevelopmentTeam(PBX, 'nope')).toBe(PBX);
  });

  it('reads the paid teams Xcode is signed in with', () => {
    expect(parseXcodeTeams(XCODE_DEFAULTS)).toEqual(['ABCDE12345']);
  });

  it('prefers the project, then the saved team, then Apple, then Xcode', async () => {
    const withTeam = withDevelopmentTeam(PBX, 'PROJ000001');
    expect(await findTeamId({ pbxproj: withTeam, bundleId: 'a.b', savedTeamId: 'SAVE000001', run: noXcode })).toEqual({ teamId: 'PROJ000001', source: 'project' });
    expect(await findTeamId({ pbxproj: PBX, bundleId: 'a.b', savedTeamId: 'SAVE000001', run: noXcode })).toEqual({ teamId: 'SAVE000001', source: 'saved' });
    expect(await findTeamId({ pbxproj: PBX, bundleId: 'a.b', run: async () => ({ code: 0, out: XCODE_DEFAULTS }) })).toEqual({
      teamId: 'ABCDE12345',
      source: 'xcode',
    });
    expect(await findTeamId({ pbxproj: PBX, bundleId: 'a.b', run: noXcode })).toBeNull();
  });

  it('asks App Store Connect for the seedId of the app, else of any Bundle ID', async () => {
    const { generateKeyPair, exportPKCS8 } = await import('jose');
    const { privateKey } = await generateKeyPair('ES256', { extractable: true });
    const key = { keyId: 'ABCDEF1234', issuerId: '00000000-0000-0000-0000-000000000000', privateKey: await exportPKCS8(privateKey) };
    const urls: string[] = [];
    const fetchImpl = (async (url: string) => {
      urls.push(url);
      const data = url.includes('filter') ? [] : [{ attributes: { seedId: 'APPL000001' } }];
      return new Response(JSON.stringify({ data }), { status: 200 });
    }) as unknown as typeof fetch;
    expect(await findTeamId({ pbxproj: PBX, bundleId: 'com.x.y', key, fetchImpl, run: noXcode })).toEqual({ teamId: 'APPL000001', source: 'appstore' });
    expect(urls[0]).toContain('filter[identifier]=com.x.y');
  });
});
