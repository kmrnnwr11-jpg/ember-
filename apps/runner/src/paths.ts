import path from 'node:path';

export class PathError extends Error {
  readonly code = 'bad_path';
}

/** Normalizes a client path to project-relative POSIX form; rejects escapes. */
export function normalizeRel(input: unknown): string {
  if (typeof input !== 'string') throw new PathError('path must be a string');
  if (input.includes('\0')) throw new PathError('invalid path');
  const parts: string[] = [];
  for (const seg of input.replaceAll('\\', '/').split('/')) {
    if (seg === '' || seg === '.') continue;
    if (seg === '..') {
      if (parts.length === 0) throw new PathError('path escapes project root');
      parts.pop();
    } else {
      if (/^[a-zA-Z]:$/.test(seg) && parts.length === 0) throw new PathError('absolute paths not allowed');
      parts.push(seg);
    }
  }
  return parts.join('/');
}

/** Resolves a client path inside [root], guaranteeing the result stays inside. */
export function safeResolve(root: string, input: unknown): string {
  const rel = normalizeRel(input);
  const absRoot = path.resolve(root);
  const abs = path.resolve(absRoot, rel);
  const relCheck = path.relative(absRoot, abs);
  if (relCheck.startsWith('..') || path.isAbsolute(relCheck)) {
    throw new PathError('path escapes project root');
  }
  return abs;
}

export function toRel(root: string, abs: string): string {
  return path.relative(path.resolve(root), abs).split(path.sep).join('/');
}

const NAME_RE = /^[a-z][a-z0-9_]{0,63}$/;
const DART_RESERVED = new Set(['flutter', 'test', 'async', 'class', 'import', 'void', 'dart']);

/** Validates a project name usable as a Dart package name. */
export function validateProjectName(name: unknown): string {
  if (typeof name !== 'string' || !NAME_RE.test(name) || DART_RESERVED.has(name)) {
    throw new PathError('project name must be lowercase snake_case (a-z, 0-9, _), start with a letter, max 64 chars');
  }
  return name;
}
