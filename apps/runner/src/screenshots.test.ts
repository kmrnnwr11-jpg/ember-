import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { CLAUDE_CODE_BUILD_PROMPT } from './agent_cli.js';
import { hasScreenshotMode, SCREENSHOT_UPGRADE_REQUEST } from './screenshots.js';

describe('screenshots', () => {
  it('detects the screenshot mode in app code', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-shot-'));
    await mkdir(path.join(root, 'lib', 'config'), { recursive: true });
    await writeFile(path.join(root, 'lib', 'main.dart'), 'void main() {}');
    expect(await hasScreenshotMode(root)).toBe(false);
    await writeFile(path.join(root, 'lib', 'config', 'screenshot_screens.dart'), "final s = Uri.base.queryParameters['ember_screen'];");
    expect(await hasScreenshotMode(root)).toBe(true);
    await rm(root, { recursive: true, force: true });
  });

  it('build prompts always ask for the screenshot mode', () => {
    expect(CLAUDE_CODE_BUILD_PROMPT).toContain('ember_screen=N');
    expect(SCREENSHOT_UPGRADE_REQUEST).toContain('ember_screen');
  });
});
