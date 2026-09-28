import { describe, expect, it } from 'vitest';
import { cliBuildArgs, parseCodexLine, parseGeminiLine } from './subscription_clis.js';

describe('subscription CLIs', () => {
  it('maps codex exec --json events to agent events', () => {
    const s = { lastText: '' };
    expect(parseCodexLine('{"type":"item.completed","item":{"type":"agent_message","text":"PLAN_FILES: 6"}}', s)).toEqual([{ kind: 'text', text: 'PLAN_FILES: 6' }]);
    expect(parseCodexLine('{"type":"item.started","item":{"type":"file_change","changes":[{"path":"C:/p/app/lib/main.dart","kind":"add"}]}}', s)).toEqual([{ kind: 'tool', name: 'Write', summary: 'app/lib/main.dart' }]);
    parseCodexLine('{"type":"item.completed","item":{"type":"agent_message","text":"## Fatto"}}', s);
    expect(parseCodexLine('{"type":"turn.completed","usage":{}}', s)).toEqual([{ kind: 'result', ok: true, costUsd: null, turns: null, message: '## Fatto' }]);
    expect(parseCodexLine('not json', s)).toEqual([]);
  });

  it('maps gemini stream-json events to agent events', () => {
    const s = { lastText: '' };
    expect(parseGeminiLine('{"type":"tool_use","tool_name":"write_file","parameters":{"file_path":"/x/app/lib/a.dart"}}', s)).toEqual([{ kind: 'tool', name: 'Write', summary: 'app/lib/a.dart' }]);
    expect(parseGeminiLine('{"type":"message","role":"assistant","content":"Done"}', s)[0]).toEqual({ kind: 'text', text: 'Done' });
    expect(parseGeminiLine('{"type":"result","status":"success"}', s)[0]).toMatchObject({ kind: 'result', ok: true, message: 'Done' });
  });

  it('runs codex fully automatic in the project directory', () => {
    expect(cliBuildArgs('codex', 'C:/w/p')).toEqual(['exec', '--json', '--skip-git-repo-check', '--full-auto', '-C', 'C:/w/p', '-']);
    expect(cliBuildArgs('gemini-cli', 'C:/w/p')).toContain('yolo');
  });
});

describe('CLI models', () => {
  it('lists Claude aliases and accepts only safe model names', async () => {
    const { cliModels, safeModel } = await import('./subscription_clis.js');
    expect(cliModels()['claude-code'].map((m) => m.id)).toEqual(['sonnet', 'opus', 'fable', 'haiku']);
    expect(safeModel('gpt-5.6-terra')).toBe('gpt-5.6-terra');
    expect(safeModel('opus; rm -rf /')).toBeUndefined();
    expect(safeModel('best')).toBeUndefined();
  });
});

describe('files Codex writes through PowerShell', () => {
  it('reads the file out of the shell commands Codex really sends', async () => {
    const { shellWrites } = await import('./subscription_clis.js');
    // Taken from a real Codex session on Windows.
    expect(shellWrites("@'\nname: app\n'@ | Set-Content -Encoding UTF8 lib\config\screenshot_screens.dart")).toEqual(['lib\config\screenshot_screens.dart']);
    expect(shellWrites("'x' | Out-File -FilePath 'lib/main.dart' -Encoding utf8")).toEqual(['lib/main.dart']);
    expect(shellWrites('Add-Content -Path "pubspec.yaml" -Value "x"')).toEqual(['pubspec.yaml']);
    expect(shellWrites("[IO.File]::WriteAllText('lib/a.dart', $t)")).toEqual(['lib/a.dart']);
    // Reading is not writing.
    expect(shellWrites('Get-Content lib\main.dart')).toEqual([]);
  });

  it('turns such a command into a Write event instead of a bare "@\'"', () => {
    const line = JSON.stringify({ type: 'item.started', item: { type: 'command_execution', command: "powershell -Command \"@'\nx\n'@ | Set-Content -Encoding UTF8 lib\home.dart\"" } });
    const ev = parseCodexLine(line, { lastText: '' });
    expect(ev).toHaveLength(1);
    expect(ev[0]).toMatchObject({ kind: 'tool', name: 'Write' });
  });
});
