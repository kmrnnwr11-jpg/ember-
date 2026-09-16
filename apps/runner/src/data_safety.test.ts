import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { detectDataFacts, factsSummary, findExportedCsv, validateFilledCsv } from './data_safety.js';

const CSV = 'Question ID,Response,Response value,Answer requirement,Human-friendly question label\nPSL_DATA_TYPES_PERSONAL,PSL_NAME,,MULTIPLE_CHOICE,Personal info - Name\nPSL_DATA_TYPES_PERSONAL,PSL_EMAIL,,MULTIPLE_CHOICE,Personal info - Email';

describe('data safety', () => {
  it('detects what the app uses from its dependencies', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-ds-'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'dependencies:\n  firebase_auth: ^6.0.0\n  image_picker: ^1.0.0\n  http: ^1.0.0\n');
    const f = await detectDataFacts(root);
    expect(f.account).toBe(true);
    expect(f.photos).toBe(true);
    expect(f.location).toBe(false);
    expect(factsSummary(f)).toContain('account');
    await rm(root, { recursive: true, force: true });
  });

  it('accepts a filled CSV with the same questions and rejects tampering', () => {
    const filled = CSV.replace('PSL_NAME,,', 'PSL_NAME,TRUE,');
    expect(validateFilledCsv(CSV, filled)).toContain('PSL_NAME,TRUE');
    expect(validateFilledCsv(CSV, '```csv\n' + filled + '\n```')).toContain('PSL_NAME,TRUE');
    expect(() => validateFilledCsv(CSV, CSV.split('\n').slice(0, 2).join('\n'))).toThrow(/rows/);
    expect(() => validateFilledCsv(CSV, filled.replace('PSL_DATA_TYPES_PERSONAL,PSL_EMAIL', 'PSL_OTHER,PSL_EMAIL'))).toThrow(/changed question/);
  });

  it('finds the newest exported CSV in a folder', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'fc-dl-'));
    expect(await findExportedCsv(dir)).toBeNull();
    await writeFile(path.join(dir, 'data_safety_export.csv'), CSV);
    expect(await findExportedCsv(dir)).toContain('data_safety_export.csv');
    await rm(dir, { recursive: true, force: true });
  });
});
